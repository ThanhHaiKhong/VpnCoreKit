import XCTest
@testable import VpnCoreKit
@testable import VpnCoreObjC
import Foundation

#if os(macOS)

/// macOS-ONLY tests to diagnose "Native call returned null" issue
/// These tests check the specific runtime environment that might cause failures
@available(macOS 15.0, *)
final class MacOSOnlyTests: XCTestCase {

    // MARK: - Environment Detection Tests

    func testMacOSVersion() throws {
        print("\n=== macOS Version Check ===")

        let version = ProcessInfo.processInfo.operatingSystemVersion
        print("macOS Version: \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)")

        // VpnCore binary requires macOS 15.0+
        XCTAssertGreaterThanOrEqual(version.majorVersion, 15,
            "VpnCore requires macOS 15.0 or later. Current: \(version.majorVersion).\(version.minorVersion)")

        if version.majorVersion < 15 {
            print("⚠️  WARNING: Running on macOS \(version.majorVersion).x")
            print("   VpnCore binary was built for macOS 15.0+")
            print("   This WILL cause 'Native call returned null' errors!")
        } else {
            print("✅ macOS version is compatible (\(version.majorVersion).\(version.minorVersion))")
        }
    }

    func testDebuggerDetection() throws {
        print("\n=== Debugger Detection Test ===")

        // Check if process is being debugged
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride

        let result = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)

