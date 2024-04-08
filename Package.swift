// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TMDbAPI",

    platforms: [
        .macOS(.v14)
    ],

    products: [
        .executable(name: "Status", targets: ["Status"])
    ],

    dependencies: [
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", from: "1.0.0-alpha")
    ],

    targets: [
        .executableTarget(
            name: "Status",
            dependencies: [
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime")
            ]
        ),
        .testTarget(
            name: "StatusTests",
            dependencies: [
                "Status",
                .product(name: "AWSLambdaTesting", package: "swift-aws-lambda-runtime")
            ]
        )
    ]
)
