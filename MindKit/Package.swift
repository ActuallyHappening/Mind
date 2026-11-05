// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MindKit",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [.library(name: "MindKit", targets: ["MindKit"])],
    targets: [
        .target(name: "MindKit"),
        .testTarget(name: "MindKitTests", dependencies: ["MindKit"]),
    ],
    swiftLanguageModes: [.v5]
)
