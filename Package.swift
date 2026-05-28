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
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.7.0")
    ],
    targets: [
        .executableTarget(
            name: "ReadMate",
            dependencies: ["SwiftSoup"],
            path: "Sources/ReadMate"
        ),
        .testTarget(
            name: "ReadMateTests",
            dependencies: ["ReadMate", "SwiftSoup"],
            path: "Tests/ReadMateTests"
        )
    ]
)
