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
            , url: "https://github.com/wang-bin/mdk-sdk/releases/download/v0.34.0/mdk-sdk-apple.zip"
            , checksum: "e9003c0639e59254692ac0796ed99ca1aad79e4d505636d468e796fd6d7afbe4"),
        .target(
            name: "swift-mdk",
            dependencies: ["mdk-sdk"]),
        .testTarget(
            name: "swift-mdkTests",
            dependencies: ["swift-mdk"]),
    ]
    //, .swiftLanguageVersions: [.version("6"), .v5]
)
