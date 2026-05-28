import XCTest
@testable import ReadMate

final class ModelsTests: XCTestCase {

    func testAITemplateInit() {
        let t = AITemplate(templateId: "test", name: "Test", summary: "Summary", promptInstruction: "Do something")
        XCTAssertEqual(t.templateId, "test")
        XCTAssertEqual(t.name, "Test")
        XCTAssertEqual(t.summary, "Summary")
        XCTAssertEqual(t.promptInstruction, "Do something")
        XCTAssertEqual(t.id, "test")
    }

    func testAITemplateDefaultsCount() {
        XCTAssertEqual(AITemplates.defaults.count, 6)
        XCTAssertEqual(AITemplates.defaults.first?.templateId, "explain_all")
    }

    func testVocabularyItemCodable() {
        let item = VocabularyItem(word: "run", meaning: "move fast", vietnamese: "chạy", example: "I run every day.")
        let encoded = try! JSONEncoder().encode(item)
        let decoded = try! JSONDecoder().decode(VocabularyItem.self, from: encoded)
        XCTAssertEqual(decoded.word, "run")
        XCTAssertEqual(decoded.meaning, "move fast")
        XCTAssertEqual(decoded.vietnamese, "chạy")
        XCTAssertEqual(decoded.example, "I run every day.")
        XCTAssertEqual(decoded.id, "run")
    }

    func testLookupResultCodable() {
        let result = LookupResult(
            simpleMeaning: "move fast",
            vietnameseMeaning: "chạy",
            examples: ["I run.", "You run."],
            grammar: "verb",
            vocabulary: [VocabularyItem(word: "run", meaning: "move", vietnamese: "chạy", example: "Run!")],
            aiNotes: "note"
        )
        let encoded = try! JSONEncoder().encode(result)
        let decoded = try! JSONDecoder().decode(LookupResult.self, from: encoded)
        XCTAssertEqual(decoded.simpleMeaning, "move fast")
        XCTAssertEqual(decoded.vietnameseMeaning, "chạy")
        XCTAssertEqual(decoded.examples.count, 2)
        XCTAssertEqual(decoded.grammar, "verb")
        XCTAssertEqual(decoded.vocabulary?.count, 1)
        XCTAssertEqual(decoded.aiNotes, "note")
    }

    func testWordLookupCodable() {
        let result = LookupResult(
            simpleMeaning: "test",
            vietnameseMeaning: "thử",
            examples: ["Test me."]
        )
        let lookup = WordLookup(
            id: UUID(),
            selectedText: "test",
            sourceApp: "Safari",
            createdAt: Date(timeIntervalSince1970: 1000),
            mode: "word",
            result: result
        )
        let encoded = try! JSONEncoder().encode(lookup)
        let decoded = try! JSONDecoder().decode(WordLookup.self, from: encoded)
        XCTAssertEqual(decoded.selectedText, "test")
        XCTAssertEqual(decoded.sourceApp, "Safari")
        XCTAssertEqual(decoded.mode, "word")
        XCTAssertNotNil(decoded.result)
        XCTAssertEqual(decoded.result?.simpleMeaning, "test")
    }

    func testDictionaryModeRawValues() {
        XCTAssertEqual(DictionaryMode.engeng.rawValue, "engeng")
        XCTAssertEqual(DictionaryMode.engviet.rawValue, "engviet")
        XCTAssertEqual(DictionaryMode.engeng.displayName, "English - English")
        XCTAssertEqual(DictionaryMode.engviet.displayName, "English - Vietnamese")
        XCTAssertEqual(DictionaryMode.allCases.count, 2)
    }
}
