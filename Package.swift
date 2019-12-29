// swift-tools-version:5.1
import PackageDescription

let package = Package(
  name: "Lumina",
  platforms: [
    .iOS(.v12)
  ],
  products: [
    .library(name: "Lumina", type: .dynamic, targets: ["Lumina"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0")
  ],
  targets: [
    .target(name: "Lumina", dependencies: ["Logging"])
  ]
)
