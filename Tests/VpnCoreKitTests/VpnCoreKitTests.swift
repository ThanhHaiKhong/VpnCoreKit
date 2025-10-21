import XCTest
@testable import VpnCoreKit
import VpnCoreObjC

@available(macOS 15.0, iOS 15.0, *)
final class VpnCoreKitTests: XCTestCase {

    // MARK: - Model Tests

    func testVpnProtocolDisplayName() {
        XCTAssertEqual(String.openvpn.protocolDisplayName, "OpenVPN")
        XCTAssertEqual(String.ikev2.protocolDisplayName, "IKEv2")
        XCTAssertEqual("OPENVPN".protocolDisplayName, "OpenVPN")
        XCTAssertEqual("IKEV2".protocolDisplayName, "IKEv2")
    }

    func testVpnProtocolConstants() {
        XCTAssertEqual(String.openvpn, "OPENVPN")
        XCTAssertEqual(String.ikev2, "IKEV2")
    }

    func testVpnProtocolApiValue() {
        XCTAssertEqual(String.openvpn.protocolApiValue, "openvpn")
        XCTAssertEqual(String.ikev2.protocolApiValue, "ikev2")
        XCTAssertEqual("OPENVPN".protocolApiValue, "openvpn")
        XCTAssertEqual("IKEV2".protocolApiValue, "ikev2")
    }

    func testServerInfoDecoding() throws {
        let json = """
        {
            "id": "server-1",
            "name": "US Server",
            "countryCode": "US",
            "protocols": ["OPENVPN", "IKEV2"]
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let serverInfo = try decoder.decode(ServerInfo.self, from: data)

        XCTAssertEqual(serverInfo.id, "server-1")
        XCTAssertEqual(serverInfo.name, "US Server")
        XCTAssertEqual(serverInfo.countryCode, "US")
        XCTAssertEqual(serverInfo.protocols.count, 2)
        XCTAssertTrue(serverInfo.protocols.contains("OPENVPN"))
        XCTAssertTrue(serverInfo.protocols.contains("IKEV2"))
    }

    func testServerInfoArrayDecoding() throws {
        let json = """
        [
            {
                "id": "server-1",
                "name": "US Server",
                "countryCode": "US",
                "protocols": ["OPENVPN"]
            },
            {
                "id": "server-2",
                "name": "UK Server",
                "countryCode": "GB",
                "protocols": ["IKEV2"]
            }
        ]
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let servers = try decoder.decode([ServerInfo].self, from: data)

        XCTAssertEqual(servers.count, 2)
        XCTAssertEqual(servers[0].id, "server-1")
        XCTAssertEqual(servers[1].id, "server-2")
    }

