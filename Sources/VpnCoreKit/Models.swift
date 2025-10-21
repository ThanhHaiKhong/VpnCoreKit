import Foundation

// MARK: - VPN Protocol

/// VPN Protocol type alias for flexibility
public typealias VpnProtocol = String

/// Common VPN protocol constants
public extension String {
    static let openvpn = "OPENVPN"
    static let ikev2 = "IKEV2"

    /// Get display name for protocol
    var protocolDisplayName: String {
        switch self.uppercased() {
        case "OPENVPN": return "OpenVPN"
        case "IKEV2": return "IKEv2"
        default: return self
        }
    }

    /// Get lowercase API value for protocol
    var protocolApiValue: String {
        return self.lowercased()
    }
}

// MARK: - Server Info

/// VPN Server information from server list
public struct ServerInfo: Codable, Equatable, Identifiable {
    /// Unique server identifier
    public let id: String

    /// Server display name
    public let name: String

    /// ISO country code (e.g., "US", "GB", "JP")
    public let countryCode: String

    /// Server quality (e.g., "low", "medium", "high")
    public let quality: String

    /// List of supported VPN protocols (uppercase strings like "OPENVPN", "IKEV2")
    public let protocols: [VpnProtocol]

    /// Coding keys for JSON mapping
    /// Supports both camelCase and snake_case for backward compatibility
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case countryCode
        case countryCodeSnake = "country_code"
        case quality
        case protocols
    }

    public init(id: String, name: String, countryCode: String, quality: String = "", protocols: [VpnProtocol]) {
        self.id = id
        self.name = name
        self.countryCode = countryCode
        self.quality = quality
        self.protocols = protocols
    }

    // Custom decoder to support both countryCode and country_code
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)

        // Try camelCase first, fall back to snake_case
        if let cc = try? container.decode(String.self, forKey: .countryCode) {
            countryCode = cc
        } else {
            countryCode = try container.decode(String.self, forKey: .countryCodeSnake)
        }

        quality = try container.decodeIfPresent(String.self, forKey: .quality) ?? ""
        protocols = try container.decode([VpnProtocol].self, forKey: .protocols)
    }

    // Custom encoder - always encode as camelCase
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(countryCode, forKey: .countryCode)
        try container.encode(quality, forKey: .quality)
        try container.encode(protocols, forKey: .protocols)
    }
}

// MARK: - Server Configuration

/// VPN Server configuration with credentials
public struct ServerConfiguration: Codable, Equatable {
    /// Server identifier
    public let id: String

    /// Server name
    public let name: String

    /// VPN protocol (uppercase string like "OPENVPN", "IKEV2")
    public let `protocol`: VpnProtocol

    /// Configuration template (e.g., .ovpn file content for OpenVPN)
    public let template: String?

    /// Server host/IP
    public let host: String

    /// Username for authentication
    public let username: String

    /// Password for authentication
    public let password: String

    public init(
        id: String,
        name: String,
        `protocol`: VpnProtocol,
        template: String? = nil,
        host: String,
        username: String,
        password: String
    ) {
        self.id = id
        self.name = name
        self.protocol = `protocol`
        self.template = template
        self.host = host
        self.username = username
        self.password = password
    }
}

// MARK: - Error Response

/// Error response from native vpn-core
/// Format: {"error": "error message"}
public struct ErrorResponse: Codable {
    public let error: String
}

// MARK: - VPN API Error

/// Errors that can occur when using VPN API
public enum VpnAPIError: Error, LocalizedError {
    /// Native call returned null
    case nativeNull

    /// API returned error response
    case apiError(String, code: String?)

    /// Invalid JSON received from API
    case invalidJSON(String)

    /// Decoding failed
    case decodingFailed(Error)

    /// Parse error
    case parseError(String)

    /// Network/HTTP error
    case networkError(String)

    public var errorDescription: String? {
        switch self {
        case .nativeNull:
            return "Native call returned null"
        case .apiError(let message, let code):
            if let code = code {
                return "API error [\(code)]: \(message)"
            }
            return "API error: \(message)"
        case .invalidJSON(let message):
            return "Invalid JSON: \(message)"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .parseError(let message):
            return "Parse error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }

    /// Error code for programmatic handling
    public var code: String {
        switch self {
        case .nativeNull: return "NATIVE_NULL"
        case .apiError(_, let code): return code ?? "API_ERROR"
        case .invalidJSON: return "INVALID_JSON"
        case .decodingFailed: return "DECODE_ERROR"
        case .parseError: return "PARSE_ERROR"
        case .networkError: return "NETWORK_ERROR"
        }
    }
}
