#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Objective-C wrapper for VpnCore C API
///
/// Provides safe Objective-C interface to the native vpn-core library.
/// Automatically handles memory management for C strings.
@interface VpnCoreWrapper : NSObject

/// Get list of available VPN servers
///
/// @return JSON string containing array of servers, or nil on error
/// @note The library automatically handles JWT generation and API authentication
+ (nullable NSString *)getServerList;

/// Get server configuration by ID and protocol
///
/// @param serverId Server ID from server list
/// @param protocol VPN protocol ("openvpn" or "ikev2")
/// @return JSON string containing server configuration, or nil on error
/// @note Response is automatically decrypted if Content-Type is application/octet-stream
+ (nullable NSString *)getServerConfigurationWithServerId:(NSString *)serverId
                                                  protocol:(NSString *)protocol;

@end

NS_ASSUME_NONNULL_END
