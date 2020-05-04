import SwiftSyntax
import Foundation
import TAP

public final class Runner {
    public let statements: [Statement]

    public convenience init(source: String, assumedFileName: String, lineOffset: Int = 0) throws {
        let tree = try SyntaxParser.parse(source: source)
        let sourceLocationConverter = SourceLocationConverter(file: assumedFileName, tree: tree)
        self.init(syntax: tree, sourceLocationConverter: sourceLocationConverter)
        for statement in statements {
            if let line = statement.sourceLocation.line,
                let column = statement.sourceLocation.column,
                let file = statement.sourceLocation.file
            {
                statement.sourceLocation = SourceLocation(line: line + lineOffset, column: column, offset: statement.sourceLocation.offset, file: file)
            }
        }
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
            tests.append(contentsOf: statement.tests(with: result))
        }

        for statement in statements {
            repl.evaluate(statement)
        }

        repl.close()
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
