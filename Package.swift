// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Lumina",
  platforms: [.iOS(.v13)],
  products: [
    .library(name: "Lumina",targets: ["Lumina"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0")
  ],
  targets: [
    .target(name: "Lumina", dependencies: [
      .product(name: "Logging", package: "swift-log")
    ]),
    .testTarget(name: "LuminaTests", dependencies: ["Lumina"]),
  ]
)
