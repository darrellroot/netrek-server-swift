// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "netrek-server-swift",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
	.executable(name: "netrek-server-swift", targets: ["netrek-server-swift"]),
    ],   
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.2.0"),
    ],
    targets: [
        .target(name: "netrek-server-swift", dependencies: [
            .product(name: "NIO", package: "swift-nio"),
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ]),
    ]
)
