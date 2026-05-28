import XCTest
@testable import ReadMate

final class DictionaryServiceTests: XCTestCase {

    // MARK: - isSingleWord

    func testIsSingleWord_true() {
        XCTAssertTrue(DictionaryService.shared.isSingleWord("hello"))
        XCTAssertTrue(DictionaryService.shared.isSingleWord("running"))
    }

    func testIsSingleWord_falseForPhrase() {
        XCTAssertFalse(DictionaryService.shared.isSingleWord("hello world"))
        XCTAssertFalse(DictionaryService.shared.isSingleWord("run fast"))
    }

    func testIsSingleWord_falseForPunctuation() {
        XCTAssertFalse(DictionaryService.shared.isSingleWord("hello!"))
        XCTAssertFalse(DictionaryService.shared.isSingleWord("run."))
    }

    func testIsSingleWord_falseForEmpty() {
        XCTAssertFalse(DictionaryService.shared.isSingleWord(""))
        XCTAssertFalse(DictionaryService.shared.isSingleWord("   "))
    }

    func testIsSingleWord_trimsWhitespace() {
        XCTAssertTrue(DictionaryService.shared.isSingleWord("  hello  "))
        XCTAssertTrue(DictionaryService.shared.isSingleWord("\tworld\n"))
    }

    // MARK: - buildResult engeng

    func testBuildResultEngEng() {
        let cambridge = CambridgeResponse(
            word: "run",
            pos: ["verb", "noun"],
            verbs: [
                CambridgeVerb(id: 0, type: "Plain form", text: "run"),
                CambridgeVerb(id: 1, type: "Past tense", text: "ran")
            ],
            pronunciation: [
                CambridgePronunciation(pos: "verb", lang: "us", url: "http://example.com/run.mp3", pron: "/rʌn/")
            ],
            definition: [
                CambridgeDefinition(
                    id: 0,
                    pos: "verb",
                    source: "cald4",
                    text: "to move quickly on foot",
                    translation: "chạy",
                    example: [
                        CambridgeExample(id: 0, text: "I run every morning.", translation: "Tôi chạy mỗi sáng.")
                    ]
                )
            ]
        )

        let result = DictionaryService.shared.buildResult(from: cambridge, word: "run", mode: .engeng)

        XCTAssertTrue(result.simpleMeaning.contains("to move quickly on foot"))
        XCTAssertTrue(result.simpleMeaning.contains("VERB"))
        XCTAssertEqual(result.vietnameseMeaning, "English-only mode")
        XCTAssertEqual(result.examples.count, 3)
        XCTAssertEqual(result.examples.first, "I run every morning.")
        XCTAssertNotNil(result.grammar)
        XCTAssertTrue(result.grammar!.contains("Pronunciation: /rʌn/"))
        XCTAssertTrue(result.grammar!.contains("Conjugation: Plain form: run | Past tense: ran"))
        XCTAssertTrue(result.aiNotes?.contains("Cambridge") == true)
    }

    // MARK: - buildResult engviet

    func testBuildResultEngViet() {
        let cambridge = CambridgeResponse(
            word: "hello",
            pos: ["exclamation"],
            verbs: [],
            pronunciation: [],
            definition: [
                CambridgeDefinition(
                    id: 0,
                    pos: "exclamation",
                    source: "cald4",
                    text: "used when meeting someone",
                    translation: "xin chào",
                    example: [
                        CambridgeExample(id: 0, text: "Hello, world!", translation: "Xin chào, thế giới!")
                    ]
                )
            ]
        )

        let result = DictionaryService.shared.buildResult(from: cambridge, word: "hello", mode: .engviet)

        XCTAssertTrue(result.simpleMeaning.contains("used when meeting someone"))
        XCTAssertTrue(result.simpleMeaning.contains("xin chào"))
        XCTAssertEqual(result.examples.first, "Hello, world! — Xin chào, thế giới!")
        XCTAssertEqual(result.vietnameseMeaning, "xin chào")
    }

    // MARK: - buildResult empty definitions

    func testBuildResultEmptyDefinitions() {
        let cambridge = CambridgeResponse(
            word: "xyz",
            pos: [],
            verbs: [],
            pronunciation: [],
            definition: []
        )

        let result = DictionaryService.shared.buildResult(from: cambridge, word: "xyz", mode: .engeng)
        XCTAssertEqual(result.simpleMeaning, "Definition not found.")
        XCTAssertEqual(result.examples.count, 3)
    }

    // MARK: - buildFallbackResult

    func testBuildFallbackResultEngEng() {
        let result = DictionaryService.shared.buildFallbackResult(word: "a big sentence", mode: .engeng)
        XCTAssertTrue(result.simpleMeaning.contains("Free lookup"))
        XCTAssertEqual(result.vietnameseMeaning, "English-only mode")
        XCTAssertEqual(result.examples.count, 3)
        XCTAssertTrue(result.aiNotes?.contains("English-English") == true)
    }

    func testBuildFallbackResultEngViet() {
        let result = DictionaryService.shared.buildFallbackResult(word: "a big sentence", mode: .engviet)
        XCTAssertTrue(result.simpleMeaning.contains("Free translation"))
        XCTAssertTrue(result.vietnameseMeaning.contains("Phrase translation not available"))
        XCTAssertTrue(result.aiNotes?.contains("English-Vietnamese") == true)
    }
}
