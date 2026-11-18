// swift-tools-version: 6.0
// PROTOTYPE - NOT FOR PRODUCTION (TASK-078 DeviceSpike). Pure helpers for the spike app, tested headless with
// `swift test`. Never moved into apple/ (TASK-075): the stories re-implement what the ADRs decide.
import PackageDescription

let package = Package(
    name: "SpikeKit",
    platforms: [.iOS("26.0"), .macOS("26.0")],
    products: [.library(name: "SpikeKit", targets: ["SpikeKit"])],
    targets: [
        .target(name: "SpikeKit"),
        .testTarget(name: "SpikeKitTests", dependencies: ["SpikeKit"]),
    ]
)
