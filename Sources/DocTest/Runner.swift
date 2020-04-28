import SwiftSyntax
import Foundation
import TAP

public final class Runner {
    let statements: [Statement]

    public convenience init(source: String, assumedFileName: String) throws {
        let tree = try SyntaxParser.parse(source: source)
        let sourceLocationConverter = SourceLocationConverter(file: assumedFileName, tree: tree)
        self.init(syntax: tree, sourceLocationConverter: sourceLocationConverter)
    }

    public convenience init(file url: URL) throws {
        let tree = try SyntaxParser.parse(url)
        let sourceLocationConverter = SourceLocationConverter(file: url.path, tree: tree)
        self.init(syntax: tree, sourceLocationConverter: sourceLocationConverter)
    }

    public required init(syntax tree: SourceFileSyntax, sourceLocationConverter: SourceLocationConverter) {
        let visitor = Visitor(sourceLocationConverter)
        visitor.walk(tree)

        self.statements = visitor.statements
    }

    public func run(with configuration: REPL.Configuration, completion: (Result<Report, Error>) -> Void) {
        var tests: [Test] = []

        let repl = REPL(configuration: configuration)

        repl.evaluationHandler = { (statement, result) in
            print("evaluationHandler for REPL called back with \(statement) and \(result)")
            tests.append(contentsOf: statement.tests(with: result))
        }

        for statement in statements {
            print("sending statement for evaluation: \(String(reflecting: statement))")
            repl.evaluate(statement)
        }
        print("closing REPL")
        repl.close()
        print("waiting for REPL process to terminate")
        repl.waitUntilExit()

        completion(Result<Report, Error> { try tests.run() })
    }

    private class Visitor: SyntaxVisitor {
        let sourceLocationConverter: SourceLocationConverter
        var statements: [Statement] = []

        init(_ sourceLocationConverter: SourceLocationConverter) {
            self.sourceLocationConverter = sourceLocationConverter
        }

        override func visit(_ node: CodeBlockItemSyntax) -> SyntaxVisitorContinueKind {
            statements.last?.expectations += node.leadingTrivia?.expectations ?? []

            let sourceLocation = sourceLocationConverter.location(for: node.position)
            if let statement = Statement(node, sourceLocation) {
                statements.append(statement)
            }

            return .skipChildren
        }

        override func visitPost(_ node: CodeBlockItemSyntax) {
            statements.last?.expectations += node.trailingTrivia?.expectations ?? []
        }

        override func visitPost(_ node: SourceFileSyntax) {
            statements.last?.expectations += node.eofToken.leadingTrivia?.expectations ?? []
        }
    }
}
