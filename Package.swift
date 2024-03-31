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
            , url: "https://sourceforge.net/projects/mdk-sdk/files/mdk-sdk-apple.zip"
            , checksum: "f4a950692e8429653c222f2ffa9822ef90613e204c65b9f9178c02e3df933207"),
        .target(
            name: "swift-mdk",
            dependencies: ["mdk-sdk"]),
        .testTarget(
            name: "swift-mdkTests",
            dependencies: ["swift-mdk"]),
    ]
)
