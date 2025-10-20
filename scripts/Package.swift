// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "XcodeScripts",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/tuist/XcodeProj.git", from: "8.23.0")
    ],
    targets: [
        .executableTarget(
            name: "add-xcode-targets",
            dependencies: [
                .product(name: "XcodeProj", package: "XcodeProj")
            ],
            path: "add-xcode-targets"
        )
    ]
)
