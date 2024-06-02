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
            name: "Simply",
            dependencies: [ "Shared" ],
            path: "Sources/Simply"
        ),
        .target(
            name: "Tartlet",
            dependencies: [ "Shared" ],
            path: "Sources/Tartlet"
        ),
        .executableTarget(
            name: "Executable",
            dependencies: [ "Untyped" ]),
        .testTarget(
            name: "SharedTests",
            dependencies: [ "Shared" ]),
        .testTarget(
            name: "SimplyTests",
            dependencies: [ 
                "Simply", 
                .product(name: "CustomDump", package: "swift-custom-dump")
            ]),
        .testTarget(
            name: "TartletTests",
            dependencies: [ "Tartlet" ]
        ),
        .testTarget(
            name: "UntypedTests",
            dependencies: [ 
                "Untyped",
                .product(name: "CustomDump", package: "swift-custom-dump")
            ]),
    ]
)
