import XCTest
@testable import ReadMate

final class AIServiceE2ETests: XCTestCase {

    var apiKey: String? {
        KeychainManager.shared.retrieve()
    }

    func testExplainRealAPI() async throws {
        guard let key = apiKey, !key.isEmpty else {
            throw XCTSkip("No Gemini API key in keychain. Skipping E2E test.")
        }

        let template = AITemplates.defaults[0]
        let result = try await AIService.shared.explain(text: "hello", template: template)

        XCTAssertFalse(result.simpleMeaning.isEmpty, "simpleMeaning should not be empty")
        XCTAssertFalse(result.vietnameseMeaning.isEmpty, "vietnameseMeaning should not be empty")
        XCTAssertEqual(result.examples.count, 3, "Should return exactly 3 examples")
    }

    func testExplainRealAPIWithPhrase() async throws {
        guard let key = apiKey, !key.isEmpty else {
            throw XCTSkip("No Gemini API key in keychain. Skipping E2E test.")
        }

        let template = AITemplates.defaults[0]
        let result = try await AIService.shared.explain(text: "The quick brown fox jumps over the lazy dog", template: template)

        XCTAssertFalse(result.simpleMeaning.isEmpty)
        XCTAssertFalse(result.vietnameseMeaning.isEmpty)
        XCTAssertEqual(result.examples.count, 3)
    }

    func testExplainRealAPIMissingKeyThrows() async {
        let originalKey = apiKey
        KeychainManager.shared.delete()
        defer {
            if let key = originalKey { KeychainManager.shared.save(key: key) }
        }

        let template = AITemplates.defaults[0]
        do {
            _ = try await AIService.shared.explain(text: "hello", template: template)
            XCTFail("Should throw missingApiKey error")
        } catch let error as AIError {
            XCTAssertEqual(error, AIError.missingApiKey)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
