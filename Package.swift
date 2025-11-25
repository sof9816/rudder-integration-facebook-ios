// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Rudder-Facebook",
    platforms: [
        .iOS(.v12),
    ],
    products: [
            .library(
                name: "Rudder-Facebook",
                targets: ["Rudder-Facebook"]
            )
    ],
    dependencies: [
      .package(name: "Rudder", url: "https://github.com/rudderlabs/rudder-sdk-ios.git", .exact("2.4.2")),
      .package(name: "Facebook", url: "https://github.com/facebook/facebook-ios-sdk.git", from: "14.0.0")
    ],
    targets: [
        .target(
            name: "Rudder-Facebook",
            dependencies: [
                "Rudder",
                .product(name: "FacebookCore", package: "Facebook")
            ],
            sources: [
              "ObjCFiles"
            ],
            publicHeadersPath: "ObjCFiles"
        )
    ]
)
