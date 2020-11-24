import Foundation
import StringLocationConverter

public class Scanner {
    public typealias Match = (line: Int, column: Int, content: String)

    private var regularExpression: NSRegularExpression

    public init() throws {
        let pattern = #"""
        ^
        \h* \`{3} \h* swift \h+ doctest \h* \n
        (.+)\n
        \h* \`{3} \h*
        $
        """#
        self.regularExpression = try NSRegularExpression(pattern: pattern,
                                                         options: [
                                                            .allowCommentsAndWhitespace,
                                                            .anchorsMatchLines,
                                                            .caseInsensitive,
                                                            .dotMatchesLineSeparators
                                                         ])
    }

    public func matches(in source: String) -> [Match] {
        let range = NSRange(source.startIndex..<source.endIndex, in: source)
        return regularExpression.matches(in: source, options: [], range: range).compactMap { result in
            guard result.numberOfRanges == 2,
                let range = Range(result.range(at: 1), in: source)
                else { return nil }
            let content = source[range]

            let converter = StringLocationConverter(for: source)

            let line: Int, column: Int
            if let location = converter.location(for: range.lowerBound, in: source) {
                line = location.line
                column = location.column
            } else {
                line = 0
                column = range.lowerBound.utf16Offset(in: source)
            }

            return (line, column, content.trimmed)
        }
    }
}
