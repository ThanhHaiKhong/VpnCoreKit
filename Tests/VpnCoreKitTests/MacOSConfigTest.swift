import XCTest
@testable import VpnCoreKit
@testable import VpnCoreObjC

@available(macOS 15.0, iOS 15.0, *)
final class MacOSConfigTest: XCTestCase {

    func testGetConfigurationOpenVPN() async throws {
        print("\n=== Testing getConfiguration(OpenVPN) ===")

        // First get a server ID
        let serversResult = await VpnAPI.shared.getServers()
        guard case .success(let servers) = serversResult, !servers.isEmpty else {
            XCTFail("Failed to get servers")
            return
        }

        // Find a server that supports OpenVPN
        guard let server = servers.first(where: { $0.protocols.contains(.openvpn) }) else {
            XCTFail("No OpenVPN servers available")
            return
        }

        print("Testing with server: \(server.name) (\(server.id))")

        // Get configuration
        let configResult = await VpnAPI.shared.getConfiguration(
            serverId: server.id,
            protocol: .openvpn
        )

        switch configResult {
        case .success(let config):
            print("✅ SUCCESS: Got OpenVPN configuration")
            print("Server: \(config.name ?? "N/A")")
            print("Host: \(config.host ?? "N/A")")
            print("Has template: \(config.template != nil)")
            print("Has username: \(config.username != nil)")
            print("Has password: \(config.password != nil)")

            XCTAssertNotNil(config.id)
            XCTAssertNotNil(config.name)
            XCTAssertEqual(config.protocol, .openvpn)

        case .failure(let error):
            print("❌ FAILED: \(error.localizedDescription)")
            XCTFail("getConfiguration failed: \(error)")
        }
    }

    func testGetConfigurationIKEv2() async throws {
        print("\n=== Testing getConfiguration(IKEv2) ===")

        // First get a server ID
        let serversResult = await VpnAPI.shared.getServers()
        guard case .success(let servers) = serversResult, !servers.isEmpty else {
            XCTFail("Failed to get servers")
            return
        }

        // Find a server that supports IKEv2
        guard let server = servers.first(where: { $0.protocols.contains(.ikev2) }) else {
            XCTFail("No IKEv2 servers available")
            return
        }

        print("Testing with server: \(server.name) (\(server.id))")

        // Get configuration
        let configResult = await VpnAPI.shared.getConfiguration(
            serverId: server.id,
            protocol: .ikev2
        )

        switch configResult {
        case .success(let config):
            print("✅ SUCCESS: Got IKEv2 configuration")
            print("Server: \(config.name ?? "N/A")")
            print("Host: \(config.host ?? "N/A")")
            print("Has username: \(config.username != nil)")
            print("Has password: \(config.password != nil)")

            XCTAssertNotNil(config.id)
            XCTAssertNotNil(config.name)
            XCTAssertEqual(config.protocol, .ikev2)

        case .failure(let error):
            print("❌ FAILED: \(error.localizedDescription)")
            XCTFail("getConfiguration failed: \(error)")
        }
    }

    func testServerListStructure() async throws {
        print("\n=== Testing Server List Structure ===")

        let result = await VpnAPI.shared.getServers()

        guard case .success(let servers) = result else {
            XCTFail("Failed to get servers")
            return
        }

        print("Total servers: \(servers.count)")

        // Analyze servers
        let openvpnCount = servers.filter { $0.protocols.contains(.openvpn) }.count
        let ikev2Count = servers.filter { $0.protocols.contains(.ikev2) }.count
        let countries = Set(servers.map { $0.countryCode }).count

        print("OpenVPN servers: \(openvpnCount)")
        print("IKEv2 servers: \(ikev2Count)")
        print("Countries: \(countries)")

        // Sample servers
        if servers.count >= 3 {
            print("\nSample servers:")
            for server in servers.prefix(3) {
                print("  - \(server.name) (\(server.countryCode)): \(server.protocols.joined(separator: ", "))")
            }
        }

        XCTAssertGreaterThan(servers.count, 0, "Should have at least one server")
        XCTAssertGreaterThan(openvpnCount, 0, "Should have OpenVPN servers")
        XCTAssertGreaterThan(ikev2Count, 0, "Should have IKEv2 servers")
    }
}
