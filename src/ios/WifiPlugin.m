#import "WifiPlugin.h"
#include <ifaddrs.h>
#include <arpa/inet.h>
#import <CoreLocation/CoreLocation.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <Network/Network.h>
#import <NetworkExtension/NetworkExtension.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>

@interface WifiPlugin() <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CDVInvokedUrlCommand *currentCommand;
@property (strong, nonatomic) NSMutableArray<void (^)(BOOL authorized, NSString *reason)> *pendingAuthorizationCallbacks;

@end

@implementation WifiPlugin

- (void)pluginInitialize {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.pendingAuthorizationCallbacks = [NSMutableArray array];
}


- (void)getWifiList:(CDVInvokedUrlCommand*)command {
    // This is not supported on iOS due to privacy reasons.
    [self sendNotSupportedError:command];
}

- (void)connectToNetwork:(CDVInvokedUrlCommand*)command {
    // This is not supported on iOS.
    [self sendNotSupportedError:command];
}

- (void)disconnectFromNetwork:(CDVInvokedUrlCommand*)command {
    // This is not supported on iOS.
    [self sendNotSupportedError:command];
}

- (void)isWifiEnabled:(CDVInvokedUrlCommand*)command {
    // iOS does not provide a way to check if WiFi is enabled.
    [self sendNotSupportedError:command];
}

- (void)wifiToggle:(CDVInvokedUrlCommand*)command {
    // Toggling WiFi is not supported on iOS.
    [self sendNotSupportedError:command];
}

- (void)isConnectedToInternet:(CDVInvokedUrlCommand*)command {
    // Define zero address for internet reachability check
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET; // IPv4 address

    // Use SCNetworkReachability to check reachability to the zero address
    SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithAddress(NULL, (const struct sockaddr *)&zeroAddress);
    SCNetworkReachabilityFlags flags;

    // Prepare the plugin result variable
    CDVPluginResult* pluginResult = nil;

    if (reachabilityRef) {
        // Check if the reachability can get flags successfully
        if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
            // Flags are available, check if the network is reachable
            BOOL isReachable = flags & kSCNetworkFlagsReachable;
            BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;

            // The network is considered reachable if it's reachable without requiring a connection
            BOOL isConnected = isReachable && !needsConnection;

            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:isConnected];
        } else {
            // Unable to get flags, consider the internet as not reachable
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Cannot determine internet connectivity."];
        }

        // Release the reachability reference
        CFRelease(reachabilityRef);
    } else {
        // Reachability reference creation failed
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Failed to create reachability reference."];
    }

    // Send the plugin result back to the Cordova callback
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


- (void)checkAndRequestWifiPermission:(CDVInvokedUrlCommand*)command {
    // Permissions for WiFi are not explicitly required on iOS for basic operations.
    [self sendNotSupportedError:command];
}

- (void)getConnectedDevices:(CDVInvokedUrlCommand*)command {
    // Scanning for devices on the network is not supported without specific network privileges.
    [self sendNotSupportedError:command];
}

- (void)getWifiStrength:(CDVInvokedUrlCommand*)command {
    // Directly accessing WiFi strength is not possible through public APIs.
    [self sendNotSupportedError:command];
}

- (void)ping:(CDVInvokedUrlCommand*)command {
    // Implementing a ping function would require using ICMP or similar, which is beyond this scope.
    [self sendNotSupportedError:command];
}

- (void)canConnectToInternet:(CDVInvokedUrlCommand*)command {
    // This would be similar to isConnectedToInternet and depends on external reachability.
    [self sendNotSupportedError:command];
}

- (void)canConnectToRouter:(CDVInvokedUrlCommand*)command {
    // Checking connection to a specific router is not supported without specific permissions.
    [self sendNotSupportedError:command];
}


#pragma mark - getAllWifiDetails (NEHotspotNetwork, self-requesting authorization)

