// swift-tools-version: 5.10

import PackageDescription

let package = Package(
  name: "FRSync",
  platforms: [
    .iOS(.v13)
  ],
  products: [
    .library(name: "FRSync", targets: ["FRSync"]),
  ],
  dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "11.13.0"),
    .package(url: "https://github.com/sereivoanyong/realm-swift", branch: "sy/community"),
  ],
  targets: [
    .target(
      name: "FRSync",
      dependencies: [
        .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
        .product(name: "RealmSwift", package: "realm-swift"),
      ]
    ),
    .testTarget(
      name: "FRSyncTests",
      dependencies: ["FRSync"]
    )
  ]
)
