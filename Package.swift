// swift-tools-version: 5.9
import PackageDescription

let tdlibPath = "./tdlib-local"

let package = Package(
    name: "TelegramVoiceHotkey",
    platforms: [.macOS(.v13)],
    targets: [
        .systemLibrary(
            name: "CTDLib",
            path: "Sources/CTDLib",
            pkgConfig: nil,
            providers: []
        ),
        .executableTarget(
            name: "TelegramVoiceHotkey",
            dependencies: ["CTDLib"],
            path: "Sources",
            exclude: ["CTDLib"],
            linkerSettings: [
                .unsafeFlags([
                    "-L\(tdlibPath)/lib",
                    "-rpath", "@executable_path/../Resources/lib",
                ]),
                .linkedLibrary("tdjson"),
            ]
        ),
    ]
)
