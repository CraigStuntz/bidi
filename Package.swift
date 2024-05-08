// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Bidi",
    targets: [
        .target(
            name: "Shared",
            path: "Sources/Shared"
        ),
        .target(
            name: "Untyped",
            dependencies: [ "Shared" ],
            path: "Sources/Untyped"
        ),
        .target(
            name: "Bidi",
            dependencies: [ "Shared" ],
            path: "Sources/Bidi"
        ),
        .executableTarget(
            name: "Executable",
            dependencies: [ "Untyped" ]),
        .testTarget(
            name: "SharedTests",
            dependencies: [ "Shared" ]),
        .testTarget(
            name: "UntypedTests",
            dependencies: [ "Untyped" ]),
    ]
)
