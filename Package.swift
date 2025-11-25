// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Rudder-Facebook",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "Rudder-Facebook",
            targets: ["Rudder-Facebook"]),
    ],
    dependencies: [
        .package(name: "Rudder", url: "https://github.com/rudderlabs/rudder-sdk-ios.git", from: "1.12.0"),
        .package(name: "Facebook", url: "https://github.com/facebook/facebook-ios-sdk.git", from: "17.0.2")
    ],
    targets: [
        .target(
            name: "Rudder-Facebook",
            dependencies: [
                .product(name: "Rudder", package: "Rudder"),
                .product(name: "FacebookCore", package: "Facebook")
            ],
            path: "Rudder-Facebook/Classes",
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath(".")
            ]
        )
    ]
)
