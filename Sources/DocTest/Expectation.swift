import Foundation

public enum Expectation: Hashable {
    case error
    case type(String)
    case value(String)
    case match(String)

    public init?(_ string: String?) {
        guard let string = string?.trimmed,
              let index = string.index(string.startIndex, offsetBy: 2, limitedBy: string.endIndex)
        else { return nil }

        switch string.prefix(upTo: index) {
        case "!!":
            self = .error
        case "->":
            self = .type(string.suffix(from: index).trimmed)
        case "=>":
            self = .value(string.suffix(from: index).trimmed)
        case "~>":
            self = .match(string.suffix(from: index).trimmed)
        default:
            return nil
        }
    }

    public func evaluate(_ output: String) -> Bool {
        let output = output.trimmed

        switch self {
        case .error:
            return output.hasPrefix("error:")
        case .type(let type):
            return output.hasPrefix("\(type) =")
        case .value(let value):
            return output.hasSuffix("= \(value)")
        case .match(let pattern):
            return output.range(of: pattern, options: .regularExpression) != nil
        }
    }
}
