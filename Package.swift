// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Bidi",
    targets: [
        .target(
            name: "Bidi",
            path: "Sources/Bidi"
        ),
        .executableTarget(
            name: "Executable",
            dependencies: [ "Bidi" ]),
        .testTarget(
            name: "BidiTests",
            dependencies: [ "Bidi" ]),
    ]
)
