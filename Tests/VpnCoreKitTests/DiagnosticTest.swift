import XCTest
@testable import VpnCoreKit
@testable import VpnCoreObjC
import Foundation

@available(macOS 15.0, iOS 15.0, *)
final class DiagnosticTest: XCTestCase {

    func testVpnCoreWrapperDirect() throws {
        print("\n=== VpnCore Diagnostic Test ===")
        print("Platform: macOS")
        print("Architecture: \(getMachineArchitecture())")
        print("Debug mode: \(isDebugBuild() ? "YES" : "NO")")
        print("Process: \(ProcessInfo.processInfo.processName)")
        print("PID: \(ProcessInfo.processInfo.processIdentifier)")

        print("\n--- Testing VpnCoreWrapper.getServerList() ---")
        let result = VpnCoreWrapper.getServerList()

        if let jsonString = result {
            print("✅ SUCCESS: Received response")
            print("Length: \(jsonString.count) characters")
            print("Preview: \(jsonString.prefix(200))")
            XCTAssertTrue(jsonString.count > 0, "Response should not be empty")
        } else {
            print("❌ FAILED: VpnCoreWrapper.getServerList() returned nil")
            print("\nPossible causes:")
            print("1. Anti-debugging detection (check_debugger)")
            print("2. Missing OpenSSL runtime libraries")
            print("3. Framework not properly linked")
            print("4. Deployment target mismatch")
            print("5. Sandboxing restrictions")

            // Try to get more info
            print("\n--- Environment Check ---")
            print("DYLD_LIBRARY_PATH: \(ProcessInfo.processInfo.environment["DYLD_LIBRARY_PATH"] ?? "not set")")
            print("DYLD_FRAMEWORK_PATH: \(ProcessInfo.processInfo.environment["DYLD_FRAMEWORK_PATH"] ?? "not set")")

            XCTFail("VpnCoreWrapper.getServerList() returned nil - C library not working")
        }
    }

    func testOpenSSLAvailability() throws {
        print("\n--- OpenSSL Check ---")
        let fileManager = FileManager.default
        let openSSLPaths = [
            "/opt/homebrew/opt/openssl@3/lib/libssl.3.dylib",
            "/opt/homebrew/opt/openssl@3/lib/libcrypto.3.dylib",
            "/usr/local/opt/openssl@3/lib/libssl.3.dylib",
            "/usr/local/opt/openssl@3/lib/libcrypto.3.dylib"
        ]

        for path in openSSLPaths {
            let exists = fileManager.fileExists(atPath: path)
            print("\(exists ? "✅" : "❌") \(path)")
        }
    }

    private func getMachineArchitecture() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machine = withUnsafeBytes(of: &systemInfo.machine) {
            $0.bindMemory(to: CChar.self)
        }
        return String(cString: Array(machine))
    }

    private func isDebugBuild() -> Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}
