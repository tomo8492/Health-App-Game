// swift-tools-version: 5.9
// VitaCityCore: ドメインロジックの独立 Swift Package
// isowords パターン: コアロジックをモジュール分離し、CI で高速テストを実現
// nalexn パターン: ビジネスロジックはフレームワーク依存ゼロの純粋 Swift

import PackageDescription

let package = Package(
    name: "VitaCityCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),  // CI（macOS Runner）でもテスト可能にする
    ],
    products: [
        .library(
            name: "VitaCityCore",
            targets: ["VitaCityCore"]
        ),
    ],
    targets: [
        // ─────────────────────────────────────────────
        // VitaCityCore: ビジネスロジック（外部依存ゼロ）
        //   - CPPointCalculator（CP計算・純粋関数）
        //   - StreakManager（連続記録管理）
        //   - Domain value types
        // ─────────────────────────────────────────────
        .target(
            name: "VitaCityCore",
            path: "Sources/VitaCityCore",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        // ─────────────────────────────────────────────
        // テストターゲット（Swift Testing フレームワーク使用）
        // ─────────────────────────────────────────────
        .testTarget(
            name: "VitaCityCoreTests",
            dependencies: ["VitaCityCore"],
            path: "Tests/VitaCityCoreTests"
        ),
    ]
)
