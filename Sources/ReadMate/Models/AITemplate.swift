import Foundation

public struct AITemplate: Identifiable, Codable, Hashable, Sendable {
    public var id: String { templateId }
    public let templateId: String
    public let name: String
    public let summary: String
    public let promptInstruction: String
    
    public init(templateId: String, name: String, summary: String, promptInstruction: String) {
        self.templateId = templateId
        self.name = name
        self.summary = summary
        self.promptInstruction = promptInstruction
    }
}

public struct AITemplates: Sendable {
    public static let defaults: [AITemplate] = [
        AITemplate(
            templateId: "explain_all",
            name: "✨ Explain simply",
            summary: "Comprehensive lookup with definitions, translation, and examples.",
            promptInstruction: "Explain the selected text using very simple English, provide a natural Vietnamese translation, break down difficult vocabulary, and give 3 natural examples."
        ),
        AITemplate(
            templateId: "vocab_breakdown",
            name: "📚 Vocabulary breakdown",
            summary: "Word-by-word analysis and detailed meanings.",
            promptInstruction: "Break down the text word-by-word. For each key word/expression, list its part of speech, its simple English meaning, its Vietnamese meaning, and an example sentence."
        ),
        AITemplate(
            templateId: "grammar_explain",
            name: "⚙️ Grammar breakdown",
            summary: "Grammar, sentence structures, and key patterns.",
            promptInstruction: "Explain the grammatical structure of the sentence. Break down subject, verb, objects, modifiers, and detail the tenses or voice used."
        ),
        AITemplate(
            templateId: "eli5",
            name: "👶 Explain like I'm 5",
            summary: "Ultra-simple explanations and comparisons.",
            promptInstruction: "Explain what this text means using language a 5-year-old child can easily understand, complete with an illustrative analogy."
        ),
        AITemplate(
            templateId: "natural_translation",
            name: "🇻🇳 Natural Vietnamese",
            summary: "Natural translation, context, and Vietnamese idioms.",
            promptInstruction: "Provide a translation of the text that sounds native, fluid, and contextually accurate in Vietnamese, explaining any specific vocabulary shifts."
        ),
        AITemplate(
            templateId: "anki_card",
            name: "🗂️ Save as Anki card",
            summary: "Creates Front & Back flashcard contents.",
            promptInstruction: "Generate a structured flashcard. Provide Front (the word or phrase) and Back (simple definition, Vietnamese translation, and a clean example sentence)."
        )
    ]
}
