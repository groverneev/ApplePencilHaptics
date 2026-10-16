// swift-tools-version: 5.9

// Swift Playgrounds app package. Open this folder (PencilHaptics.swiftpm)
// in Swift Playgrounds on iPad, or in Xcode on a Mac.

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "Pencil Haptics",
    platforms: [
        .iOS("17.5")
    ],
    products: [
        .iOSApplication(
            name: "Pencil Haptics",
            targets: ["AppModule"],
            bundleIdentifier: "com.applepencilhaptics.PencilHaptics",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .pencil),
            accentColor: .presetColor(.indigo),
            supportedDeviceFamilies: [
                .pad
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "."
        )
    ]
)
