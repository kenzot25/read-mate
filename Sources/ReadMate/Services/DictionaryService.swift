import Foundation
import SwiftSoup

public final class DictionaryService: Sendable {
    public static let shared = DictionaryService()
    private let httpClient = URLSession.shared

    private init() {}

    func isSingleWord(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && !trimmed.contains(" ") && trimmed.rangeOfCharacter(from: .punctuationCharacters) == nil
    }

    public func lookup(text: String) async throws -> LookupResult {
        let queryText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !queryText.isEmpty else {
            throw NSError(domain: "DictionaryService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Empty search query."])
        }

        let mode = PreferencesManager.shared.dictionaryMode

        if isSingleWord(queryText) {
            do {
                let cambridge = try await fetchCambridge(word: queryText, mode: mode)
                return buildResult(from: cambridge, word: queryText, mode: mode)
            } catch {
                return buildFallbackResult(word: queryText, mode: mode)
            }
        }

        return buildFallbackResult(word: queryText, mode: mode)
    }

    private func fetchCambridge(word: String, mode: DictionaryMode) async throws -> CambridgeResponse {
        let language = mode == .engeng ? "english" : "english-vietnamese"
        let trimmedWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let encoded = trimmedWord.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw NSError(domain: "DictionaryService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid word encoding."])
        }
        let urlString = "https://dictionary.cambridge.org/us/dictionary/\(language)/\(encoded)"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "DictionaryService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL."])
        }

        print("[DictionaryService] Fetching: \(urlString)")

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await httpClient.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }

        print("[DictionaryService] HTTP status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "DictionaryService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"])
        }

        guard let html = String(data: data, encoding: .utf8) else {
            throw AIError.invalidResponse
        }

        return try await parseCambridgeHTML(html: html, word: word)
    }

    private func parseCambridgeHTML(html: String, word: String) async throws -> CambridgeResponse {
        let doc = try SwiftSoup.parse(html)
        let siteurl = "https://dictionary.cambridge.org"

        let title = (try? doc.select("title").first()?.text()) ?? "no title"
        print("[DictionaryService] HTML title: \(title)")

        var wordText: String = ""
        let wordSelectors = [".hw.dhw", ".dhw", ".di-title", ".tb.ttn"]
        for selector in wordSelectors {
            if let el = try doc.select(selector).first(),
               let text = try? el.text(),
               !text.isEmpty {
                wordText = text
                print("[DictionaryService] Word found via '\(selector)': \(text)")
                break
            }
        }

        if wordText.isEmpty {
            print("[DictionaryService] Word not found in HTML")
            throw NSError(domain: "DictionaryService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Word not found."])
        }

        let posElements = try doc.select(".pos.dpos")
        let pos = try Set(posElements.map { try $0.text() }).sorted()
        print("[DictionaryService] POS count: \(pos.count)")

        var audio: [CambridgePronunciation] = []
        let posHeaders = try doc.select(".pos-header.dpos-h")
        for header in posHeaders {
            guard let posNode = try header.select(".dpos-g").first() else { continue }
            let p = try posNode.text()
            let dpronNodes = try header.select(".dpron-i")
            for node in dpronNodes {
                let lang = (try? node.select(".region.dreg").first()?.text()) ?? ""
                let audioSrc = (try? node.select("audio source").first()?.attr("src")) ?? ""
                let pron = (try? node.select(".pron.dpron").first()?.text()) ?? ""
                if !audioSrc.isEmpty && !pron.isEmpty {
                    audio.append(CambridgePronunciation(pos: p, lang: lang, url: siteurl + audioSrc, pron: pron))
                }
            }
        }

        var definitions: [CambridgeDefinition] = []
        let defBlocks = try doc.select(".def-block.ddef_block")
        print("[DictionaryService] Definition blocks count: \(defBlocks.size())")

        for (index, block) in defBlocks.enumerated() {
            let pos = (try? block.parent()?.select(".pos.dpos").first()?.text()) ?? ""
            let source = (try? block.parent()?.attr("data-id")) ?? ""

            var text = ""
            for selector in [".def.ddef_d.db", ".def.ddef_d"] {
                if let el = try block.select(selector).first(),
                   let t = try? el.text(),
                   !t.isEmpty {
                    text = t
                    break
                }
            }

            var translation = ""
            for selector in [".def-body.ddef_b > span.trans.dtrans", ".trans.dtrans"] {
                if let el = try block.select(selector).first(),
                   let t = try? el.text(),
                   !t.isEmpty {
                    translation = t
                    break
                }
            }

            var examples: [CambridgeExample] = []
            let exampNodes = try block.select(".def-body.ddef_b > .examp.dexamp")
            for (i, ex) in exampNodes.enumerated() {
                let exText = (try? ex.select(".eg.deg").first()?.text()) ?? ""
                let exTrans = (try? ex.select(".trans.dtrans").first()?.text()) ?? ""
                examples.append(CambridgeExample(id: i, text: exText, translation: exTrans))
            }

            if examples.isEmpty {
                let corpusNodes = try block.select(".degs .deg")
                for (i, ex) in corpusNodes.enumerated() {
                    let exText = (try? ex.text()) ?? ""
                    if !exText.isEmpty {
                        examples.append(CambridgeExample(id: i, text: exText, translation: ""))
                    }
                }
            }

            definitions.append(CambridgeDefinition(
                id: index,
                pos: pos,
                source: source,
                text: text,
                translation: translation,
                example: examples
            ))
        }

        let transCount = definitions.filter { !$0.translation.isEmpty }.count
        print("[DictionaryService] Definitions with translation: \(transCount)/\(definitions.count)")

        let verbs = (try? await fetchVerbs(word: wordText)) ?? []

        return CambridgeResponse(
            word: wordText,
            pos: Array(pos),
            verbs: verbs,
            pronunciation: audio,
            definition: definitions
        )
    }

    private func fetchVerbs(word: String) async throws -> [CambridgeVerb] {
        let url = URL(string: "https://simple.wiktionary.org/wiki/\(word)")!
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await httpClient.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
              let html = String(data: data, encoding: .utf8) else {
            return []
        }

        let doc = try SwiftSoup.parse(html)
        var verbs: [CambridgeVerb] = []
        let cells = try doc.select(".inflection-table tr td")
        for cell in cells {
            let cellText = try cell.text().trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cellText.isEmpty else { continue }

            let pElements = try cell.select("p")
            for p in pElements {
                let pText = try p.text().trimmingCharacters(in: .whitespacesAndNewlines)
                let parts = pText.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }

                if parts.count >= 2 {
                    let type = parts[0]
                    let text = parts[1]
                    if !type.isEmpty && !text.isEmpty {
                        verbs.append(CambridgeVerb(id: verbs.count, type: type, text: text))
                    }
                } else {
                    let htmlContent = try p.html()
                    if htmlContent.contains("<br>") {
                        let htmlParts = htmlContent.split(separator: "<br>", omittingEmptySubsequences: false)
                        if htmlParts.count >= 2 {
                            let type = String(htmlParts[0]).replacingOccurrences(of: "<[^>]*>", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
                            let text = String(htmlParts[1]).replacingOccurrences(of: "<[^>]*>", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
                            if !type.isEmpty && !text.isEmpty {
                                verbs.append(CambridgeVerb(id: verbs.count, type: type, text: text))
                            }
                        }
                    }
                }
            }
        }
        return verbs
    }

    func buildResult(from cambridge: CambridgeResponse, word: String, mode: DictionaryMode) -> LookupResult {
        var simpleMeaning = ""
        var examples: [String] = []
        var pronunciation = ""

        if let firstPron = cambridge.pronunciation.first(where: { $0.lang == "us" }) ?? cambridge.pronunciation.first {
            pronunciation = firstPron.pron
        }

        for def in cambridge.definition.prefix(3) {
            let pos = def.pos.uppercased()
            if !simpleMeaning.isEmpty { simpleMeaning += "\n" }

            if mode == .engviet, !def.translation.isEmpty {
                simpleMeaning += "(\(pos)) \(def.text) — \(def.translation)"
            } else {
                simpleMeaning += "(\(pos)) \(def.text)"
            }

            for ex in def.example.prefix(2) {
                if examples.count < 3 {
                    if mode == .engviet, !ex.translation.isEmpty {
                        examples.append("\(ex.text) — \(ex.translation)")
                    } else {
                        examples.append(ex.text)
                    }
                }
            }
        }

        if simpleMeaning.isEmpty {
            simpleMeaning = "Definition not found."
        }

        while examples.count < 3 {
            examples.append("Learning English with ReadMate is simple.")
        }
        examples = Array(examples.prefix(3))

        var grammarParts: [String] = []
        if !pronunciation.isEmpty {
            grammarParts.append("Pronunciation: \(pronunciation)")
        }
        if !cambridge.verbs.isEmpty {
            let verbForms = cambridge.verbs.prefix(5).map { "\($0.type): \($0.text)" }.joined(separator: " | ")
            grammarParts.append("Conjugation: \(verbForms)")
        }
        let grammarNote = grammarParts.isEmpty ? nil : grammarParts.joined(separator: "\n")

        let vietnamese = mode == .engviet ? (cambridge.definition.first?.translation ?? "") : "English-only mode"
        let aiNote = mode == .engeng
            ? "Cambridge Dictionary (English-English)"
            : "Cambridge Dictionary (English-Vietnamese)"

        return LookupResult(
            simpleMeaning: simpleMeaning,
            vietnameseMeaning: vietnamese.isEmpty ? "English-Vietnamese" : vietnamese,
            examples: examples,
            grammar: grammarNote,
            vocabulary: nil,
            aiNotes: aiNote
        )
    }

    func buildFallbackResult(word: String, mode: DictionaryMode) -> LookupResult {
        let aiNote = mode == .engeng
            ? "Phrase lookup (English-English). Add a Gemini API Key for AI insights."
            : "Phrase lookup (English-Vietnamese). Add a Gemini API Key for deeper analysis."

        return LookupResult(
            simpleMeaning: mode == .engeng ? "Free lookup of phrase/sentence." : "Free translation of phrase/sentence.",
            vietnameseMeaning: mode == .engeng ? "English-only mode" : "Phrase translation not available in dictionary mode.",
            examples: [
                "Original text: \(word)",
                "ReadMate makes it easy to read foreign languages.",
                "Highlight any sentence to get immediate translation."
            ],
            grammar: nil,
            vocabulary: nil,
            aiNotes: aiNote
        )
    }
}

// MARK: - Cambridge API Models

struct CambridgeResponse: Codable {
    let word: String
    let pos: [String]
    let verbs: [CambridgeVerb]
    let pronunciation: [CambridgePronunciation]
    let definition: [CambridgeDefinition]
}

struct CambridgeVerb: Codable {
    let id: Int
    let type: String
    let text: String
}

struct CambridgePronunciation: Codable {
    let pos: String
    let lang: String
    let url: String
    let pron: String
}

struct CambridgeDefinition: Codable {
    let id: Int
    let pos: String
    let source: String
    let text: String
    let translation: String
    let example: [CambridgeExample]
}

struct CambridgeExample: Codable {
    let id: Int
    let text: String
    let translation: String
}
