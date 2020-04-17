import SwiftSyntax

extension SyntaxProtocol {
    var expectations: [Expectation] {
        let trivia: Trivia?
        switch self {
        case let node as SourceFileSyntax:
            trivia = node.eofToken.leadingTrivia
        default:
            trivia = leadingTrivia
        }

        return trivia?.comments.compactMap { Expectation($0) } ?? []
    }
}
