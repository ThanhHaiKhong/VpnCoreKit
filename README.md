# VpnCoreKit

Swift wrapper for VPN Core native library. Provides a type-safe, async/await Swift API for VPN server operations.

## Features

- Type-safe Swift API with Codable models
- Async/await and synchronous APIs
- Automatic JWT token generation (30s TTL)
- Automatic AES-256-CBC decryption of API responses
- Memory-safe C interop with proper resource cleanup
- Comprehensive unit tests

## Requirements

- iOS 12.0+
- Swift 5.7+
- VpnCore XCFramework (built from vpn-core native library)

## Installation

### Swift Package Manager

Add VpnCoreKit as a local package dependency in your Xcode project:

1. File → Add Package Dependencies
2. Click "Add Local..."
3. Select the `mobile/iOS/VpnCoreKit` directory
4. Add to your target

### Building VpnCore XCFramework

Before using VpnCoreKit, you must build the native VpnCore XCFramework:

```bash
cd mobile/android/vpn-core

# Configure build settings (first time only)
cp ios-config.sh.example ios-config.sh
# Edit ios-config.sh with your API endpoint, JWT secret, etc.

# Build XCFramework
source ios-config.sh
./build-xcframework.sh
```

The XCFramework will be created at:
```
mobile/android/vpn-core/build-ios/VpnCore.xcframework
```

## Usage

### Import the framework

```swift
import VpnCoreKit
```

### Get server list

**Async/await** (recommended):

```swift
do {
    let servers = try await VpnAPI.shared.getServers()
    for server in servers {
        print("\(server.name) - \(server.countryCode)")
        print("Protocols: \(server.protocols.map { $0.displayName }.joined(separator: ", "))")
    }
} catch {
    print("Error: \(error)")
}
```

**Synchronous**:

```swift
if let servers = VpnAPI.shared.getServersSync() {
    for server in servers {
        print("\(server.name) - \(server.countryCode)")
    }
}
```

### Get server configuration

**Async/await** (recommended):

```swift
do {
    let config = try await VpnAPI.shared.getConfiguration(
        serverId: "server-123",
        protocol: .openvpn
    )

    switch config.vpnType {
    case .openvpn:
        print("OpenVPN Template:")
        print(config.template ?? "N/A")
        print("Username: \(config.username ?? "N/A")")
        print("Password: \(config.password ?? "N/A")")

    case .ikev2:
        print("IKEv2 Configuration:")
        print("Host: \(config.host ?? "N/A")")
        print("PSK: \(config.psk ?? "N/A")")
    }
} catch {
    print("Error: \(error)")
}
```

**Synchronous**:

```swift
if let config = VpnAPI.shared.getConfigurationSync(
    serverId: "server-123",
    protocol: .ikev2
) {
    print("Host: \(config.host ?? "N/A")")
}
```

## API Reference

### VpnAPI

High-level Swift API for VPN operations.

#### Methods

```swift
// Async methods
func getServers() async throws -> [ServerInfo]
func getConfiguration(serverId: String, protocol: VpnProtocol) async throws -> ServerConfiguration

// Sync methods
func getServersSync() -> [ServerInfo]?
func getConfigurationSync(serverId: String, protocol: VpnProtocol) -> ServerConfiguration?
```

### Models

#### VpnProtocol

```swift
public enum VpnProtocol: String, Codable {
    case openvpn = "openvpn"
    case ikev2 = "ikev2"

    var displayName: String // "OpenVPN" or "IKEv2"
}
```

#### ServerInfo

```swift
public struct ServerInfo: Codable, Identifiable {
    let id: String              // Unique server identifier
    let name: String            // Display name (e.g., "US Server")
    let countryCode: String     // ISO country code (e.g., "US")
    let protocols: [VpnProtocol] // Supported protocols
}
```

#### ServerConfiguration

```swift
public struct ServerConfiguration: Codable {
    let id: String?
    let name: String?
    let vpnType: VpnProtocol

    // OpenVPN fields
    let template: String?       // .ovpn file content
    let username: String?
    let password: String?

    // IKEv2 fields
    let host: String?
    let port: Int?
    let psk: String?           // Pre-shared key
    let config: String?        // Additional config
}
```

