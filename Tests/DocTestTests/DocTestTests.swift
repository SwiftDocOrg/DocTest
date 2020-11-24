import XCTest
import DocTest

final class DocTestTests: XCTestCase {
    func testRunner() throws {
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

    func testScanner() throws {
        let scanner = try Scanner()


        let source = #"""
        /**
            Returns the sum of two integers.

            ```swift doctest
            add(1, 3) // => 2
            ```
        */
        func add(_ a: Int, _ b: Int) -> Int {
            return a + b
        }

        /**
            Returns the product of two integers.
        */
        func multiply(_ a: Int, _ b: Int) -> Int {
            return a * b
        }
        """#

        let matches = scanner.matches(in: source)

        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches.first?.line, 5)
        XCTAssertEqual(matches.first?.column, 1)
        XCTAssertEqual(matches.first?.content, "add(1, 3) // => 2")
    }

    func testExpectations() throws {
        XCTAssertEqual(Expectation("-> Int"), .type("Int"))
        XCTAssertEqual(Expectation("=> 2"), .value("2"))
        XCTAssertEqual(Expectation(#"~> Int = \d+"#), .match(#"Int = \d+"#))
        XCTAssertEqual(Expectation("!! error: division by zero"), .error)
    }
}
