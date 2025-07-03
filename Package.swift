// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "BellMetal",
    platforms: [.macOS(.v13),.iOS(.v16)],
    products: [
        .library(
            name: "BellMetal",
            targets: ["BellMetal"]
        ),
    ],
    dependencies: [
      .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.2.1")
    ],
    targets: [
        .target(
          name: "BellMetal",
          dependencies: [
            .product(name: "Algorithms", package: "swift-algorithms")
          ]
        ),
        .testTarget(
            name: "BellMetalTests",
            dependencies: ["BellMetal"]
        ),
    ]
)
