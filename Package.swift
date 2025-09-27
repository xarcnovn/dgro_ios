// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MCPiOSClient",
    platforms: [
        .iOS(.v16),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "MCPiOSClient",
            targets: ["MCPiOSClient"]),
    ],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/mcp-swift-sdk", from: "0.2.3"),
        .package(url: "https://github.com/jamesrochabrun/SwiftAnthropic", from: "2.1.3"),
    ],
    targets: [
        .target(
            name: "MCPiOSClient",
            dependencies: [
                .product(name: "SwiftAnthropic", package: "SwiftAnthropic"),
                .product(name: "MCP", package: "mcp-swift-sdk"),
            ]),
        .testTarget(
            name: "MCPiOSClientTests",
            dependencies: ["MCPiOSClient"]
        ),
    ]
)