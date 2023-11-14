// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftLocation",
    platforms: [.iOS(.v14), .macOS(.v11), .watchOS(.v7), .tvOS(.v14)],
    products: [
        .library(
            name: "SwiftLocation",
            targets: ["SwiftLocation"]),
    ],
    targets: [
        .target(
            name: "SwiftLocation"),
        .testTarget(
            name: "SwiftLocationTests",
            dependencies: ["SwiftLocation"]),
    ]
)
