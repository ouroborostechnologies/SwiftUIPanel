// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftUIPanel",
    platforms: [
        .macOS(.v13), .iOS(.v16)
    ],
    products: [
        .library(name: "SwiftUIPanel", targets: ["SwiftUIPanel"])
    ],
    dependencies: [],
    targets: [
        .target(name: "SwiftUIPanel", dependencies: [])
    ]
)
