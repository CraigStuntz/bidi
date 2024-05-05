// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Bidi",
    targets: [
        .target(
            name: "Untyped",
            path: "Sources/Untyped"
        ),
        .target(
            name: "Bidi",
            path: "Sources/Bidi"
        ),
        .executableTarget(
            name: "Executable",
            dependencies: [ "Untyped" ]),
        .testTarget(
            name: "UntypedTests",
            dependencies: [ "Untyped" ]),
    ]
)
