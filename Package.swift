// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-mdk",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "swift-mdk",
            targets: ["swift-mdk"]),
    ],
    dependencies: [
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        //.binaryTarget(name: "mdk-sdk", path: "mdk-sdk/lib/mdk.xcframework"),
        .binaryTarget(name: "mdk-sdk"
            , url: "https://github.com/wang-bin/mdk-sdk/releases/download/v0.36.0/mdk-sdk-apple.zip"
            , checksum: "9c73e96a113096c9e8d9d255477e5327301bff6dead2266f7ab5436d37d6ccb6"),
        .target(
            name: "swift-mdk",
            dependencies: ["mdk-sdk"]),
        .testTarget(
            name: "swift-mdkTests",
            dependencies: ["swift-mdk"]),
    ]
    //, .swiftLanguageVersions: [.version("6"), .v5]
)
