import XCTest
import DocTest

final class RunnerTests: XCTestCase {
    func testExample() throws {
        let source = #"""
        1 + 2 // => 3
        1 + 2 // -> String
        1 / 0 // !! error: division by zero
        invalid
        1 + 2 // ~> Int = \d
        """#

        let expectation = XCTestExpectation()

        let runner = try Runner(source: source, assumedFileName: "Example.swift")
        runner.run(with: .default) { (result) in
            switch result {
            case .failure(let error):
                XCTFail("\(error)")
            case .success(let report):
                XCTAssertEqual(report.results.count, 5)
                XCTAssertTrue(try! report.results[0].get().ok)
                XCTAssertFalse(try! report.results[1].get().ok)
                XCTAssertTrue(try! report.results[2].get().ok)
                XCTAssertFalse(try! report.results[3].get().ok)
                XCTAssertTrue(try! report.results[4].get().ok)

                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 10.0)
    }
}
