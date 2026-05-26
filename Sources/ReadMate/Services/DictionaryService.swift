import Foundation

public final class DictionaryService: Sendable {
    public static let shared = DictionaryService()
    
    private init() {}
    
    /// Checks if a string is a single word (contains no spaces or punctuation)
    private func isSingleWord(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.contains(" ") && trimmed.rangeOfCharacter(from: .punctuationCharacters) == nil
    }
    
    /// Fetches free dictionary lookup and translation without requiring an API key.
    public func lookup(text: String) async throws -> LookupResult {
        let queryText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !queryText.isEmpty else {
            throw NSError(domain: "DictionaryService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Empty search query."])
        }
        
        // 1. Fetch translation from MyMemory API (Free translation pair English -> Vietnamese)
        let translation = try await translateToVietnamese(queryText)
        
        // 2. If it's a single word, fetch from Free Dictionary API
        if isSingleWord(queryText) {
            do {
                let dictData = try await fetchEnglishDefinition(queryText)
                
                // Parse definition details
                var simpleMeaning = ""
                var examples: [String] = []
                var pronunciation = ""
                
                if let phonetic = dictData.phonetic {
                    pronunciation = phonetic
                } else if let phonetics = dictData.phonetics, let firstWithText = phonetics.first(where: { $0.text != nil }) {
                    pronunciation = firstWithText.text ?? ""
                }
                
                if let meanings = dictData.meanings {
                    for meaning in meanings.prefix(3) {
                        let pos = meaning.partOfSpeech.uppercased()
                        for def in meaning.definitions.prefix(2) {
                            if simpleMeaning.isEmpty {
                                simpleMeaning = "(\(pos)) \(def.definition)"
                            } else {
                                simpleMeaning += "\n(\(pos)) \(def.definition)"
                            }
                            
                            if let example = def.example, !example.isEmpty {
                                examples.append(example)
                            }
                        }
                    }
                }
                
                // Fallback if meanings were empty
                if simpleMeaning.isEmpty {
                    simpleMeaning = "Definition not found in free dictionary."
                }
                
                // Ensure we have exactly 3 examples, fallback if API had fewer
                if examples.count < 3 {
                    examples.append("Learning English with ReadMate is simple.")
                    examples.append("How do you pronounce '\(queryText)'?")
                    examples.append("He looked up the definition of '\(queryText)'.")
                }
                examples = Array(examples.prefix(3))
                
                let grammarNote = pronunciation.isEmpty ? nil : "Pronunciation: \(pronunciation)"
                
                return LookupResult(
                    simpleMeaning: simpleMeaning,
                    vietnameseMeaning: translation,
                    examples: examples,
                    grammar: grammarNote,
                    vocabulary: nil,
                    aiNotes: "💡 Dictionary Mode (Free Offline API). Add a Gemini Key in Settings to unlock deep AI structural insights and customizable explanation templates."
                )
                
            } catch {
                // If Free Dictionary API fails or word not found, fallback to Translation Mode
                return buildFallbackTranslationResult(word: queryText, translation: translation)
            }
        } else {
            // For phrases or sentences, directly build a translation-focused result
            return buildFallbackTranslationResult(word: queryText, translation: translation)
        }
    }
    
    private func buildFallbackTranslationResult(word: String, translation: String) -> LookupResult {
        return LookupResult(
            simpleMeaning: "Free translation of phrase/sentence.",
            vietnameseMeaning: translation,
            examples: [
                "Original text: \(word)",
                "ReadMate makes it easy to read foreign languages.",
                "Highlight any sentence to get immediate translation."
            ],
            grammar: nil,
            vocabulary: nil,
            aiNotes: "💡 Dictionary Mode (Free translation). Add a Gemini API Key in Settings to unlock comprehensive word-by-word vocabulary breakdowns, Anki formatting, and grammar tips!"
        )
    }
    
    // MARK: - Free API Clients
    
    private func translateToVietnamese(_ text: String) async throws -> String {
        guard let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.mymemory.translated.net/get?q=\(encodedText)&langpair=en|vi") else {
            return "Translation URL error."
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(MyMemoryResponse.self, from: data)
        return response.responseData.translatedText
    }
    
    private func fetchEnglishDefinition(_ word: String) async throws -> FreeDictWord {
        guard let encodedWord = word.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.dictionaryapi.dev/api/v2/entries/en/\(encodedWord)") else {
            throw NSError(domain: "DictionaryService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL."])
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "DictionaryService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Word not found."])
        }
        
        let words = try JSONDecoder().decode([FreeDictWord].self, from: data)
        guard let firstWord = words.first else {
            throw NSError(domain: "DictionaryService", code: 404, userInfo: [NSLocalizedDescriptionKey: "No data found."])
        }
        
        return firstWord
    }
}

// MARK: - Free Dictionary API Model Structures

struct FreeDictWord: Codable {
    let word: String
    let phonetic: String?
    let phonetics: [FreeDictPhonetic]?
    let meanings: [FreeDictMeaning]?
}

struct FreeDictPhonetic: Codable {
    let text: String?
    let audio: String?
}

struct FreeDictMeaning: Codable {
    let partOfSpeech: String
    let definitions: [FreeDictDefinition]
}

struct FreeDictDefinition: Codable {
    let definition: String
    let example: String?
    let synonyms: [String]?
    let antonyms: [String]?
}

struct MyMemoryResponse: Codable {
    let responseData: MyMemoryResponseData
}

struct MyMemoryResponseData: Codable {
    let translatedText: String
}
