// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "DocTest",
    platforms: [
        .macOS(.v10_12)
    ],
    products: [
        .executable(name: "swift-doctest", targets: ["swift-doctest"]),
        .library(name: "DocTest", targets: ["DocTest"])
    ],
    dependencies: [
        .package(name: "SwiftSyntax",
                 url: "https://github.com/apple/swift-syntax.git",
                 .revision("0.50300.0")
        ),
        .package(url: "https://github.com/apple/swift-argument-parser.git",
                 .upToNextMinor(from: "0.3.1")
        ),
        .package(url: "https://github.com/SwiftDocOrg/TAP.git",
                 .upToNextMinor(from: "0.1.1")
        ),
        .package(url: "https://github.com/SwiftDocOrg/StringLocationConverter.git",
                 .upToNextMinor(from: "0.0.1")
        ),
        .package(url: "https://github.com/apple/swift-log.git",
                 .upToNextMinor(from: "1.4.0")
        ),
    ],
    targets: [
        .target(
            name: "swift-doctest",
            dependencies: [
                .target(name: "DocTest"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log"),
            ]),
        .target(
            name: "DocTest",
            dependencies: [
                .product(name: "SwiftSyntax", package: "SwiftSyntax"),
                .product(name: "StringLocationConverter", package: "StringLocationConverter"),
                .product(name: "TAP", package: "TAP"),
            ]),
        .testTarget(
            name: "DocTestTests",
            dependencies: [
                .target(name: "DocTest"),
            ]),
    ]
)
