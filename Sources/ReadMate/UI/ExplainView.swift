import SwiftUI
import AppKit

public struct ExplainView: View {
    @Binding var selectedText: String
    @State private var inputWord: String = ""
    @State private var isAnalyzing: Bool = false
    @State private var result: LookupResult? = nil
    @State private var errorMessage: String? = nil
    @State private var selectedTemplate: AITemplate = AITemplates.defaults[0]

    public init(selectedText: Binding<String>) {
        self._selectedText = selectedText
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Input bar at top
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 12))

                    TextField("Enter text to explain...", text: $inputWord, onCommit: {
                        if !inputWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            selectedText = inputWord
                            triggerAnalysis()
                        }
                    })
                    .textFieldStyle(.plain)
                    .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.15))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color(red: 0.94, green: 0.94, blue: 0.96))
                .cornerRadius(8)

                Button(action: {
                    if !inputWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        selectedText = inputWord
                        triggerAnalysis()
                    }
                }) {
                    Image(systemName: "arrow.right")
                        .foregroundColor(.white)
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 32, height: 32)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(inputWord.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            Divider()
                .background(Color(red: 0.9, green: 0.9, blue: 0.92))

            // Main content area
            if isAnalyzing {
                LoadingHUDView()
            } else if let error = errorMessage {
                ErrorHUDView(message: error, retryAction: triggerAnalysis)
            } else if let data = result {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 16) {

                        // Header with Speak and Copy actions
                        HStack(spacing: 12) {
                            Text(selectedText)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.12))
                                .lineLimit(2)

                            Button(action: speakWord) {
                                Image(systemName: "speaker.wave.2.bubble.left.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 13))
                                    .padding(6)
                                    .background(Color(red: 0.9, green: 0.93, blue: 1.0))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            .help("Listen to pronunciation")

                            Spacer()

                            Button(action: copyToClipboard) {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.on.doc.fill")
                                    Text("Copy all")
                                }
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Color(red: 0.35, green: 0.35, blue: 0.4))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(Color(red: 0.93, green: 0.93, blue: 0.95))
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }

                        // 1. Simple English Meaning
                        VStack(alignment: .leading, spacing: 6) {
                            Text("SIMPLE MEANING")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Color(red: 0.35, green: 0.35, blue: 0.4))

                            Text(data.simpleMeaning)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.15))
                                .lineSpacing(4)
                        }

                        // 2. Vietnamese Meaning
                        VStack(alignment: .leading, spacing: 6) {
                            Text("VIETNAMESE")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Color(red: 0.35, green: 0.35, blue: 0.4))

                            Text(data.vietnameseMeaning)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(red: 0.05, green: 0.15, blue: 0.55))
                                .lineSpacing(4)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 0.88, green: 0.93, blue: 1.0))
                        .cornerRadius(8)

                        // 3. Vocabulary Breakdown
                        if let vocab = data.vocabulary, !vocab.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("KEY VOCABULARY")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(Color(red: 0.35, green: 0.35, blue: 0.4))

                                ForEach(vocab) { item in
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(item.word)
                                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.12))

                                            Spacer()

                                            Text(item.vietnamese)
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(Color(red: 0.05, green: 0.2, blue: 0.6))
                                        }

                                        Text(item.meaning)
                                            .font(.system(size: 11))
                                            .foregroundColor(Color(red: 0.35, green: 0.35, blue: 0.4))

                                        if !item.example.isEmpty {
                                            Text("ex: \(item.example)")
                                                .font(.system(size: 10, design: .serif))
                                                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.45))
                                                .italic()
                                        }
                                    }
                                    .padding(8)
                                    .background(Color(red: 0.94, green: 0.94, blue: 0.97))
                                    .cornerRadius(6)
                                }
                            }
                        }

                        // 4. Grammar Insights
                        if let grammar = data.grammar, !grammar.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("GRAMMAR DETAILS")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(Color(red: 0.35, green: 0.35, blue: 0.4))

                                Text(grammar)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.18))
                                    .lineSpacing(3)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(red: 0.94, green: 0.94, blue: 0.97))
                            .cornerRadius(8)
                        }

                        // 5. Examples
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NATURAL EXAMPLES")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Color(red: 0.35, green: 0.35, blue: 0.4))

                            ForEach(data.examples, id: \.self) { example in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("\u{2022}")
                                        .foregroundColor(.blue)
                                    Text(example)
                                        .font(.system(size: 12, design: .serif))
                                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.25))
                                        .lineSpacing(3)
                                    Spacer()
                                    Button(action: { NSSpeechSynthesizer().startSpeaking(example) }) {
                                        Image(systemName: "speaker.wave.1.fill")
                                            .foregroundColor(Color(red: 0.35, green: 0.35, blue: 0.4))
                                            .font(.system(size: 10))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.vertical, 2)
                            }
                        }

                        // 6. Template Notes
                        if let notes = data.aiNotes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("ADDITIONAL NOTES (\(selectedTemplate.name))")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(Color(red: 0.35, green: 0.35, blue: 0.4))

                                Text(notes)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.05))
                                    .padding(8)
                                    .background(Color(red: 1.0, green: 0.97, blue: 0.78))
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .padding(16)
                }
            } else {
                // Initial empty state
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "sparkles")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                    Text("Select text anywhere & press Cmd+Shift+E")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.18))
                    Text("Or type a word in the text box above to explain instantly.")
                        .font(.system(size: 10))
                        .foregroundColor(Color(red: 0.35, green: 0.35, blue: 0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Footer with template picker
            if result != nil || isAnalyzing || errorMessage != nil {
                Divider()
                    .background(Color(red: 0.9, green: 0.9, blue: 0.92))

                HStack {
                    Text("Template:")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(red: 0.35, green: 0.35, blue: 0.4))

                    Picker("", selection: $selectedTemplate) {
                        ForEach(AITemplates.defaults) { template in
                            Text(template.name)
                                .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.15))
                                .tag(template)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 180)
                    .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.15))
                    .onChange(of: selectedTemplate) { _ in
                        triggerAnalysis()
                    }

                    Spacer()

                    if isAnalyzing {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 16, height: 16)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(red: 0.97, green: 0.97, blue: 0.98))
            }
        }
        .onAppear {
            if !selectedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                inputWord = selectedText
                triggerAnalysis()
            }
        }
        .onChange(of: selectedText) { newValue in
            if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                inputWord = newValue
                triggerAnalysis()
            }
        }
    }

    private func triggerAnalysis() {
        guard !selectedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        isAnalyzing = true
        errorMessage = nil

        Task {
            do {
                let lookupResult: LookupResult
                let hasApiKey = KeychainManager.shared.retrieve() != nil
                let isPhrase = selectedText.trimmingCharacters(in: .whitespacesAndNewlines)
                    .contains(where: { $0.isWhitespace || $0 == "\n" }) || selectedText.count > 20

                if !hasApiKey && isPhrase {
                    throw AIError.missingApiKey
                }

                if hasApiKey {
                    lookupResult = try await AIService.shared.explain(text: selectedText, template: selectedTemplate)
                } else {
                    lookupResult = try await DictionaryService.shared.lookup(text: selectedText)
                }

                let lookup = WordLookup(selectedText: selectedText, sourceApp: getActiveAppName(), result: lookupResult)
                HistoryService.shared.addLookup(lookup)

                await MainActor.run {
                    self.result = lookupResult
                    self.isAnalyzing = false
                }
            } catch {
                do {
                    let lookupResult = try await DictionaryService.shared.lookup(text: selectedText)
                    let lookup = WordLookup(selectedText: selectedText, sourceApp: getActiveAppName(), result: lookupResult)
                    HistoryService.shared.addLookup(lookup)

                    await MainActor.run {
                        self.result = lookupResult
                        self.isAnalyzing = false
                    }
                } catch let dictError {
                    await MainActor.run {
                        self.errorMessage = "Failed to load explanation: \(error.localizedDescription) (Dictionary fallback error: \(dictError.localizedDescription))"
                        self.isAnalyzing = false
                    }
                }
            }
        }
    }

    private func speakWord() {
        guard !selectedText.isEmpty else { return }
        let synth = NSSpeechSynthesizer()
        synth.startSpeaking(selectedText)
    }

    private func copyToClipboard() {
        guard let data = result else { return }

        var summary = """
        Word: \(selectedText)
        Definition: \(data.simpleMeaning)
        Vietnamese: \(data.vietnameseMeaning)

        Examples:
        """

        for example in data.examples {
            summary += "\n- \(example)"
        }

        if let grammar = data.grammar {
            summary += "\n\nGrammar:\n\(grammar)"
        }

        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(summary, forType: .string)
    }

    private func getActiveAppName() -> String {
        if let frontApp = NSWorkspace.shared.frontmostApplication,
           let name = frontApp.localizedName,
           name != "ReadMate" {
            return name
        }
        return "Browser"
    }
}

