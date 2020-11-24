import XCTest
import DocTest

final class ScannerTests: XCTestCase {
    func testExample() throws {
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
}
