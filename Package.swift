// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AemiSwift",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .tvOS(.v18),
        .watchOS(.v11),
        .visionOS(.v2),
    ],
    products: [
        .library(name: "AemiConcurrency", targets: ["AemiConcurrency"]),
        .library(name: "AemiTesting", targets: ["AemiTesting"]),
    ],
    targets: [
        .target(name: "AemiConcurrency"),
        .target(
            name: "AemiTesting",
            dependencies: ["AemiConcurrency"]
        ),
        .testTarget(
            name: "AemiTestingTests",
            dependencies: ["AemiConcurrency", "AemiTesting"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
