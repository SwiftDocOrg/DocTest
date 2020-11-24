import ArgumentParser
import DocTest
import Foundation
import TAP
import StringLocationConverter
import Logging

// Pattern borrowed upstream from Swift:
// https://github.com/apple/swift/blob/87d3b4d984281b113ffad503cdb1d82b9f0ae5b9/test/Interpreter/SDK/libc.swift#L12-L17
#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
import Darwin
#elseif os(Linux) || os(FreeBSD) || os(PS4) || os(Android) || os(Cygwin) || os(Haiku)
import Glibc
#elseif os(Windows)
import MSVCRT
#endif

LoggingSystem.bootstrap { label in
    return StreamLogHandler.standardError(label: label)
}

let fileManager = FileManager.default

var standardInput = FileHandle.standardInput
var standardOutput = FileHandle.standardOutput

struct SwiftDocTest: ParsableCommand {
    struct Options: ParsableArguments {
        @Argument(help: "Swift code or a path to a Swift file")
        var input: String

        @Option(name: [.customLong("swift-launch-path")],
                help: "The path to the swift executable.")
        var launchPath: String = REPL.Configuration.default.launchPath

        @Flag(name: [.customShort("p"), .customLong("package")],
              help: "Whether to run the REPL through Swift Package Manager (`swift run --repl`).")
        var runThroughPackageManager: Bool = false

        @Option(name: [.customLong("assumed-filename")],
                help: "The assumed filename to use for reporting when parsing from standard input.")
        var assumedFilename: String = "Untitled.swift"

        @Flag(help: "Use verbose output")
        var verbose: Bool = false
    }

    static var configuration = CommandConfiguration(
        commandName: "swift-doctest",
        abstract: "A utility for syntax testing documentation in Swift code."
    )

    @OptionGroup()
    var options: Options

    func run() throws {
        var logger = Logger(label: "org.swiftdoc.doctest")
        logger.logLevel = options.verbose ? .trace : .warning

        logger.trace("Starting \(SwiftDocTest.configuration.commandName ?? "")")

        let input = options.input

        let configuration = REPL.Configuration(launchPath: options.launchPath, arguments: options.runThroughPackageManager ? ["run", "--repl"] : [])

        logger.debug("Swift launch path: \(configuration.launchPath)")
        logger.debug("Swift launch arguments: \(configuration.arguments)")

        let scanner = try Scanner()

        let source: String
        let assumedFileName: String
        if fileManager.fileExists(atPath: input) {
            let url = URL(fileURLWithPath: input)
            source = try String(contentsOf: url)
            assumedFileName = url.relativePath
            logger.trace("Scanning \(url.path) for DocTest blocks")
        } else {
            source = input
            assumedFileName = options.assumedFilename
            logger.trace("Scanning standard input for DocTest blocks")
        }

        var reports: [Report] = []

        let group = DispatchGroup()
        for match in scanner.matches(in: source) {
            logger.info("Found DocTest block at \(assumedFileName)#\(match.line):\(match.column)\n\(match.content)")

            var lineOffset = match.line
            var code = match.content
            if options.runThroughPackageManager {
                if source.range(of: #"^import \w"#, options: [.regularExpression]) == nil {
                    logger.notice("No import statements found at \(assumedFileName)#\(match.line):\(match.column). This may cause unexpected API resolution failures when running through Swift Package Manager.")
                }
            } else {
                code = "\(source)\n\(code)"
                lineOffset -= source.split(whereSeparator: { $0.isNewline }).count + 1
            }

            let runner = try Runner(source: code, assumedFileName: assumedFileName, lineOffset: lineOffset)
            group.enter()
            runner.run(with: configuration) { result in
                switch result {
                case .failure(let error):
                    reports.append(Report(results: [.failure(BailOut("\(error)"))]))
                    logger.notice("\(error)")
                case .success(let report):
                    reports.append(report)
                }
                group.leave()
            }
        }
        group.wait()

        logger.trace("Finished running tests.")
        logger.trace("Printing test report in TAP format.")

        let consolidatedReport = Report.consolidation(of: reports)
        standardOutput.write(consolidatedReport.description.data(using: .utf8)!)

        if consolidatedReport.results.contains(where: { (try? $0.get().ok) != true }) {
            // Return a non-zero result code if any tests failed
            #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
            Darwin.exit(EXIT_FAILURE)
            #elseif os(Linux) || os(FreeBSD) || os(PS4) || os(Android) || os(Cygwin) || os(Haiku)
            Glibc.exit(EXIT_FAILURE)
            #endif
        }
    }
}

if ProcessInfo.processInfo.arguments.count == 1 {
    let input = standardInput.readDataToEndOfFile()
    let source = String(data: input, encoding: .utf8)!
    SwiftDocTest.main([source])
} else {
    SwiftDocTest.main()
}
