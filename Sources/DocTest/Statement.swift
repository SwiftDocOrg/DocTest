import SwiftSyntax
import Foundation
import TAP

public class Statement {
    public let code: String
    public let sourceLocation: SourceLocation
    public internal(set) var expectations: [Expectation] = []

    public init?(_ node: CodeBlockItemSyntax, _ sourceLocation: SourceLocation) {
        let code = node.withoutTrivia().description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return nil }
        
        self.code = code
        self.sourceLocation = sourceLocation
    }

    public func tests(with result: Result<String, REPL.Error>) -> [Test] {
        let metadata: [String: Any] = [
            "file": self.sourceLocation.file as Any?,
            "line": self.sourceLocation.line as Any?,
            "column": self.sourceLocation.column as Any?
        ].compactMapValues { $0 }

        return expectations.map { expectation in
            switch expectation {
            case .value(let expected):

                if case .success(let actual) = result {
                    if actual == expected {
                        return test {
                            .success("- `\(self.code)` produces `\(actual)`", directive: nil, metadata: metadata)
                        }
                    } else {
                        return test {
                            .failure("- `\(self.code)` produces `\(actual)`, expected `\(expected)`", directive: nil, metadata: metadata)
                        }
                    }

                } else {
                    return test {
                        .failure("- `\(self.code)` did not produce `\(expected)`", directive: nil, metadata: metadata)
                    }
                }
            case .error:
                if case .failure = result {
                    return test {
                        .success("- `\(self.code)` produced an error, as expected", directive: nil, metadata: metadata)
                    }
                } else {
                    return test {
                        .failure("- `\(self.code)` didn't produce an error, which was unexpected", directive: nil, metadata: metadata)
                    }
                }
            }
        }
    }
}
