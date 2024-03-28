// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BellMetal",
    platforms: [.macOS(.v13), .iOS(.v17)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "BellMetal",
            targets: ["BellMetal"]),
    ],
    dependencies: [
      .package(
        url: "https://github.com/Quick/Nimble.git",
        from: "12.0.0"
      ),
      .package(
        url: "https://github.com/dankogai/swift-combinatorics.git",
        from: "0.0.1"
      )
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "BellMetal",
            dependencies: [.product(name: "Combinatorics", package: "swift-combinatorics")]
        ),
        .testTarget(
            name: "BellMetalTests",
            dependencies: ["BellMetal", "Nimble"]),
    ]
)
