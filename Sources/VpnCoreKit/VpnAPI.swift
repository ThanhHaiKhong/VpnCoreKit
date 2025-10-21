import Foundation
import VpnCoreObjC

/// High-level Swift API for VPN operations
///
/// This class provides a type-safe Swift interface to the VPN Core library.
/// All API calls automatically handle:
/// - JWT token generation (30s TTL, auto-refreshed)
/// - HTTPS communication
/// - Response decryption (AES-256-CBC)
/// - JSON parsing
@available(iOS 15.0, macOS 15.0, *)
public final class VpnAPI {

    // MARK: - Properties

    private let decoder: JSONDecoder

    // MARK: - Initialization

    /// Shared instance
    public static let shared = VpnAPI()

    private init() {
        decoder = JSONDecoder()
        // API returns camelCase JSON, no conversion needed
    }

    // MARK: - Public API

    /// Get list of available VPN servers
    ///
    /// - Returns: ApiResult with array of server information or error
    ///
    /// Example:
    /// ```swift
    /// let result = await VpnAPI.shared.getServers()
    /// switch result {
    /// case .success(let servers):
    ///     for server in servers {
    ///         print("\(server.name) - \(server.countryCode)")
    ///     }
    /// case .failure(let error):
    ///     print("Error: \(error.localizedDescription)")
    /// }
    /// ```
    @available(iOS 15.0, macOS 15.0, *)
    public func getServers() async -> ApiResult<[ServerInfo]> {
        guard let jsonString = VpnCoreWrapper.getServerList() else {
            return .failure(.nativeNull)
        }

        // Check if response is an error
        if jsonString.contains("\"error\"") {
            if let jsonData = jsonString.data(using: .utf8),
               let errorResponse = try? decoder.decode(ErrorResponse.self, from: jsonData) {
                return .failure(.apiError(errorResponse.error, code: "API_ERROR"))
            }
        }

        guard let jsonData = jsonString.data(using: .utf8) else {
            return .failure(.invalidJSON("Failed to convert response to Data"))
        }

        do {
            let servers = try decoder.decode([ServerInfo].self, from: jsonData)
            return .success(servers)
        } catch {
            return .failure(.decodingFailed(error))
        }
    }

    /// Get server configuration by ID and protocol
    ///
    /// - Parameters:
    ///   - serverId: Server identifier from server list
    ///   - protocol: VPN protocol to use
    /// - Returns: ApiResult with server configuration or error
    ///
    /// Example:
    /// ```swift
    /// let result = await VpnAPI.shared.getConfiguration(
    ///     serverId: "server-1",
    ///     protocol: .openvpn
    /// )
    /// switch result {
    /// case .success(let config):
    ///     print("Host: \(config.host ?? "N/A")")
    ///     print("Username: \(config.username ?? "N/A")")
    /// case .failure(let error):
    ///     print("Error: \(error.localizedDescription)")
    /// }
    /// ```
    @available(iOS 15.0, macOS 15.0, *)
    public func getConfiguration(serverId: String, protocol: VpnProtocol) async -> ApiResult<ServerConfiguration> {
        VpnCoreLog.info("getConfiguration: \(serverId) (\(`protocol`))")

        guard let jsonString = VpnCoreWrapper.getServerConfiguration(
            withServerId: serverId,
            protocol: `protocol`
        ) else {
            VpnCoreLog.error("VpnCoreWrapper returned nil")
            return .failure(.nativeNull)
        }

        VpnCoreLog.debug("Response: \(jsonString.count) chars")

        // Check if response is an error
        if jsonString.contains("\"error\"") {
            if let jsonData = jsonString.data(using: .utf8),
               let errorResponse = try? decoder.decode(ErrorResponse.self, from: jsonData) {
                VpnCoreLog.error("API error: \(errorResponse.error)")
                return .failure(.apiError(errorResponse.error, code: "API_ERROR"))
            }
        }

        guard let jsonData = jsonString.data(using: .utf8) else {
            VpnCoreLog.error("Failed to convert response to Data")
            return .failure(.invalidJSON("Failed to convert response to Data"))
        }

        do {
            let config = try decoder.decode(ServerConfiguration.self, from: jsonData)
            VpnCoreLog.info("ServerConfiguration decoded successfully")
            return .success(config)
        } catch {
            VpnCoreLog.error("Decoding failed: \(error.localizedDescription)")
            VpnCoreLog.debug("Full response: \(jsonString)")
            return .failure(.decodingFailed(error))
        }
    }

    // MARK: - Synchronous API (for backward compatibility)

    /// Get list of available VPN servers (synchronous)
    ///
    /// - Returns: ApiResult with array of server information or error
    /// - Note: Prefer async version when possible
    public func getServersSync() -> ApiResult<[ServerInfo]> {
        guard let jsonString = VpnCoreWrapper.getServerList() else {
            return .failure(.nativeNull)
        }

        // Check if response is an error
        if jsonString.contains("\"error\"") {
            if let jsonData = jsonString.data(using: .utf8),
               let errorResponse = try? decoder.decode(ErrorResponse.self, from: jsonData) {
                return .failure(.apiError(errorResponse.error, code: "API_ERROR"))
            }
        }

        guard let jsonData = jsonString.data(using: .utf8) else {
            return .failure(.invalidJSON("Failed to convert response to Data"))
        }

        do {
            let servers = try decoder.decode([ServerInfo].self, from: jsonData)
            return .success(servers)
        } catch {
            return .failure(.decodingFailed(error))
        }
    }

    /// Get server configuration (synchronous)
    ///
    /// - Parameters:
    ///   - serverId: Server identifier
    ///   - protocol: VPN protocol
    /// - Returns: ApiResult with server configuration or error
    /// - Note: Prefer async version when possible
    public func getConfigurationSync(serverId: String, protocol: VpnProtocol) -> ApiResult<ServerConfiguration> {
        guard let jsonString = VpnCoreWrapper.getServerConfiguration(
            withServerId: serverId,
            protocol: `protocol`
        ) else {
            return .failure(.nativeNull)
        }

        // Check if response is an error
        if jsonString.contains("\"error\"") {
            if let jsonData = jsonString.data(using: .utf8),
               let errorResponse = try? decoder.decode(ErrorResponse.self, from: jsonData) {
                return .failure(.apiError(errorResponse.error, code: "API_ERROR"))
            }
        }

        guard let jsonData = jsonString.data(using: .utf8) else {
            return .failure(.invalidJSON("Failed to convert response to Data"))
        }

        do {
            let config = try decoder.decode(ServerConfiguration.self, from: jsonData)
            return .success(config)
        } catch {
            return .failure(.decodingFailed(error))
        }
    }
}