- (void)getAllWifiDetails:(CDVInvokedUrlCommand*)command {
    [self ensureLocationAuthorizationWithCompletion:^(BOOL authorized, NSString *reason) {
        if (!authorized) {
            [self sendWifiDetailsUnavailable:command reason:reason ?: @"location_unavailable"];
            return;
        }
        [self fetchSSIDInfoWithCompletion:^(NSDictionary *networkInfo) {
            if (!networkInfo) {
                // No current Wi-Fi association, no "Access WiFi Information" entitlement on the
                // consuming app, or (pre-iOS 14) the deprecated CaptiveNetwork API returned nothing.
                [self sendWifiDetailsUnavailable:command reason:@"no_wifi_or_entitlement"];
                return;
            }

            NSString *ipAddress = [self getIPAddress];
            NSDictionary *wifiDetails = @{
                @"isWifiEnabled": @YES,
                @"isSupportWifi": @YES,
                @"SSID": networkInfo[@"SSID"] ?: @"Unavailable",
                @"BSSID": networkInfo[@"BSSID"] ?: @"Unavailable",
                @"IP": ipAddress ?: @"Unavailable",
                @"MAC": @"Unavailable", // Not accessible on iOS
                @"NetworkID": @-1, // Not applicable
                @"LinkSpeed": @-1, // Not accessible
                // Normalized 0.0-1.0 (NEHotspotNetwork.signalStrength). NOT the same scale as
                // Android's dBm-based "signalstrength" — see README.
                @"SignalStrength": networkInfo[@"signalStrength"] ?: @-1,
                @"Gateway": @"Unavailable", // Not directly accessible
                @"RSSI": @-1, // Not directly accessible
                @"Speed": @-1, // Not directly accessible
                @"Frequency": @-1, // Not directly accessible
                @"Channel": @-1, // Not directly accessible
                @"DNS1": @"Unavailable", // Not directly accessible
                @"DNS2": @"Unavailable", // Not directly accessible
                @"isSecure": networkInfo[@"isSecure"] ?: @NO, // additive, iOS only (NEHotspotNetwork)
                @"reason": @"", // additive, machine-readable reason when Unavailable
            };

            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:wifiDetails];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }];
    }];
}

- (void)sendWifiDetailsUnavailable:(CDVInvokedUrlCommand *)command reason:(NSString *)reason {
    NSDictionary *wifiDetails = @{
        @"isWifiEnabled": @NO,
        @"isSupportWifi": @YES,
        @"SSID": @"Unavailable",
        @"BSSID": @"Unavailable",
        @"IP": [self getIPAddress] ?: @"Unavailable",
        @"MAC": @"Unavailable",
        @"NetworkID": @-1,
        @"LinkSpeed": @-1,
        @"SignalStrength": @-1,
        @"Gateway": @"Unavailable",
        @"RSSI": @-1,
        @"Speed": @-1,
        @"Frequency": @-1,
        @"Channel": @-1,
        @"DNS1": @"Unavailable",
        @"DNS2": @"Unavailable",
        @"isSecure": @NO,
        @"reason": reason ?: @"unavailable",
    };
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:wifiDetails];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}


#pragma mark - getIpInfo

- (void)getIpInfo:(CDVInvokedUrlCommand*)command {
    self.currentCommand = command;

    [self ensureLocationAuthorizationWithCompletion:^(BOOL authorized, NSString *reason) {
        if (!authorized) {
            [self sendError:[self locationErrorMessageForReason:reason] toCommand:command];
            return;
        }
        if (![CLLocationManager locationServicesEnabled]) {
            [self sendError:@"Location request services are not enabled." toCommand:command];
            return;
        }
        [self.locationManager startUpdatingLocation];
    }];
}

- (NSString *)locationErrorMessageForReason:(NSString *)reason {
    if ([reason isEqualToString:@"location_denied"]) {
        return @"Location services are not enabled.";
    }
    if ([reason isEqualToString:@"location_restricted"]) {
        return @"Location services are restricted.";
    }
    return @"Location request services are not enabled.";
}