#### VpnAPIError

```swift
public enum VpnAPIError: Error, LocalizedError {
    case emptyResponse         // API returned null/empty
    case invalidJSON(String)   // JSON parsing failed
    case decodingFailed(Error) // Model decoding failed
    case networkError(String)  // Network/HTTP error
}
```

### VpnCoreWrapper

Low-level wrapper for C API. Use `VpnAPI` instead unless you need direct C API access.

```swift
public final class VpnCoreWrapper {
    static func getServerList() -> String?
    static func getServerConfiguration(serverId: String, protocol: String) -> String?
}
```

## Testing

Run unit tests:

```bash
cd mobile/iOS/VpnCoreKit
swift test
```

Tests include:
- Model encoding/decoding
- API error handling
- Server list retrieval
- Server configuration retrieval
- Synchronous API
- Performance benchmarks

**Note**: Integration tests require:
1. VpnCore XCFramework to be built
2. Valid API endpoint configured in `vpn-core/ios-config.sh`
3. Network connectivity to API

## Architecture

```
VpnCoreKit (Swift Package)
├── VpnAPI.swift              # High-level async/sync API
├── VpnCoreWrapper.swift      # C interop with memory management
├── Models.swift              # Swift types (ServerInfo, etc.)
└── Tests/
    └── VpnCoreKitTests.swift

VpnCore.xcframework (Native)
├── Headers/
│   └── vc_vpn_api.h         # C API: _L1sT_v3r_(), _G3t_C0nf_()
└── Libraries/
    └── libvpn_core.a        # Native library with JWT + crypto
```

## How it works

1. **VpnAPI** provides type-safe Swift interface
2. **VpnCoreWrapper** calls native C functions:
   - `_L1sT_v3r_()` - Get server list
   - `_G3t_C0nf_(server_id, protocol)` - Get server config
   - `_Fr33_Str_(ptr)` - Free C-allocated memory
3. **Native library** handles:
   - JWT token generation (HMAC-SHA256, 30s TTL)
   - HTTPS requests to API
   - AES-256-CBC response decryption
   - JSON response formatting
4. **VpnCoreWrapper** converts C strings to Swift and frees memory
5. **VpnAPI** decodes JSON to Swift models

## Build Configuration

VpnCore is configured at build time via `vpn-core/ios-config.sh`:

```bash
# API Configuration
export VPN_API_ENDPOINT="https://api.yourdomain.com"
export VPN_JWT_SECRET="your-jwt-secret-here"
export VPN_CLIENT_ID="your-client-id"

# Encryption Keys
export VPN_AES_KEY="your-256-bit-hex-key"
export VPN_AES_IV="your-128-bit-hex-iv"
```

Generate secure keys:

```bash
# JWT secret (base64)
openssl rand -base64 32

# AES-256 key (hex)
openssl rand -hex 32

# AES IV (hex)
openssl rand -hex 16
```

## Troubleshooting

### Tests fail with "dyld: Library not loaded"

Build the XCFramework first:
```bash
cd mobile/android/vpn-core
source ios-config.sh
./build-xcframework.sh
```

### Tests fail with "API returned empty response"

Check your `ios-config.sh` configuration:
1. Verify `VPN_API_ENDPOINT` is correct
2. Ensure API is accessible
3. Check network connectivity

### Invalid JSON errors

Verify API response format matches expected structure:
- Server list: Array of objects with `id`, `name`, `country_code`, `vpn_types`
- Server config: Object with `vpn_type` and protocol-specific fields

### Memory leaks

VpnCoreWrapper automatically frees C memory. If you use `VpnCoreWrapper` directly:
- Never call `_L1sT_v3r_()` or `_G3t_C0nf_()` directly
- Always use `VpnCoreWrapper.getServerList()` and `getServerConfiguration()`
- These methods handle `_Fr33_Str_()` cleanup automatically

## License

See main project LICENSE file.