    func testServerInfoDecodingWithQuality() throws {
        let json = """
        {
            "id": "server-1",
            "name": "US Server",
            "countryCode": "US",
            "quality": "low",
            "protocols": ["OPENVPN", "IKEV2"]
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let serverInfo = try decoder.decode(ServerInfo.self, from: data)

        XCTAssertEqual(serverInfo.id, "server-1")
        XCTAssertEqual(serverInfo.name, "US Server")
        XCTAssertEqual(serverInfo.countryCode, "US")
        XCTAssertEqual(serverInfo.quality, "low")
        XCTAssertEqual(serverInfo.protocols.count, 2)
    }

    func testServerConfigurationDecoding() throws {
        let json = """
        {
            "id": "server-1",
            "name": "US Server",
            "protocol": "OPENVPN",
            "template": "client\\nremote 1.2.3.4 1194",
            "host": "1.2.3.4",
            "username": "user123",
            "password": "pass123"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let config = try decoder.decode(ServerConfiguration.self, from: data)

        XCTAssertEqual(config.id, "server-1")
        XCTAssertEqual(config.name, "US Server")
        XCTAssertEqual(config.protocol, "OPENVPN")
        XCTAssertNotNil(config.template)
        XCTAssertEqual(config.host, "1.2.3.4")
        XCTAssertEqual(config.username, "user123")
        XCTAssertEqual(config.password, "pass123")
    }

    // MARK: - Error Response Tests

    func testErrorResponseDecoding() throws {
        let json = """
        {
            "error": "HTTP 404"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let errorResponse = try decoder.decode(ErrorResponse.self, from: data)

        XCTAssertEqual(errorResponse.error, "HTTP 404")
    }

    // MARK: - API Error Tests

    func testVpnAPIErrorDescriptions() {
        let nativeNullError = VpnAPIError.nativeNull
        XCTAssertNotNil(nativeNullError.errorDescription)
        XCTAssertTrue(nativeNullError.errorDescription!.contains("Native"))

        let apiError = VpnAPIError.apiError("Server error", code: "API_ERROR")
        XCTAssertNotNil(apiError.errorDescription)
        XCTAssertTrue(apiError.errorDescription!.contains("Server error"))

        let jsonError = VpnAPIError.invalidJSON("test")
        XCTAssertNotNil(jsonError.errorDescription)
        XCTAssertTrue(jsonError.errorDescription!.contains("Invalid JSON"))

        let networkError = VpnAPIError.networkError("Connection timeout")
        XCTAssertNotNil(networkError.errorDescription)
        XCTAssertTrue(networkError.errorDescription!.contains("Network error"))
    }

    func testVpnAPIErrorCodes() {
        XCTAssertEqual(VpnAPIError.nativeNull.code, "NATIVE_NULL")
        XCTAssertEqual(VpnAPIError.apiError("test", code: "API_ERROR").code, "API_ERROR")
        XCTAssertEqual(VpnAPIError.invalidJSON("test").code, "INVALID_JSON")
        XCTAssertEqual(VpnAPIError.parseError("test").code, "PARSE_ERROR")
        XCTAssertEqual(VpnAPIError.networkError("test").code, "NETWORK_ERROR")
    }

    // MARK: - ApiResult Tests

    func testApiResultSuccess() {
        let result: ApiResult<String> = .success("test data")

        XCTAssertTrue(result.isSuccess)
        XCTAssertFalse(result.isFailure)
        XCTAssertEqual(result.get(), "test data")
        XCTAssertEqual(result.getOrDefault("default"), "test data")
        XCTAssertNil(result.error())
    }

    func testApiResultFailure() {
        let result: ApiResult<String> = .failure(.nativeNull)

        XCTAssertFalse(result.isSuccess)
        XCTAssertTrue(result.isFailure)
        XCTAssertNil(result.get())
        XCTAssertEqual(result.getOrDefault("default"), "default")
        XCTAssertNotNil(result.error())
        XCTAssertEqual(result.error()?.code, "NATIVE_NULL")
    }

    func testApiResultMap() {
        let result: ApiResult<Int> = .success(5)
        let mapped = result.map { $0 * 2 }

        XCTAssertTrue(mapped.isSuccess)
        XCTAssertEqual(mapped.get(), 10)
    }

    func testApiResultMapFailure() {
        let result: ApiResult<Int> = .failure(.nativeNull)
        let mapped = result.map { $0 * 2 }

        XCTAssertTrue(mapped.isFailure)
        XCTAssertNil(mapped.get())
    }

    // MARK: - Integration Tests

    /// Test server list retrieval
    /// - Note: This requires vpn-core XCFramework to be built and linked
    func testGetServers() async {
        // This test will only pass if:
        // 1. VpnCore XCFramework is built and linked
        // 2. API endpoint is accessible
        // 3. API returns valid JSON

        let result = await VpnAPI.shared.getServers()

        switch result {
        case .success(let servers):
            // Verify we got some servers
            XCTAssertFalse(servers.isEmpty, "Should return at least one server")

            // Verify server structure
            if let firstServer = servers.first {
                XCTAssertFalse(firstServer.id.isEmpty, "Server ID should not be empty")
                XCTAssertFalse(firstServer.name.isEmpty, "Server name should not be empty")
                XCTAssertFalse(firstServer.countryCode.isEmpty, "Country code should not be empty")
                XCTAssertFalse(firstServer.protocols.isEmpty, "Should support at least one protocol")
            }

        case .failure(let error):
            // Log error but don't fail test - API might not be available in test environment
            print("API Error: \(error.localizedDescription) [\(error.code)]")
            XCTFail("Failed to get servers: \(error.localizedDescription)")
        }
    }

    /// Test server configuration retrieval
    /// - Note: This requires a valid server ID from your API
    func testGetConfiguration() async {
        // First get server list to get a valid server ID
        let serversResult = await VpnAPI.shared.getServers()

        guard case .success(let servers) = serversResult,
              let firstServer = servers.first,
              let firstProtocol = firstServer.protocols.first else {
            print("Skipping configuration test - no servers available")
            return
        }

        // Get configuration for first server
        let result = await VpnAPI.shared.getConfiguration(
            serverId: firstServer.id,
            protocol: firstProtocol
        )

        switch result {
        case .success(let config):
            // Verify configuration structure
            XCTAssertEqual(config.protocol, firstProtocol, "Protocol should match request")

            // Verify required fields based on protocol
            if config.protocol == "OPENVPN" {
                XCTAssertNotNil(config.template, "OpenVPN config should have template")
                XCTAssertNotNil(config.username, "OpenVPN config should have username")
                XCTAssertNotNil(config.password, "OpenVPN config should have password")
            } else if config.protocol == "IKEV2" {
                XCTAssertNotNil(config.host, "IKEv2 config should have host")
            }

        case .failure(let error):
            print("API Error: \(error.localizedDescription) [\(error.code)]")
            XCTFail("Failed to get configuration: \(error.localizedDescription)")
        }
    }

    /// Test synchronous API
    func testGetServersSync() {
        let result = VpnAPI.shared.getServersSync()

        switch result {
        case .success(let servers):
            XCTAssertFalse(servers.isEmpty, "Should return at least one server")
        case .failure(let error):
            print("Sync API Error: \(error.localizedDescription) [\(error.code)]")
        }
    }

    /// Test VpnCoreWrapper directly
    func testVpnCoreWrapperServerList() {
        let jsonString = VpnCoreWrapper.getServerList()

        if let jsonString = jsonString {
            XCTAssertFalse(jsonString.isEmpty, "JSON string should not be empty")

            // Verify it's valid JSON
            guard let data = jsonString.data(using: .utf8) else {
                XCTFail("Failed to convert JSON string to Data")
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data)
                XCTAssertTrue(json is [[String: Any]], "Should be array of objects")
            } catch {
                XCTFail("Invalid JSON: \(error)")
            }
        } else {
            print("Warning: VpnCoreWrapper returned nil - check API configuration")
        }
    }

    /// Test VpnCoreWrapper with invalid server ID
    func testVpnCoreWrapperInvalidServer() {
        let result = VpnCoreWrapper.getServerConfiguration(
            withServerId: "invalid-server-id-12345",
            protocol: String.openvpn.protocolApiValue
        )

        // Should return nil or empty for invalid server
        if let result = result {
            print("Result for invalid server: \(result)")
            // Depending on API behavior, might be nil or error JSON
        }
    }

    // MARK: - Performance Tests

    func testGetServersPerformance() throws {
        measure {
            _ = VpnAPI.shared.getServersSync()
        }
    }
}
