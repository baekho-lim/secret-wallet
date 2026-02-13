// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "secret-wallet",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(name: "SecretWalletCore", targets: ["SecretWalletCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", "1.3.0"..<"1.6.0"),
    ],
    targets: [
        .target(
            name: "SecretWalletCore",
            path: "Sources/SecretWalletCore",
            linkerSettings: [
                .linkedFramework("Security"),
                .linkedFramework("LocalAuthentication"),
            ]
        ),
        .executableTarget(
            name: "secret-wallet",
            dependencies: [
                "SecretWalletCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/secret-wallet"
        ),
    ]
)
