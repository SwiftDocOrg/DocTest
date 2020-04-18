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
        runner.run(with: .default) { (result) in
            expectation.fulfill()

            switch result {
            case .failure(let error):
                XCTFail("\(error)")
            case .success(let report):
                XCTAssertEqual(report.results.count, 3)
                XCTAssertTrue(try! report.results[0].get().ok) // 1 + 1 => 2
                XCTAssertFalse(try! report.results[1].get().ok) // 1 + 1 => "wat"
                XCTAssertTrue(try! report.results[2].get().ok) // 1 / 0 !! Error
            }
        }
        wait(for: [expectation], timeout: 10.0)
    }
}
