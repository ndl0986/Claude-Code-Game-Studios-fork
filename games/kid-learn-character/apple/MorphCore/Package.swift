// swift-tools-version: 6.0
// MorphCore: the stardust morph as pure maths (morph-contract-v1). No UI or platform imports (ADR-0001, ADR-0002 D1).
// Depends on nothing. Mirrored by name in the Android app's `morphcore` module (ADR-0002 D8).
import PackageDescription

let package = Package(
    name: "MorphCore",
    platforms: [.iOS("26.0"), .macOS("26.0")],
    products: [.library(name: "MorphCore", targets: ["MorphCore"])],
    targets: [
        .target(name: "MorphCore"),
        .testTarget(name: "MorphCoreTests", dependencies: ["MorphCore"]),
    ]
)
