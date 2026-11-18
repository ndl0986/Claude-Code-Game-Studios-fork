// swift-tools-version: 6.0
// KidCore: every game rule as pure, injectable Swift (ADR-0002 D1). Depends on MorphCore only; no UI or platform
// imports, and the ADR-0002 D2 type rules (tools/ci/ban-grep.sh). Mirrored by the Android app's `kidcore` module.
import PackageDescription

let package = Package(
    name: "KidCore",
    platforms: [.iOS("26.0"), .macOS("26.0")],
    products: [.library(name: "KidCore", targets: ["KidCore"])],
    dependencies: [.package(path: "../MorphCore")],
    targets: [
        .target(name: "KidCore", dependencies: [.product(name: "MorphCore", package: "MorphCore")]),
        .testTarget(name: "KidCoreTests", dependencies: ["KidCore"]),
    ]
)
