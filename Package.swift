// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NetSpeed",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "NetSpeed",
            path: "Sources",
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Resources/Info.plist"
                ])
            ]
        )
    ]
)