#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    [self.locationManager stopUpdatingLocation]; // Stop location updates to conserve battery life

    CLLocation *location = [locations lastObject];
    [self reverseGeocodeLocation:location forCommand:self.currentCommand];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [self sendError:@"Failed to get location." toCommand:self.currentCommand];
}

// iOS 14+ delegate callback for authorization changes.
- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager API_AVAILABLE(ios(14.0)) {
    [self drainPendingAuthorizationCallbacksWithStatus:manager.authorizationStatus];
}

// Pre-iOS 14 delegate callback. Only acts when the iOS 14+ callback above isn't the one firing.
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (@available(iOS 14.0, *)) {
        return;
    }
    [self drainPendingAuthorizationCallbacksWithStatus:status];
}


#pragma mark - Location authorization (self-requesting)

// Resolves immediately if authorization is already decided; otherwise requests
// "When In Use" authorization and queues the completion to run once the user answers.
- (void)ensureLocationAuthorizationWithCompletion:(void (^)(BOOL authorized, NSString *reason))completion {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];

    switch (status) {
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        case kCLAuthorizationStatusAuthorizedAlways:
            completion(YES, nil);
            return;
        case kCLAuthorizationStatusDenied:
            completion(NO, @"location_denied");
            return;
        case kCLAuthorizationStatusRestricted:
            completion(NO, @"location_restricted");
            return;
        case kCLAuthorizationStatusNotDetermined:
        default:
            break;
    }

    if (![CLLocationManager locationServicesEnabled]) {
        completion(NO, @"location_services_disabled");
        return;
    }

    @synchronized (self.pendingAuthorizationCallbacks) {
        [self.pendingAuthorizationCallbacks addObject:[completion copy]];
    }
    [self.locationManager requestWhenInUseAuthorization];
}

- (void)drainPendingAuthorizationCallbacksWithStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusNotDetermined) {
        return; // still waiting on the user
    }

    NSArray<void (^)(BOOL, NSString *)> *callbacks;
    @synchronized (self.pendingAuthorizationCallbacks) {
        callbacks = [self.pendingAuthorizationCallbacks copy];
        [self.pendingAuthorizationCallbacks removeAllObjects];
    }
    if (callbacks.count == 0) {
        return;
    }

    BOOL authorized = (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways);
    NSString *reason = nil;
    if (!authorized) {
        reason = (status == kCLAuthorizationStatusDenied) ? @"location_denied" : @"location_restricted";
    }
    for (void (^callback)(BOOL, NSString *) in callbacks) {
        callback(authorized, reason);
    }
}


#pragma mark - Utility Methods

- (NSString *)getIPAddress {
    NSString *address = nil;
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;

    success = getifaddrs(&interfaces);
    if (success == 0) {
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    freeifaddrs(interfaces);
    return address ?: @"Unavailable";
}


- (NSString *)checkConnectionType {
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;

    SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)&zeroAddress);
    if (reachabilityRef != NULL) {
        SCNetworkReachabilityFlags flags;
        if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
            if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
                // The target host is not reachable.
                CFRelease(reachabilityRef);
                return @"none";
            }

            NSString *connectionType = @"unknown";

            if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
                // If the target host is reachable and no connection is required, then we'll assume it's WiFi
                connectionType = @"wifi";
            }

            if (((flags & kSCNetworkReachabilityFlagsConnectionOnDemand) != 0) ||
                ((flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) {
                // ... and the connection is on-demand (or on-traffic) if the
                // calling application is using the CFSocketStream or higher APIs.
                if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
                    // ... and no [user] intervention is needed
                    connectionType = @"wifi";
                }
            }

#if TARGET_OS_IPHONE
            if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
                // ... but WWAN connections are OK if the calling application
                // is using the CFNetwork APIs.
                connectionType = @"cellular";
            }
#endif

            CFRelease(reachabilityRef);
            return connectionType;
        }
        CFRelease(reachabilityRef);
    }

    return @"unknown";
}


