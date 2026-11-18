// swift-tools-version: 6.0
// ContractKit (K-38): test-only. Loads contract fixtures (ADR-0004) and decodes their JSON for the KidCore and Tools
// test targets. Never linked into the app or a core (ADR-0002 D1 note).
import PackageDescription

let package = Package(
    name: "ContractKit",
    platforms: [.iOS("26.0"), .macOS("26.0")],
    products: [.library(name: "ContractKit", targets: ["ContractKit"])],
    targets: [
        .target(name: "ContractKit"),
        .testTarget(name: "ContractKitTests", dependencies: ["ContractKit"]),
    ]
)
