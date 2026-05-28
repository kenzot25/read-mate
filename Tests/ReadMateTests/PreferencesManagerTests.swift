import XCTest
@testable import ReadMate

final class PreferencesManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "dictionaryMode")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "dictionaryMode")
        super.tearDown()
    }

    func testDefaultModeIsEngViet() {
        XCTAssertEqual(PreferencesManager.shared.dictionaryMode, .engviet)
    }

    func testSetAndGetMode() {
        PreferencesManager.shared.dictionaryMode = .engeng
        XCTAssertEqual(PreferencesManager.shared.dictionaryMode, .engeng)

        PreferencesManager.shared.dictionaryMode = .engviet
        XCTAssertEqual(PreferencesManager.shared.dictionaryMode, .engviet)
    }

    func testModePersists() {
        PreferencesManager.shared.dictionaryMode = .engeng
        let fresh = PreferencesManager.shared.dictionaryMode
        XCTAssertEqual(fresh, .engeng)
    }
}
