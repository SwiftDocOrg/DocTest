import Foundation

public enum Expectation: Hashable {
    case value(String)
    case error

    public init?(_ string: String?) {
        guard let string = string?.trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }
        if string.starts(with: "=>"),
            let index = string.firstIndex(where: { $0.isWhitespace })
        {
            self = .value(string.suffix(from: index).trimmingCharacters(in: .whitespaces))
        } else if string.starts(with: "!!") {
            self = .error
        } else {
            return nil
        }
    }
}
