// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "LiquidGlassDemo",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "LiquidGlassDemo", targets: ["LiquidGlassDemo"])
    ],
    dependencies: [
        // Sparkle powers direct-download auto-updates (see RELEASE.md). It's only
        // active in a signed .app bundle with an SUFeedURL; `swift run` ignores it.
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0")
    ],
    targets: [
        .executableTarget(
            name: "LiquidGlassDemo",
            dependencies: [.product(name: "Sparkle", package: "Sparkle")],
            // String catalog for L10n (compiled into the resource bundle).
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "LiquidGlassDemoTests",
            dependencies: ["LiquidGlassDemo"]
        )
    ]
)
