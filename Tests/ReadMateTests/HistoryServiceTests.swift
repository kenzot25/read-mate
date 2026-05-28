import XCTest
@testable import ReadMate

final class HistoryServiceTests: XCTestCase {

    func testWordLookupEncodeDecode() {
        let result = LookupResult(
            simpleMeaning: "test",
            vietnameseMeaning: "thử",
            examples: ["Test."]
        )
        let lookup = WordLookup(
            selectedText: "test",
            sourceApp: "Safari",
            mode: "word",
            result: result
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try! encoder.encode([lookup])

        let decoded = try! JSONDecoder().decode([WordLookup].self, from: data)
        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded[0].selectedText, "test")
        XCTAssertEqual(decoded[0].sourceApp, "Safari")
        XCTAssertEqual(decoded[0].mode, "word")
        XCTAssertNotNil(decoded[0].result)
    }

    func testWordLookupUniqueBySelectedText() {
        let lookup1 = WordLookup(selectedText: "hello", sourceApp: "A")
        let lookup2 = WordLookup(selectedText: "hello", sourceApp: "B")

        XCTAssertNotEqual(lookup1.id, lookup2.id)
        XCTAssertEqual(lookup1.selectedText, lookup2.selectedText)
    }
}
