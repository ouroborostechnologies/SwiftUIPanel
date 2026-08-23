// swift-tools-version: 5.9
import PackageDescription

// FloatingPanelKit, shipped under the existing `SwiftUIPanel` name so that
// dependents keep resolving. See README.md for the design spec this follows.
let package = Package(
    name: "SwiftUIPanel",
    platforms: [
        .macOS(.v14), .iOS(.v17)
    ],
    products: [
        .library(name: "SwiftUIPanel", targets: ["SwiftUIPanel"])
    ],
    targets: [
        .target(name: "SwiftUIPanel"),
        .testTarget(name: "SwiftUIPanelTests", dependencies: ["SwiftUIPanel"])
    ]
)
