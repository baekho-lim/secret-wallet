// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SecretWalletApp",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(path: ".."),
    ],
    targets: [
        .executableTarget(
            name: "SecretWalletApp",
            dependencies: [
                .product(name: "SecretWalletCore", package: "secret-wallet"),
            ],
            path: "SecretWalletApp",
            linkerSettings: [
                .linkedFramework("Security"),
                .linkedFramework("LocalAuthentication"),
            ]
        ),
    ]
)
