// swift-tools-version: 6.1

import PackageDescription

// Benchmarks for BellMetal, kept in their own package so the benchmark
// dependency never reaches the library itself.
//
// BellMetal comes from a local path: this checkout's by default, or
// whichever checkout BELLMETAL_PATH names. That's how the same benchmark
// source runs against two versions (e.g. a worktree of develop and a
// feature branch) for comparison -- see README.md.
let bellMetalPath = Context.environment["BELLMETAL_PATH"] ?? ".."

let package = Package(
    name: "BellMetalBenchmarks",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/ordo-one/package-benchmark", from: "1.4.0"),
        .package(name: "BellMetal", path: bellMetalPath),
    ],
    targets: [
        .executableTarget(
            name: "BellMetalBenchmarks",
            dependencies: [
                .product(name: "Benchmark", package: "package-benchmark"),
                .product(name: "BellMetal", package: "BellMetal"),
            ],
            path: "Benchmarks/BellMetalBenchmarks",
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "package-benchmark"),
            ]
        ),
    ]
)
