// swift-tools-version: 5.9
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
            , url: "https://github.com/wang-bin/mdk-sdk/releases/download/v0.29.0/mdk-sdk-apple.zip"
            , checksum: "77cd52e9c62a9b5fffc76e0b699e8a62291ea902ba3c44ac5481aa49fd51a0f7"),
        .target(
            name: "swift-mdk",
            dependencies: ["mdk-sdk"]),
        .testTarget(
            name: "swift-mdkTests",
            dependencies: ["swift-mdk"]),
    ]
)
