// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Bidi",
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.0.0")
    ],
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
            name: "BidiTests",
            dependencies: [ 
                "Bidi", 
                .product(name: "CustomDump", package: "swift-custom-dump")
        ]
        ),
        .testTarget(
            name: "SharedTests",
            dependencies: [ "Shared" ]),
        .testTarget(
            name: "UntypedTests",
            dependencies: [ 
                "Untyped",
                .product(name: "CustomDump", package: "swift-custom-dump")
            ]),
    ]
)
