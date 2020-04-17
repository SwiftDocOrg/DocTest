import XCTest

import doctestTests

var tests = [XCTestCaseEntry]()
tests += doctestTests.allTests()
XCTMain(tests)
