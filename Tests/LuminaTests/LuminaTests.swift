import XCTest
@testable import Lumina

final class LuminaTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Lumina().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
