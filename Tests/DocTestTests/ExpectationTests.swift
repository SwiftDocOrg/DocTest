import XCTest
import DocTest

final class ExpectationTests: XCTestCase {
    func testTypeExpectation() throws {
        XCTAssertEqual(Expectation("-> Int"), .type("Int"))
    }

    func testValueExpectation() throws {
        XCTAssertEqual(Expectation("=> 2"), .value("2"))
    }

    func testMatchExpectation() throws {
        XCTAssertEqual(Expectation(#"~> Int = \d+"#), .match(#"Int = \d+"#))
    }

    func testErrorExpectation() throws {
        XCTAssertEqual(Expectation("!! error: division by zero"), .error)
    }

    func testInvalidExpectation() throws {
        XCTAssertNil(Expectation("invalid"))
    }
}
