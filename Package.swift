// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ReadMate",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "ReadMate", targets: ["ReadMate"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "ReadMate",
            dependencies: [],
            path: "Sources/ReadMate"
        )
    ]
)
