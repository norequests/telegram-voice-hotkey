// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VoiceToSlop",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "VoiceToSlop",
            path: "Sources",
            exclude: ["CTDLib"]
        ),
    ]
)
