// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "USBChime",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "USBChime",
            path: "Sources",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
