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
    .package(url: "https://github.com/Aemi-Studio/aemi.git", revision: "409c647a91736065ac53c1877abe2cf4840f7617")
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
