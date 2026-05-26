import Foundation

public struct WordLookup: Identifiable, Codable, Sendable {
    public let id: UUID
    public let selectedText: String
    public let sourceApp: String
    public let createdAt: Date
    public let mode: String // "word", "sentence", "paragraph"
    public var result: LookupResult?
    
    public init(
        id: UUID = UUID(),
        selectedText: String,
        sourceApp: String = "Unknown",
        createdAt: Date = Date(),
        mode: String = "word",
        result: LookupResult? = nil
    ) {
        self.id = id
        self.selectedText = selectedText
        self.sourceApp = sourceApp
        self.createdAt = createdAt
        self.mode = mode
        self.result = result
    }
}

public struct LookupResult: Codable, Sendable {
    public let simpleMeaning: String
    public let vietnameseMeaning: String
    public let examples: [String]
    public let grammar: String?
    public let vocabulary: [VocabularyItem]?
    public let aiNotes: String?
    
    public init(
        simpleMeaning: String,
        vietnameseMeaning: String,
        examples: [String],
        grammar: String? = nil,
        vocabulary: [VocabularyItem]? = nil,
        aiNotes: String? = nil
    ) {
        self.simpleMeaning = simpleMeaning
        self.vietnameseMeaning = vietnameseMeaning
        self.examples = examples
        self.grammar = grammar
        self.vocabulary = vocabulary
        self.aiNotes = aiNotes
    }
}

public struct VocabularyItem: Identifiable, Codable, Sendable {
    public var id: String { word }
    public let word: String
    public let meaning: String
    public let vietnamese: String
    public let example: String
    
    public init(
        word: String,
        meaning: String,
        vietnamese: String,
        example: String
    ) {
        self.word = word
        self.meaning = meaning
        self.vietnamese = vietnamese
        self.example = example
    }
}
