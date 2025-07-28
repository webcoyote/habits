// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Habitual",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "Habitual",
            targets: ["Habitual"])
    ],
    dependencies: [
        .package(url: "https://github.com/PostHog/posthog-ios", exact: "3.29.0"),
        .package(url: "https://github.com/amplitude/Amplitude-Swift", exact: "1.13.9"),
        .package(url: "https://github.com/mixpanel/mixpanel-swift", exact: "2.10.4"),
        .package(url: "https://github.com/rollbar/rollbar-apple", exact: "3.3.3")
    ],
    targets: [
        .target(
            name: "Habitual",
            dependencies: [
                .product(name: "PostHog", package: "posthog-ios"),
                .product(name: "AmplitudeSwift", package: "Amplitude-Swift"),
                .product(name: "Mixpanel", package: "mixpanel-swift"),
                .product(name: "RollbarNotifier", package: "rollbar-apple")
            ]
        )
    ]
)
