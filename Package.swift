// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DocTest",
    platforms: [
        .macOS(.v10_10)
    ],
    products: [
        .executable(name: "swift-doctest", targets: ["swift-doctest"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-syntax.git", .revision("0.50200.0")),
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMinor(from: "0.0.4")),
        .package(url: "https://github.com/SwiftDocOrg/TAP.git", .upToNextMinor(from: "0.1.1")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "swift-doctest",
            dependencies: ["DocTest", "ArgumentParser"]),
        .target(
            name: "DocTest",
            dependencies: ["SwiftSyntax", "TAP"]),
        .testTarget(
            name: "DocTestTests",
            dependencies: ["DocTest"]),
    ]
)
