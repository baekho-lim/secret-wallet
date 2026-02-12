// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SecretWalletApp",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "SecretWalletApp",
            path: "SecretWalletApp",
            linkerSettings: [
                .linkedFramework("Security"),
                .linkedFramework("LocalAuthentication"),
            ]
        ),
    ]
)
