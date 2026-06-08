// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Tmac",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(path: "../SwiftTerm"),
    ],
    targets: [
        .executableTarget(
            name: "Tmac",
            dependencies: [
                .product(name: "SwiftTerm", package: "SwiftTerm"),
            ],
            path: "Sources/Tmac"
        ),
    ]
)
