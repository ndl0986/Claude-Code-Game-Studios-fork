// swift-tools-version:5.9
// GameCore: the iOS game core (ADR-0001). Foundation only: no UIKit, no SpriteKit,
// so every rule and every shared fixture in content/fixtures runs as a plain unit test.
import PackageDescription

let package = Package(
    name: "GameCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "GameCore", targets: ["GameCore"])],
    targets: [
        .target(name: "GameCore"),
        .testTarget(
            name: "GameCoreTests",
            dependencies: ["GameCore"],
            // content/ is the repo's shared data; tests read it in place (data, samples, fixtures).
            resources: []
        ),
    ]
)
