// swift-tools-version: 6.0
// PROTOTYPE - NOT FOR PRODUCTION
// TASK-033 spike (throwaway): the stardust morph as pure math, no UI imports, so a Kotlin port can copy it and
// prove itself against fixtures/morph-D-dinosaur.json.
import PackageDescription

let package = Package(
    name: "MorphCore",
    platforms: [.iOS("26.0"), .macOS("26.0")],
    products: [.library(name: "MorphCore", targets: ["MorphCore"])],
    targets: [
        .target(name: "MorphCore"),
        .executableTarget(name: "morph-fixture", dependencies: ["MorphCore"]),
        .testTarget(name: "MorphCoreTests", dependencies: ["MorphCore"]),
    ]
)
