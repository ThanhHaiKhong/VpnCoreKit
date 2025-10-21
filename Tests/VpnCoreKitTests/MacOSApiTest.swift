import XCTest
@testable import VpnCoreKit
@testable import VpnCoreObjC

@available(macOS 15.0, iOS 15.0, *)
final class MacOSApiTest: XCTestCase {

    func testNativeCallDirectly() throws {
        print("Testing direct native call...")

        // Test if wrapper can call C function
        let result = VpnCoreWrapper.getServerList()

        if let jsonString = result {
            print("✅ Success! Received: \(jsonString.prefix(200))")
            XCTAssertNotNil(jsonString)
            XCTAssertFalse(jsonString.isEmpty)
        } else {
            print("❌ Failed: VpnCoreWrapper.getServerList() returned nil")
            print("This means the C function _L1sT_v3r_() returned NULL")

            // Log some diagnostic info
            print("\nDiagnostic Info:")
            print("- Running on: macOS")
            print("- Architecture: \(String(cString: uname().machine))")

            XCTFail("Native call returned null - C API not working on macOS")
        }
    }

    func testVpnAPIGetServers() async throws {
        print("Testing VpnAPI.getServers()...")

        let result = await VpnAPI.shared.getServers()

        switch result {
        case .success(let servers):
            print("✅ Success! Received \(servers.count) servers")
            XCTAssertFalse(servers.isEmpty)
        case .failure(let error):
            print("❌ Failed: \(error.localizedDescription)")
            XCTFail("VpnAPI.getServers() failed: \(error)")
        }
    }
}

// Helper to get machine architecture
private func uname() -> (machine: [CChar], sysname: [CChar]) {
    var systemInfo = utsname()
    Darwin.uname(&systemInfo)

    return (
        machine: withUnsafeBytes(of: &systemInfo.machine) { Array($0.bindMemory(to: CChar.self)) },
        sysname: withUnsafeBytes(of: &systemInfo.sysname) { Array($0.bindMemory(to: CChar.self)) }
    )
}
