import SwiftSyntax

extension Trivia {
    var comments: [String] {
        compactMap { piece -> String? in
            switch piece {
            case let .lineComment(comment):
                let startIndex = comment.index(comment.startIndex, offsetBy: 2)
                return String(comment.suffix(from: startIndex))
            case let .blockComment(comment):
                let startIndex = comment.index(comment.startIndex, offsetBy: 2)
                let endIndex = comment.index(comment.endIndex, offsetBy: -2)
                return String(comment[startIndex ..< endIndex])
            default:
                return nil
            }
        }
    }

    var expectations: [Expectation] {
        return comments.compactMap { Expectation($0) }
    }
}
