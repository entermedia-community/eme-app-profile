// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .macOS("12.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "app_links", path: "../.packages/app_links-6.4.1"),
        .package(name: "file_picker_darwin", path: "../.packages/file_picker_darwin-2.4.0"),
        .package(name: "file_selector_macos", path: "../.packages/file_selector_macos-0.9.5+1"),
        .package(name: "firebase_analytics", path: "../.packages/firebase_analytics-12.6.1"),
        .package(name: "firebase_auth", path: "../.packages/firebase_auth-6.7.1"),
        .package(name: "firebase_core", path: "../.packages/firebase_core-4.15.2"),
        .package(name: "firebase_crashlytics", path: "../.packages/firebase_crashlytics-5.4.1"),
        .package(name: "firebase_messaging", path: "../.packages/firebase_messaging-16.7.1"),
        .package(name: "flutter_local_notifications", path: "../.packages/flutter_local_notifications-22.3.2"),
        .package(name: "flutter_secure_storage_darwin", path: "../.packages/flutter_secure_storage_darwin-0.4.3"),
        .package(name: "pdfium_flutter", path: "../.packages/pdfium_flutter-0.4.1"),
        .package(name: "quill_native_bridge_macos", path: "../.packages/quill_native_bridge_macos-0.0.1"),
        .package(name: "shared_preferences_foundation", path: "../.packages/shared_preferences_foundation-2.5.7"),
        .package(name: "sqflite_darwin", path: "../.packages/sqflite_darwin-2.4.4+1"),
        .package(name: "url_launcher_macos", path: "../.packages/url_launcher_macos-3.2.6"),
        .package(name: "video_player_avfoundation", path: "../.packages/video_player_avfoundation-2.12.3"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "app-links", package: "app_links"),
                .product(name: "file-picker-darwin", package: "file_picker_darwin"),
                .product(name: "file-selector-macos", package: "file_selector_macos"),
                .product(name: "firebase-analytics", package: "firebase_analytics"),
                .product(name: "firebase-auth", package: "firebase_auth"),
                .product(name: "firebase-core", package: "firebase_core"),
                .product(name: "firebase-crashlytics", package: "firebase_crashlytics"),
                .product(name: "firebase-messaging", package: "firebase_messaging"),
                .product(name: "flutter-local-notifications", package: "flutter_local_notifications"),
                .product(name: "flutter-secure-storage-darwin", package: "flutter_secure_storage_darwin"),
                .product(name: "pdfium-flutter", package: "pdfium_flutter"),
                .product(name: "quill-native-bridge-macos", package: "quill_native_bridge_macos"),
                .product(name: "shared-preferences-foundation", package: "shared_preferences_foundation"),
                .product(name: "sqflite-darwin", package: "sqflite_darwin"),
                .product(name: "url-launcher-macos", package: "url_launcher_macos"),
                .product(name: "video-player-avfoundation", package: "video_player_avfoundation"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
