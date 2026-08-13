// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "SoundAnchor",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "SoundAnchor", targets: ["SoundAnchor"])
    ],
    targets: [
        .executableTarget(
            name: "SoundAnchor",
            path: "Sources/SoundAnchor"
        ),
        .testTarget(
            name: "SoundAnchorTests",
            dependencies: ["SoundAnchor"],
            path: "Tests/SoundAnchorTests"
        )
    ]
)