- (void)reverseGeocodeLocation:(CLLocation *)location forCommand:(CDVInvokedUrlCommand *)command {
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];

    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray<CLPlacemark *> *placemarks, NSError *error) {
        if (error) {
            [self sendError:@"Failed to get location information." toCommand:command];
            return;
        }

        CLPlacemark *placemark = [placemarks firstObject];

        [self fetchSSIDInfoWithCompletion:^(NSDictionary *networkInfo) {
            NSMutableArray *ipInfos = [NSMutableArray array];
            NSDictionary *ipInfo = @{
                       @"type": [self checkConnectionType],
                       @"signal": networkInfo[@"signalStrength"] ?: @-1,
                       @"speed": @-1, // Not directly accessible
                       @"ssid": networkInfo[@"SSID"] ?: @"",
                       @"internalip": [self getIPAddress] ?: @"",
                       @"macaddress": @"Unavailable", // Not accessible on iOS
                       @"networkid": @-1, // Not applicable
                       @"frequency": @-1, // Not directly accessible
                       @"bssid": networkInfo[@"BSSID"] ?: @"",
                       @"dns1": @"Unavailable", // Not directly accessible
                       @"dns2": @"Unavailable", // Not directly accessible
                       @"timezone": [[NSTimeZone localTimeZone] name],
                       @"latitude": location ? @(location.coordinate.latitude) : @0,
                       @"longitude": location ? @(location.coordinate.longitude) : @0,
                       @"city": placemark.locality ?: @"",
                       @"street": placemark.thoroughfare ?: @"",
                       @"country": placemark.country ?: @"",
                       @"region": placemark.administrativeArea ?: @"",
                       @"zipcode": placemark.postalCode ?: @"",
                       @"state": placemark.administrativeArea ?: @"",
                   };

            [ipInfos addObject:ipInfo];
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:ipInfos];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }];
    }];
}

// Modern, async SSID/BSSID lookup. Requires the consuming app to hold the
// "Access WiFi Information" entitlement (com.apple.developer.networking.wifi-info)
// AND foreground location authorization; a Cordova plugin cannot grant that
// entitlement itself (see plugin.xml / README). Falls back to the deprecated
// CaptiveNetwork API only on deployment targets below iOS 14.
- (void)fetchSSIDInfoWithCompletion:(void (^)(NSDictionary *networkInfo))completion {
    if (@available(iOS 14.0, *)) {
        [NEHotspotNetwork fetchCurrentWithCompletionHandler:^(NEHotspotNetwork * _Nullable network) {
            if (!network) {
                completion(nil);
                return;
            }
            NSDictionary *info = @{
                @"SSID": network.SSID ?: @"Unavailable",
                @"BSSID": network.BSSID ?: @"Unavailable",
                @"signalStrength": @(network.signalStrength), // 0.0-1.0
                @"isSecure": @(network.isSecure),
            };
            completion(info);
        }];
        return;
    }

    // Deprecated fallback, only reachable when the consuming app's deployment
    // target is below iOS 14 (cordova-ios 8's own default is 13.0).
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *legacyInfo = [self legacyFetchSSIDInfo];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(legacyInfo);
        });
    });
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (NSDictionary *)legacyFetchSSIDInfo {
    NSArray *interfaceNames = CFBridgingRelease(CNCopySupportedInterfaces());
    NSDictionary *SSIDInfo = nil;
    for (NSString *interfaceName in interfaceNames) {
        SSIDInfo = CFBridgingRelease(CNCopyCurrentNetworkInfo((__bridge CFStringRef)interfaceName));
        if (SSIDInfo.count > 0) {
            break;
        }
    }
    return SSIDInfo;
}
#pragma clang diagnostic pop


- (void)sendError:(NSString *)errorMessage toCommand:(CDVInvokedUrlCommand *)command {
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMessage];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)sendNotSupportedError:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"This feature is not supported on iOS."];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}


@end
