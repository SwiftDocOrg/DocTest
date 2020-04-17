import Foundation

public class REPL {
    public struct Configuration: Equatable {
        public var launchPath: String
        public var arguments: [String]

        public static let `default` = Configuration(launchPath: "/usr/bin/swift", arguments: [])

        public init(launchPath: String, arguments: [String]) {
            self.launchPath = launchPath
            self.arguments = arguments
        }
    }

    public struct Error: Swift.Error, LosslessStringConvertible {
        public var description: String

        public init?(_ description: String) {
            let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedDescription.isEmpty else { return nil }
            self.description = trimmedDescription
        }
    }

    private var process: Process!

    private let (beginDelimiter, endDelimiter): (String, String) = {
        let nonce = UUID()
        return ("<\(nonce)", ">\(nonce)")
    }()

    private let inputPipe = Pipe()
    private let outputPipe = Pipe()
    private let errorPipe = Pipe()

    private var outputBuffer = ""
    private var errorBuffer = ""

    private var queue: [Statement] = []

    public var evaluationHandler: ((Statement, Result<String, Error>) -> ())?

    public init(configuration: Configuration) {
        process = Process()

        if #available(OSX 10.13, *) {
            let url = URL(fileURLWithPath: configuration.launchPath)
            process.executableURL = url
        } else {
            process.launchPath = configuration.launchPath
        }

        process.arguments = configuration.arguments
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard let string = String(data: data, encoding: .utf8) else { return }
            self.outputBuffer += string


            guard let startRange = self.outputBuffer.range(of: self.beginDelimiter),
                let endRange = self.outputBuffer.range(of: self.endDelimiter)
            else {
                return
            }

            let statement = self.queue.removeFirst()

            defer {
                self.outputBuffer.removeSubrange(...endRange.upperBound)
                self.errorBuffer.removeAll()
            }

            let result: Result<String, Error>

            if let error = Error(self.errorBuffer) {
                result = .failure(error)
            } else {
                let start = self.outputBuffer.index(after: startRange.upperBound)
                let end = endRange.lowerBound

                let rawOutput = self.outputBuffer[start..<end]
                let lines: [Substring] = rawOutput.split(separator: "\n").map { line in
                    if line.hasPrefix("$R"),
                        let colonIndex = line.firstIndex(of: ":"),
                        let startIndex = line.index(colonIndex, offsetBy: 2, limitedBy: line.endIndex)
                    {
                        return line[startIndex...]
                    } else {
                        return line
                    }
                }

                result = .success(String(lines.joined(separator: "\n")))
            }

            self.evaluationHandler?(statement, result)
        }

        errorPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard let string = String(data: data, encoding: .utf8) else { return }
            self.errorBuffer += string
        }
    }

    public func evaluate(_ statement: Statement) {
        if !process.isRunning {
            if #available(OSX 10.13, *) {
                try! process.run()
            } else {
                process.launch()
            }
        }

        queue.append(statement)

        let lines = """
        print("\(self.beginDelimiter)")
        \(statement.code)
        print("\(self.endDelimiter)")

        """

        self.inputPipe.fileHandleForWriting.write(lines.data(using: .utf8)!)
    }

    deinit {
        outputPipe.fileHandleForReading.readabilityHandler = nil
    }

    public func waitUntilExit() {
        process.waitUntilExit()
    }

    public func close() {

      if #available(OSX 10.15, *) {
          try! self.inputPipe.fileHandleForWriting.close()
      }
    }
}