// Shimmery loading UI
struct LoadingHUDView: View {
    @State private var shimmer = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(red: 0.93, green: 0.93, blue: 0.95).opacity(shimmer ? 1 : 0.5))
                    .frame(width: 140, height: 20)
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(red: 0.93, green: 0.93, blue: 0.95).opacity(shimmer ? 1 : 0.5))
                    .frame(width: 32, height: 20)
            }

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(red: 0.93, green: 0.93, blue: 0.95).opacity(shimmer ? 1 : 0.5))
                    .frame(height: 12)
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(red: 0.93, green: 0.93, blue: 0.95).opacity(shimmer ? 1 : 0.5))
                    .frame(height: 12)
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(red: 0.93, green: 0.93, blue: 0.95).opacity(shimmer ? 1 : 0.5))
                    .frame(width: 200, height: 12)
            }

            Divider()
                .background(Color(red: 0.9, green: 0.9, blue: 0.92))

            VStack(alignment: .leading, spacing: 10) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(red: 0.93, green: 0.93, blue: 0.95).opacity(shimmer ? 1 : 0.5))
                    .frame(width: 80, height: 10)
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(red: 0.93, green: 0.93, blue: 0.95).opacity(shimmer ? 1 : 0.5))
                    .frame(height: 40)
            }

            Spacer()
        }
        .padding(16)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                shimmer = true
            }
        }
    }
}

// Error state view
struct ErrorHUDView: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.0))

            Text("Something went wrong")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.18))

            Text(message)
                .font(.system(size: 11))
                .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Button(action: retryAction) {
                Text("Try Again")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}