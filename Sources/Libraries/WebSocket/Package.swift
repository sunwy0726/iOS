// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "HAWebSocket",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_14),
    ],
    products: [
        .library(
            name: "HAWebSocket",
            targets: ["HAWebSocket"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/daltoniam/Starscream", 
            from: "4.0.4"
        ),
    ],
    targets: [
        .target(
            name: "HAWebSocket",
            dependencies: [
                .byName(name: "Starscream"),
            ],
            path: "Source"
        ),
        .testTarget(
            name: "HAWebSocketTests",
            dependencies: ["HAWebSocket"],
            path: "Tests"
        ),
    ]
)
