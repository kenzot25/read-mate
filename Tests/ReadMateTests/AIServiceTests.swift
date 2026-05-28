import XCTest
@testable import ReadMate

final class AIServiceTests: XCTestCase {

    func testAIErrorMissingApiKeyDescription() {
        let error = AIError.missingApiKey
        XCTAssertEqual(error.localizedDescription, "Please enter a valid Gemini API Key in the Settings tab.")
    }

    func testAIErrorInvalidResponseDescription() {
        let error = AIError.invalidResponse
        XCTAssertEqual(error.localizedDescription, "Failed to parse the response from the Gemini API.")
    }

    func testAIErrorApiErrorDescription() {
        let error = AIError.apiError("Rate limit exceeded")
        XCTAssertEqual(error.localizedDescription, "Rate limit exceeded")
    }
}
