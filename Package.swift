// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "LiquidGlassDemo",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "LiquidGlassDemo", targets: ["LiquidGlassDemo"])
    ],
    targets: [
        .executableTarget(
            name: "LiquidGlassDemo"
        ),
        .testTarget(
            name: "LiquidGlassDemoTests",
            dependencies: ["LiquidGlassDemo"]
        )
    ]
)