        if result == 0 {
            let isBeingDebugged = (info.kp_proc.p_flag & P_TRACED) != 0

            if isBeingDebugged {
                print("⚠️  WARNING: Process is being debugged!")
                print("   VpnCore has anti-debugging protection")
                print("   This MAY cause functions to return NULL")
                print("   Solution: Run without debugger (Product → Run Without Building)")
            } else {
                print("✅ Process is NOT being debugged")
            }

            // Don't fail the test, just warn
            if isBeingDebugged {
                print("\n📝 Note: Test continues despite debugger detection")
                print("   Some apps disable anti-debug in test builds")
            }
        }
    }

    func testProcessEnvironment() throws {
        print("\n=== Process Environment Check ===")

        print("Process Name: \(ProcessInfo.processInfo.processName)")
        print("Process ID: \(ProcessInfo.processInfo.processIdentifier)")
        print("Bundle ID: \(Bundle.main.bundleIdentifier ?? "none")")
        print("Executable Path: \(ProcessInfo.processInfo.arguments[0])")

        // Check if running from Xcode
        let execPath = ProcessInfo.processInfo.arguments[0]
        let isXcodeTest = execPath.contains("DerivedData") ||
                          execPath.contains("xctest")

        if isXcodeTest {
            print("✅ Running in test environment")
        } else {
            print("📱 Running in app environment")
        }

        // Check environment variables that might affect behavior
        let env = ProcessInfo.processInfo.environment
        if let dyldPath = env["DYLD_LIBRARY_PATH"] {
            print("DYLD_LIBRARY_PATH: \(dyldPath)")
        }
        if let dyldFramework = env["DYLD_FRAMEWORK_PATH"] {
            print("DYLD_FRAMEWORK_PATH: \(dyldFramework)")
        }
    }

    // MARK: - Framework Loading Tests

    func testVpnCoreFrameworkLoading() throws {
        print("\n=== VpnCore Framework Loading Test ===")

        // Try to call the actual functions to verify they're loaded
        print("Testing if VpnCore functions can be called...")

        let result = VpnCoreWrapper.getServerList()

        if result != nil {
            print("✅ VpnCore functions are loaded and callable")
        } else {
            print("❌ VpnCore functions returned nil")
            print("   This could mean:")
            print("   - Framework not loaded properly")
            print("   - Anti-debugging triggered")
            print("   - Runtime environment issue")
        }
    }

    func testCPPStandardLibrary() throws {
        print("\n=== C++ Standard Library Check ===")

        // Test by actually calling C++ functions through VpnCore
        print("Testing C++ standard library via VpnCore...")

        // The fact that VpnCore loads and runs proves libc++ is linked
        // because VpnCore uses C++ internally (std::string, std::vector, etc.)

        let result = VpnCoreWrapper.getServerList()

        if result != nil {
            print("✅ C++ standard library is properly linked")
            print("   (VpnCore uses C++ internally and works)")
        } else {
            print("⚠️  Could not verify C++ linking")
            print("   VpnCore call returned nil")
        }
    }

    func testOpenSSLAvailability() throws {
        print("\n=== OpenSSL Availability Test ===")

        let openSSLPaths = [
            "/opt/homebrew/opt/openssl@3/lib/libssl.3.dylib",
            "/opt/homebrew/opt/openssl@3/lib/libcrypto.3.dylib",
            "/usr/local/opt/openssl@3/lib/libssl.3.dylib",
            "/usr/local/opt/openssl@3/lib/libcrypto.3.dylib"
        ]

        var foundSSL = false
        var foundCrypto = false

        for path in openSSLPaths {
            let exists = FileManager.default.fileExists(atPath: path)
            print("\(exists ? "✅" : "❌") \(path)")

            if path.contains("libssl") && exists {
                foundSSL = true
            }
            if path.contains("libcrypto") && exists {
                foundCrypto = true
            }
        }

        if !foundSSL || !foundCrypto {
            print("\n⚠️  WARNING: OpenSSL 3 not found!")
            print("   Install with: brew install openssl@3")
            print("   This may cause runtime failures")
        }
    }

    // MARK: - Native API Call Tests

    func testNativeCallDirect() throws {
        print("\n=== Direct Native Call Test ===")

        print("Calling VpnCoreWrapper.getServerList()...")
        let startTime = Date()

        let result = VpnCoreWrapper.getServerList()

        let elapsed = Date().timeIntervalSince(startTime)
        print("Call completed in \(String(format: "%.3f", elapsed))s")

        if let jsonString = result {
            print("✅ SUCCESS: Received response")
            print("   Length: \(jsonString.count) characters")
            print("   Preview: \(jsonString.prefix(100))")

            // Verify it's valid JSON
            if let data = jsonString.data(using: .utf8) {
                do {
                    let json = try JSONSerialization.jsonObject(with: data)
                    if let array = json as? [[String: Any]] {
                        print("   Parsed: \(array.count) servers")
                    }
                } catch {
                    print("   JSON parse error: \(error)")
                }
            }
        } else {
            print("❌ FAILED: VpnCoreWrapper.getServerList() returned nil")
            print("\n🔍 Diagnostic Information:")
            print("   1. Check macOS version (need 15.0+)")
            print("   2. Check if debugger is attached")
            print("   3. Check OpenSSL installation")
            print("   4. Check C++ library linkage")
            print("   5. Check framework bundle structure")

            XCTFail("Native call returned nil - see diagnostic info above")
        }
    }

    func testNativeCallRepeated() throws {
        print("\n=== Repeated Native Call Test ===")
        print("Testing stability with 5 consecutive calls...")

        var successCount = 0
        var failCount = 0

        for i in 1...5 {
            let result = VpnCoreWrapper.getServerList()
            if result != nil {
                successCount += 1
                print("  Call \(i): ✅ Success")
            } else {
                failCount += 1
                print("  Call \(i): ❌ Failed (nil)")
            }

            // Small delay between calls
            Thread.sleep(forTimeInterval: 0.1)
        }

        print("\nResults: \(successCount)/5 successful")

        if failCount > 0 {
            print("⚠️  WARNING: Inconsistent results!")
            print("   This suggests a race condition or initialization issue")
        }

        XCTAssertEqual(successCount, 5,
            "Should succeed all 5 times. Got \(successCount) successes, \(failCount) failures")
    }

    func testVpnAPIWithRetry() async throws {
        print("\n=== VpnAPI with Retry Test ===")

        let maxRetries = 3
        var attempt = 0
        var lastError: VpnAPIError?

        while attempt < maxRetries {
            attempt += 1
            print("Attempt \(attempt)/\(maxRetries)...")

            let result = await VpnAPI.shared.getServers()

            switch result {
            case .success(let servers):
                print("✅ SUCCESS on attempt \(attempt)")
                print("   Received \(servers.count) servers")
                return  // Success!

            case .failure(let error):
                lastError = error
                print("❌ Failed on attempt \(attempt): \(error.localizedDescription)")

                if case .nativeNull = error {
                    print("   Error type: Native call returned null")
                }

                if attempt < maxRetries {
                    print("   Retrying after 1 second...")
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                }
            }
        }

        // All retries failed
        print("\n❌ All \(maxRetries) attempts failed")
        if let error = lastError {
            print("Last error: \(error)")
        }

        XCTFail("VpnAPI.getServers() failed after \(maxRetries) attempts")
    }

    // MARK: - App Bundle Simulation Test

    func testFromSimulatedAppContext() throws {
        print("\n=== Simulated App Context Test ===")

        // This test simulates calling from an app (not a test)
        // by checking if behavior changes based on context

        let isTest = ProcessInfo.processInfo.processName == "xctest"
        print("Running in test context: \(isTest)")

        if isTest {
            print("📝 Note: To truly test app behavior, build a real app")
            print("   Test environment might have different linking/loading")
        }

        // Call the API
        let result = VpnCoreWrapper.getServerList()

        if result == nil {
            print("\n💡 TROUBLESHOOTING TIPS:")
            print("1. Build your actual app (not just tests)")
            print("2. Add these to your app's build settings:")
            print("   - Link libc++ (Other Linker Flags: -lc++)")
            print("   - Add OpenSSL path if needed")
            print("3. Check app entitlements:")
            print("   - com.apple.security.network.client = true")
            print("4. Run app OUTSIDE of Xcode debugger:")
            print("   - Build app")
            print("   - Run from Finder or Terminal")
            print("5. Check Console.app for crash logs/errors")
        }

        XCTAssertNotNil(result, "Native call should work in test environment")
    }

    // MARK: - Memory & Threading Tests

    func testConcurrentCalls() async throws {
        print("\n=== Concurrent Call Test ===")
        print("Testing thread safety with 3 concurrent calls...")

        let results = await withTaskGroup(of: Bool.self) { group in
            for i in 1...3 {
                group.addTask {
                    print("  Starting concurrent call \(i)")
                    let result = VpnCoreWrapper.getServerList()
                    let success = result != nil
                    print("  Concurrent call \(i): \(success ? "✅" : "❌")")
                    return success
                }
            }

            var successes: [Bool] = []
            for await result in group {
                successes.append(result)
            }
            return successes
        }

        let successCount = results.filter { $0 }.count
        print("\nConcurrent results: \(successCount)/3 successful")

        XCTAssertEqual(successCount, 3,
            "All concurrent calls should succeed. Got \(successCount)/3")
    }

    // MARK: - Build Configuration Test

    func testBuildConfiguration() throws {
        print("\n=== Build Configuration Test ===")

        #if DEBUG
        print("Build: DEBUG")
        print("⚠️  Anti-debugging is more likely to trigger in debug builds")
        print("   Consider testing in RELEASE mode")
        #else
        print("Build: RELEASE")
        print("✅ Less likely to have anti-debugging issues")
        #endif

        #if RELEASE
        print("Optimization: ON")
        #else
        print("Optimization: OFF")
        #endif
    }

    // MARK: - Integration Test

    func testFullIntegrationFlow() async throws {
        print("\n=== Full Integration Flow Test ===")
        print("Simulating real app usage pattern...")

        // Step 1: Get servers
        print("\n1️⃣  Getting server list...")
        let serversResult = await VpnAPI.shared.getServers()

        guard case .success(let servers) = serversResult else {
            print("❌ Step 1 FAILED: Could not get servers")
            if case .failure(let error) = serversResult {
                print("   Error: \(error.localizedDescription)")
            }
            XCTFail("Integration test failed at step 1: getServers")
            return
        }

        print("✅ Step 1 SUCCESS: Got \(servers.count) servers")

        // Step 2: Pick a server
        print("\n2️⃣  Selecting a server...")
        guard let server = servers.first(where: { $0.protocols.contains(.openvpn) }) else {
            XCTFail("No OpenVPN servers available")
            return
        }
        print("✅ Step 2 SUCCESS: Selected \(server.name)")

        // Step 3: Get configuration
        print("\n3️⃣  Getting server configuration...")
        let configResult = await VpnAPI.shared.getConfiguration(
            serverId: server.id,
            protocol: .openvpn
        )

        guard case .success(let config) = configResult else {
            print("❌ Step 3 FAILED: Could not get configuration")
            if case .failure(let error) = configResult {
                print("   Error: \(error.localizedDescription)")
            }
            XCTFail("Integration test failed at step 3: getConfiguration")
            return
        }

        print("✅ Step 3 SUCCESS: Got configuration")
        print("   Server: \(config.name)")
        print("   Host: \(config.host)")

        // Step 4: Verify configuration is usable
        print("\n4️⃣  Verifying configuration...")
        XCTAssertFalse(config.host.isEmpty, "Host should not be empty")
        XCTAssertFalse(config.username.isEmpty, "Username should not be empty")
        XCTAssertFalse(config.password.isEmpty, "Password should not be empty")

        if config.protocol == .openvpn {
            XCTAssertNotNil(config.template, "OpenVPN template should exist")
            XCTAssertFalse(config.template?.isEmpty ?? true, "Template should not be empty")
        }

        print("✅ Step 4 SUCCESS: Configuration is valid and usable")
        print("\n🎉 FULL INTEGRATION TEST PASSED!")
    }
}

#endif
