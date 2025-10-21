#import "VpnCoreWrapper.h"
#import <vc_vpn_api.h>
#import <os/log.h>

static os_log_t vpncore_log() {
    static os_log_t log;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        log = os_log_create("app.snapai.tvcast.vpncore", "wrapper");
    });
    return log;
}

@implementation VpnCoreWrapper

+ (nullable NSString *)getServerList {
    // Call C function
    char *resultPtr = _L1sT_v3r_();
    if (resultPtr == NULL) {
        return nil;
    }

    // Convert C string to NSString
    NSString *jsonString = [NSString stringWithUTF8String:resultPtr];

    // Free C memory (CRITICAL - prevents memory leak)
    _Fr33_Str_(resultPtr);

    return jsonString;
}

+ (nullable NSString *)getServerConfigurationWithServerId:(NSString *)serverId
                                                  protocol:(NSString *)protocol {
    os_log_info(vpncore_log(), "getServerConfiguration: %{public}@ (%{public}@)", serverId, protocol);

    // Convert NSString to C strings
    const char *serverIdCStr = [serverId UTF8String];
    const char *protocolCStr = [protocol UTF8String];

    if (serverIdCStr == NULL || protocolCStr == NULL) {
        os_log_error(vpncore_log(), "Failed to convert NSString to C string");
        return nil;
    }

    os_log_debug(vpncore_log(), "Calling C function _G3t_C0nf_(\"%{public}s\", \"%{public}s\")", serverIdCStr, protocolCStr);

    // Call C function
    char *resultPtr = _G3t_C0nf_(serverIdCStr, protocolCStr);
    if (resultPtr == NULL) {
        os_log_error(vpncore_log(), "C function returned NULL");
        return nil;
    }

    // Convert C string to NSString
    NSString *jsonString = [NSString stringWithUTF8String:resultPtr];

    os_log_info(vpncore_log(), "Response received: %lu chars", (unsigned long)[jsonString length]);
    os_log_debug(vpncore_log(), "First 500 chars: %{public}@", [jsonString substringToIndex:MIN(500, [jsonString length])]);

    // Free C memory (CRITICAL - prevents memory leak)
    _Fr33_Str_(resultPtr);

    return jsonString;
}

@end
