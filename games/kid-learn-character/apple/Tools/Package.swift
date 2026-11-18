// swift-tools-version: 6.0
// Tools: macOS build-time tools (ADR-0002 D1, ADR-0003). Nothing here ships in the app. Platform frameworks and
// JSON decoding are allowed here (ADR-0002 D1-D2).
import PackageDescription

let package = Package(
    name: "Tools",
    platforms: [.macOS("26.0")],
    products: [.executable(name: "kidtools", targets: ["kidtools"])],
    dependencies: [.package(path: "../KidCore"), .package(path: "../MorphCore")],
    targets: [
        .executableTarget(name: "kidtools", dependencies: [
            .product(name: "KidCore", package: "KidCore"), .product(name: "MorphCore", package: "MorphCore"),
        ]),
        .testTarget(name: "ToolsTests", dependencies: ["kidtools"]),
    ]
)
