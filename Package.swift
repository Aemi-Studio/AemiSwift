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
    .package(url: "https://github.com/Aemi-Studio/aemi.git", revision: "785c6b25cb3f4dc16ca2334fd69428fae4ee0b01")
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
