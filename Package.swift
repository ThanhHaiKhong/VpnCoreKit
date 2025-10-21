// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// IMPORTANT: The VpnCore.xcframework binary requires macOS 15.0+ at runtime
// due to its compile-time deployment target. The .v14 declaration here is
// the maximum supported by Swift 5.9 package tools.

import PackageDescription

let package = Package(
    name: "VpnCoreKit",
    platforms: [
        .iOS(.v15), .macOS(.v14)
    ],
    products: [
		.singleTargetLibrary("VpnCoreKit")
    ],
    dependencies: [
        
    ],
    targets: [
        .target(
            name: "VpnCoreObjC",
            dependencies: [
				"VpnCore"
			],
            path: "Sources/VpnCoreObjC",
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath("../../Frameworks/VpnCore.xcframework/ios-arm64/VpnCore-device.framework/Headers", .when(platforms: [.iOS])),
                .headerSearchPath("../../Frameworks/VpnCore.xcframework/macos-arm64/VpnCore.framework/Headers", .when(platforms: [.macOS]))
            ],
            linkerSettings: [
                .linkedLibrary("c++"),
                .linkedLibrary("ssl", .when(platforms: [.macOS])),
                .linkedLibrary("crypto", .when(platforms: [.macOS])),
                .unsafeFlags(["-L/opt/homebrew/opt/openssl@3/lib"], .when(platforms: [.macOS]))
            ]
        ),
        .target(
            name: "VpnCoreKit",
            dependencies: [
				"VpnCoreObjC"
			],
            path: "Sources/VpnCoreKit"
        ),
		.binaryTarget(
			name: "VpnCore",
			path: "Frameworks/VpnCore.xcframework"
		),
        .testTarget(
            name: "VpnCoreKitTests",
            dependencies: [
				"VpnCoreKit", 
				"VpnCoreObjC"
			],
            path: "Tests/VpnCoreKitTests"
        ),
    ]
)

extension Product {
	static func singleTargetLibrary(_ name: String) -> Product {
		.library(name: name, targets: [name])
	}
}
