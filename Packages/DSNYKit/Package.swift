// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "DSNYKit",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(name: "DSNYKit", targets: ["DSNYKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.7.0")
    ],
    targets: [
        .target(
            name: "DSNYKit",
            dependencies: ["SwiftSoup"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "DSNYKitTests",
            dependencies: ["DSNYKit"],
            resources: [.copy("Fixtures")]
        )
    ]
)
