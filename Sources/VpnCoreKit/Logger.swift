import Foundation
import OSLog

/// Logging for VpnCoreKit using OSLog
@available(iOS 15.0, macOS 15.0, *)
enum VpnCoreLog {
    private static let subsystem = "app.snapai.tvcast.vpncore"

    static let api = Logger(subsystem: subsystem, category: "api")
    static let wrapper = Logger(subsystem: subsystem, category: "wrapper")

    static func debug(_ message: String, category: Logger = VpnCoreLog.api) {
        #if DEBUG
        category.debug("\(message, privacy: .public)")
        #endif
    }

    static func info(_ message: String, category: Logger = VpnCoreLog.api) {
        category.info("\(message, privacy: .public)")
    }

    static func error(_ message: String, category: Logger = VpnCoreLog.api) {
        category.error("\(message, privacy: .public)")
    }
}
