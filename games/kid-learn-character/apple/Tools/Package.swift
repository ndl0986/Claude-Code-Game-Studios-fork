// swift-tools-version: 6.0
// Tools: macOS build-time tools (ADR-0002 D1, ADR-0003). Nothing here ships in the app. Platform frameworks and
// JSON decoding are allowed here (ADR-0002 D1-D2).
import PackageDescription

let package = Package(
    name: "Tools",
    platforms: [.macOS("26.0")],
    products: [
        .executable(name: "kidtools", targets: ["kidtools"]),
        .library(name: "ToolsCore", targets: ["ToolsCore"]),
    ],
    dependencies: [.package(path: "../KidCore"), .package(path: "../MorphCore"), .package(path: "../ContractKit")],
    targets: [
        .target(name: "ToolsCore", dependencies: [
            .product(name: "KidCore", package: "KidCore"), .product(name: "MorphCore", package: "MorphCore"),
        ]),
        .executableTarget(name: "kidtools", dependencies: ["ToolsCore"]),
        // ToolsTests: the key-table-schema-v1 "file" layer (ADR-0004 D3, D5). ContractKit is test-only (K-38).
        .testTarget(name: "ToolsTests", dependencies: ["ToolsCore", .product(name: "ContractKit", package: "ContractKit")]),
    ]
)
