import XCTest
@testable import ReadMate

final class DictionaryServiceE2ETests: XCTestCase {

    func testFetchCambridgeEnglishHello() async throws {
        let result = try await DictionaryService.shared.lookup(text: "hello")
        XCTAssertTrue(!result.simpleMeaning.isEmpty, "Should have a definition")
        XCTAssertTrue(result.examples.count >= 1, "Should have at least one example")
        XCTAssertTrue(result.aiNotes?.contains("Cambridge") == true)
    }

    func testFetchCambridgeEnglishRun() async throws {
        let result = try await DictionaryService.shared.lookup(text: "run")
        XCTAssertTrue(!result.simpleMeaning.isEmpty, "Should have a definition")
        XCTAssertTrue(result.examples.count >= 1, "Should have at least one example")
    }

    func testFetchCambridgeEnglishVietnameseHello() async throws {
        // Save current mode and restore after test
        let originalMode = PreferencesManager.shared.dictionaryMode
        PreferencesManager.shared.dictionaryMode = .engviet
        defer { PreferencesManager.shared.dictionaryMode = originalMode }

        let result = try await DictionaryService.shared.lookup(text: "hello")
        XCTAssertTrue(!result.simpleMeaning.isEmpty, "Should have a definition")
        XCTAssertTrue(!result.vietnameseMeaning.isEmpty, "Should have Vietnamese meaning")
        XCTAssertTrue(result.aiNotes?.contains("Vietnamese") == true)
    }

    func testFetchCambridgeEnglishVietnameseLizard() async throws {
        let originalMode = PreferencesManager.shared.dictionaryMode
        PreferencesManager.shared.dictionaryMode = .engviet
        defer { PreferencesManager.shared.dictionaryMode = originalMode }

        let result = try await DictionaryService.shared.lookup(text: "lizard")
        XCTAssertTrue(!result.simpleMeaning.isEmpty, "Should have a definition")
        XCTAssertTrue(!result.vietnameseMeaning.isEmpty, "Should have Vietnamese meaning")
    }

    func testFetchCambridgePhraseFallback() async throws {
        let result = try await DictionaryService.shared.lookup(text: "a big lizard")
        XCTAssertTrue(result.simpleMeaning.contains("phrase") || result.simpleMeaning.contains("Phrase"))
    }

    func testFetchCambridgeWithSpaces() async throws {
        let result = try await DictionaryService.shared.lookup(text: "  hello  ")
        XCTAssertTrue(!result.simpleMeaning.isEmpty)
    }
}
