import XCTest
import DocTest

final class DocTestTests: XCTestCase {
    func testRunner() throws {
        let source = #"""
        1 + 1 // => 2
        1 + 1 // -> String
        1 / 0 // !! error: division by zero
        invalid
        1 + 1 // ~> Int = \d
        """#

        let expectation = XCTestExpectation()

        let runner = try Runner(source: source, assumedFileName: "Example.swift")
        runner.run(with: .default) { (result) in
            switch result {
            case .failure(let error):
                XCTFail("\(error)")
            case .success(let report):
                XCTAssertEqual(report.results.count, 5)
                XCTAssertTrue(try! report.results[0].get().ok) // 1 + 1 => 2
                XCTAssertFalse(try! report.results[1].get().ok) // 1 + 1 => "wat"
                XCTAssertTrue(try! report.results[2].get().ok) // 1 / 0 !! Error
                XCTAssertFalse(try! report.results[3].get().ok) // invalid
                XCTAssertTrue(try! report.results[4].get().ok) // 1 + 1 => 2

                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 10.0)
    }

    func testExpectations() throws {
        XCTAssertEqual(Expectation("-> Int"), .type("Int"))
        XCTAssertEqual(Expectation("=> 2"), .value("2"))
        XCTAssertEqual(Expectation(#"~> Int = \d+"#), .match(#"Int = \d+"#))
        XCTAssertEqual(Expectation("!! error: division by zero"), .error)
    }
}
