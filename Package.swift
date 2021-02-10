// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftLocation",
    platforms: [
        .macOS(.v11), .iOS(.v11)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SwiftLocation",
            targets: ["SwiftLocation"]
        ),
        .library(
            name: "SwiftLocation-Dynamic",
            type: .dynamic,
            targets: ["SwiftLocation"]
         ),
        .library(
            name: "SwiftLocationBeaconBroadcaster",
            targets: ["SwiftLocationBeaconBroadcaster"]
        ),
        .library(
            name: "SwiftLocationBeaconBroadcaster.Dynamic",
            type: .dynamic,
            targets: ["SwiftLocationBeaconBroadcaster"]
        )
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SwiftLocation",
            dependencies: [],
            path: "Sources/SwiftLocation"
        ),
        .target(
            name: "SwiftLocationBeaconBroadcaster",
            dependencies: ["SwiftLocation"],
            path: "Sources/SwiftLocationBeaconBroadcaster"
        ),
        .testTarget(
            name: "SwiftLocationTests",
            dependencies: ["SwiftLocation","SwiftLocationBeaconBroadcaster"]
        )
    ]
)
