import SwiftSyntax
import Foundation
import TAP

public class Statement {
    public let code: String
    public var sourceLocation: SourceLocation
    public internal(set) var expectations: [Expectation] = []

    public init?(_ node: CodeBlockItemSyntax, _ sourceLocation: SourceLocation) {
        let code = node.withoutTrivia().description.trimmed
        guard !code.isEmpty else { return nil }

        self.code = code
        self.sourceLocation = sourceLocation
    }

    public func tests(with result: Result<String, REPL.Error>) -> [Test] {
        var metadata: [String: Any] = [
            "file": self.sourceLocation.file as Any?,
            "line": self.sourceLocation.line as Any?,
            "column": self.sourceLocation.column as Any?
        ].compactMapValues { $0 }

        switch result {
        case .failure(let error):
            metadata["actual"] = error.description

            if expectations.isEmpty {
                return [test { .failure("- `\(self.code)` produced an error", directive: nil, metadata: metadata) }]
            } else {
                return expectations.map { expectation in
                    switch expectation {
                    case .error:
                        return test {
                            .success("- `\(self.code)` produced an error, as expected", directive: nil, metadata: metadata)
                        }
                    case .type(let expected),
                         .value(let expected),
                         .match(let expected):
                        metadata["expected"] = expected

                        return test {
                            .failure("- `\(self.code)` produced an error", directive: nil, metadata: metadata)
                        }
                    }
                }
            }
        case .success(let actual):
            metadata["actual"] = actual

            return expectations.map { expectation in
                switch expectation {
                case .type(let expected),
                     .value(let expected),
                     .match(let expected):
                    metadata["expected"] = expected

                    if expectation.evaluate(actual) {
                        return test {
                            .success("- `\(self.code)` produces `\(actual)`", directive: nil, metadata: metadata)
                        }
                    } else {
                        return test {
                            .failure("- `\(self.code)` produces `\(actual)`, expected `\(expected)`", directive: nil, metadata: metadata)
                        }
                    }
                case .error:
                    return test {
                        .failure("- `\(self.code)` didn't produce an error, which was unexpected", directive: nil, metadata: metadata)
                    }
                }
            }
        }
    }
}
