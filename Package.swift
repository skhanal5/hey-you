// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HeyYou",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "HeyYou"
        ),
        .testTarget(
            name: "HeyYouTests",
            dependencies: ["HeyYou"]
        ),
    ]
)
