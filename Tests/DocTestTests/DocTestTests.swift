import XCTest
import DocTest

final class DocTestTests: XCTestCase {
    func testRunner() throws {
        let source = #"""
        1 + 1 // => Int = 2
        1 + 1 // => String = "wat"
        1 / 0 // !! Error
        """#

        let expectation = XCTestExpectation()

        let runner = try Runner(source: source, assumedFileName: "Example.swift")
        runner.run(with: .default) { (report) in
            expectation.fulfill()

            XCTAssertEqual(report.outcomes.count, 3)
            XCTAssertTrue(report.outcomes[0].ok) // 1 + 1 => 2
            XCTAssertFalse(report.outcomes[1].ok) // 1 + 1 => "wat"
            XCTAssertTrue(report.outcomes[2].ok) // 1 / 0 !! Error
        }
        wait(for: [expectation], timeout: 10.0)
    }
}
