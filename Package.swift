// swift-tools-version: 6.0
// Experimental: for React Native's Swift Package Manager mode (React Native 0.87 or later), which
// React Native itself marks as not for production. CocoaPods apps do not use this file.
//
// The ReactNative and React-GeneratedCode packages are the local packages React Native's autolinker
// generates for each app, at these paths relative to this package, the same layout other React
// Native libraries use. Revisit them when React Native publishes a remote Swift package.

import PackageDescription

let package = Package(
    name: "ReactNativeMparticle",
    // React Native's autolinker requires iOS 15; the mParticle SDK declares the same.
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "ReactNativeMparticle", targets: ["ReactNativeMparticle"]),
    ],
    dependencies: [
        .package(name: "ReactNative", path: "../../../../xcframeworks"),
        .package(name: "React-GeneratedCode", path: "../../../ios"),
        // Same URLs as the mParticle kits use, so SwiftPM unifies them into one package identity.
        .package(url: "https://github.com/mParticle/mparticle-apple-sdk", "9.2.2"..<"10.0.0"),
        .package(url: "https://github.com/ROKT/rokt-contracts-apple.git", "2.0.0"..<"3.0.0"),
    ],
    targets: [
        // A separate target: SwiftPM cannot mix Swift and Objective-C++ in one target.
        .target(
            name: "RNMParticleSwift",
            dependencies: [.product(name: "RoktContracts", package: "rokt-contracts-apple")],
            path: "ios/RNMParticle/Swift"
        ),
        .target(
            name: "ReactNativeMparticle",
            dependencies: [
                "RNMParticleSwift",
                .product(name: "ReactHeaders", package: "ReactNative"),
                .product(name: "ReactNativeHeaders", package: "ReactNative"),
                .product(name: "ReactNativeDependenciesHeaders", package: "ReactNative"),
                .product(name: "ReactAppHeaders", package: "React-GeneratedCode"),
                .product(name: "mParticle-Apple-SDK", package: "mparticle-apple-sdk"),
                .product(name: "RoktContracts", package: "rokt-contracts-apple"),
            ],
            path: ".",
            sources: [
                "ios/RNMParticle/RNMPRokt.h",
                "ios/RNMParticle/RNMPRokt.mm",
                "ios/RNMParticle/RNMPRoktSwift.h",
                "ios/RNMParticle/RNMPSDKImports.h",
                "ios/RNMParticle/RNMParticle.h",
                "ios/RNMParticle/RNMParticle.mm",
                "ios/RNMParticle/RoktEventManager.h",
                "ios/RNMParticle/RoktEventManager.mm",
                "ios/RNMParticle/RoktLayoutManager.m",
                "ios/RNMParticle/RoktNativeLayoutComponentView.h",
                "ios/RNMParticle/RoktNativeLayoutComponentView.mm",
                "ios/RNMParticle/RoktPlaceholderRegistry.h",
                "ios/RNMParticle/RoktPlaceholderRegistry.m",
            ],
            publicHeadersPath: "ios",
            // Without RCT_NEW_ARCH_ENABLED the TurboModule and Fabric code compiles out, and the app
            // crashes looking up the RoktNativeLayout component.
            cSettings: [.define("RCT_NEW_ARCH_ENABLED", to: "1"), .headerSearchPath("ios/RNMParticle")],
            cxxSettings: [
                .define("RCT_NEW_ARCH_ENABLED", to: "1"),
                .headerSearchPath("ios/RNMParticle"),
                .define("DEBUG", .when(configuration: .debug)),
                .define("NDEBUG", .when(configuration: .release)),
            ],
            linkerSettings: [.linkedFramework("UIKit"), .linkedFramework("Foundation"), .linkedFramework("CoreGraphics")]
        ),
    ],
    cxxLanguageStandard: .cxx20
)
