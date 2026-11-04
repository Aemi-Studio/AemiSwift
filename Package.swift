// swift-tools-version: 6.3
import PackageDescription

let package = Package(
  name: "AemiSwift",
  platforms: [
    .iOS(.v18), .macOS(.v15), .tvOS(.v18), .watchOS(.v11), .visionOS(.v2),
  ],
  products: [
    .library(name: "AemiConcurrency", targets: ["AemiConcurrency"]),
    .library(name: "AemiTesting", targets: ["AemiTestingCompatibility"]),
  ],
  dependencies: [
    .package(url: "https://github.com/Aemi-Studio/aemi.git", revision: "ca34b52c646abb2dc46125f9a7d42ba524823b32")
  ],
  targets: [
    .target(
      name: "AemiConcurrency",
      dependencies: [.product(name: "AemiCore", package: "aemi")]
    ),
    .target(
      name: "AemiTestingCompatibility",
      dependencies: [.product(name: "AemiTesting", package: "aemi")]
    ),
    .testTarget(
      name: "AemiTestingTests",
      dependencies: ["AemiConcurrency", "AemiTestingCompatibility"]
    ),
  ],
  swiftLanguageModes: [.v6]
)
