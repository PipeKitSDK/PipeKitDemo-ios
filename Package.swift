// swift-tools-version: 5.9
// NOTE: This file is kept for SPM compatibility only.
// Open PipeKitDemo.xcodeproj in Xcode for the full iOS/iPad/macOS project.

import PackageDescription

let package = Package(
    name: "PipeKitDemo",
    platforms: [
        .iOS(.v16),
    ],
    dependencies: [
        .package(path: "../PipeKitSDK"),
    ],
    targets: [
        .executableTarget(
            name: "PipeKitDemo",
            dependencies: [
                .product(name: "PipeKitSDK", package: "PipeKitSDK"),
            ],
            path: "PipeKitDemo"
        ),
    ]
)
