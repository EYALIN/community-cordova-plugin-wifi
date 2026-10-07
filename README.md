# Community Cordova Plugin WiFi


The Community Cordova Plugin WiFi offers extensive WiFi management functionalities for Cordova applications on Android and iOS platforms. While Android devices benefit from a wide range of WiFi management capabilities, iOS support focuses on network information retrieval due to platform restrictions.


I dedicate a considerable amount of my free time to developing and maintaining many cordova plugins for the community ([See the list with all my maintained plugins][community_plugins]).
To help ensure this plugin is kept updated,
new features are added and bugfixes are implemented quickly,
please donate a couple of dollars (or a little more if you can stretch) as this will help me to afford to dedicate time to its maintenance.
Please consider donating if you're using this plugin in an app that makes you money,
or if you're asking for new features or priority bug fixes. Thank you!

[![](https://img.shields.io/static/v1?label=Sponsor%20Me&style=for-the-badge&message=%E2%9D%A4&logo=GitHub&color=%23fe8e86)](https://github.com/sponsors/eyalin)


## Features

- Scan for available WiFi networks (Android)
- Connect to or disconnect from a WiFi network (Android)
- Check WiFi status and toggle WiFi (Android)
- Retrieve current network information
- Check internet connectivity
- Ping network addresses (Android)
- Obtain WiFi signal strength and other network details

## Installation

```bash
cordova plugin add community-cordova-plugin-wifi
```

## API Reference and Examples

### isConnectedToInternet

**Platform Support:** Android, iOS

Checks if there is an active internet connection.

#### Example

```javascript
WifiPlugin.isConnectedToInternet().then(isConnected => {
    console.log("Internet connectivity status:", isConnected);
}).catch(error => {
    console.error("Error:", error);
});
```

**Response:**

- `isConnected` (boolean): True if the device is connected to the internet.

### getWifiList (Android Only)

Scans for available WiFi networks.

**Platform Support:** Android

#### Example

```javascript
WifiPlugin.getWifiList().then(wifiList => {
    console.log("WiFi networks:", wifiList);
}).catch(error => {
    console.error("Error:", error);
});
```

**Response Fields:**

Each object in the `wifiList` array contains:
- `SSID` (string): Network name.
- `BSSID` (string): Access point MAC address.
- `capabilities` (string): Supported protocols and authentication methods.
- `frequency` (number): Channel frequency in MHz.
- `level` (number): Signal strength in dBm.
- `security` (string): Security protocols in use.

### getAllWifiDetails

Retrieves comprehensive WiFi network details.

**Platform Support:** Android, iOS (iOS requires extra setup - see "iOS Requirements" below)

#### Example

```javascript
WifiPlugin.getAllWifiDetails().then(details => {
    console.log("WiFi Details:", details);
}).catch(error => {
    console.error("Error:", error);
});
```

**Response Fields:**

- `ssid` / `SSID` (string): Current network SSID. Lowercase key on Android, capitalized on iOS (pre-existing per-platform convention; not changed here).
- `bssid` / `BSSID` (string): Network BSSID.
- `ip` / `IP` (string): Device IP address in the network.
- `mac` / `MAC` (string, Android only): Device MAC address. Always `"Unavailable"` on iOS (not exposed by any public API).
- `signalstrength` / `SignalStrength` (number): **Different scale per platform.** Android returns the raw RSSI in dBm (e.g. `-45`). iOS (1.1.0+) returns `NEHotspotNetwork.signalStrength`, normalized `0.0`-`1.0`. Don't compare the two directly.
- `isSecure` (boolean, **iOS only, added in 1.1.0**): Whether the current network uses security (WEP/WPA/WPA2/WPA3), from `NEHotspotNetwork.isSecure`. Not present on Android.
- `reason` (string, **iOS only, added in 1.1.0**): Empty string on success. When the fields above fall back to `"Unavailable"`/`-1`, one of: `location_denied`, `location_restricted`, `location_services_disabled`, `no_wifi_or_entitlement`. Not present on Android.
- Additional network details may include `networkid`, `linkspeed`, `rssi`, etc., with availability varying between platforms.

### iOS Requirements (SSID/BSSID, added in 1.1.0)

Reading the real SSID/BSSID on iOS needs three things the **consuming app** must provide — a
plugin cannot grant any of them on its own:

1. **The "Access WiFi Information" capability on the App ID.** In the Apple Developer portal
   (Certificates, Identifiers & Profiles > Identifiers > your App ID), enable **Access WiFi
   Information**, then regenerate/download the provisioning profile used to sign the app.
   This plugin's `plugin.xml` writes the `com.apple.developer.networking.wifi-info`
   entitlement key into the generated Xcode project's `Entitlements-Debug.plist` /
   `Entitlements-Release.plist`, and links `NetworkExtension.framework` - but the entitlement
   is only *honored* by Apple's signing/provisioning if the capability is also turned on for
   that App ID. Without it, `getAllWifiDetails` returns `"Unavailable"` with
   `reason: "no_wifi_or_entitlement"` even on a real device connected to Wi-Fi.
2. **Foreground ("When In Use") location authorization.** As of 1.1.0, `getAllWifiDetails`
   requests this itself the first time it's called if the status is not yet determined (via
   `CLLocationManager`), and waits for the user's answer before resolving - it no longer
   assumes an earlier `getIpInfo()` call already prompted. If the user denies it, the result
   resolves (it does not reject) with `"Unavailable"` fields and `reason: "location_denied"`
   (or `location_restricted` / `location_services_disabled`).
3. **The app must be in the foreground (or recently so).** `NEHotspotNetwork` only returns data
   while the hosting app is active; it will not resolve a real network in the background.

The two `NSLocation*UsageDescription` strings in `Info.plist` are still added by this plugin as
before.

**Implementation note:** SSID/BSSID/`signalStrength`/`isSecure` are read via
`NEHotspotNetwork.fetchCurrentWithCompletionHandler:` (iOS 14+), replacing the deprecated
`CNCopyCurrentNetworkInfo`, which Apple has progressively stopped returning data for (notably
on iOS 26). The deprecated API is kept ONLY as a fallback for apps whose own deployment target
is below iOS 14 (cordova-ios 8's own project template defaults to iOS 13.0 unless the app sets
a higher `<preference name="deployment-target">`); on iOS 14+ apps the deprecated path is never
called.

### isWifiEnabled (Android Only)

Checks if WiFi is enabled on the device.

**Platform Support:** Android

#### Example

```javascript
WifiPlugin.isWifiEnabled().then(isEnabled => {
    console.log("WiFi Enabled:", isEnabled);
}).catch(error => {
    console.error("Error:", error);
});
```

**Response:**

- `isEnabled` (boolean): True if WiFi is enabled.

### connectToNetwork (Android Only)

Connects to a specified WiFi network.

**Platform Support:** Android

#### Example

```javascript
WifiPlugin.connectToNetwork("SSID", "password").then(() => {
    console.log("Connected successfully.");
}).catch(error => {
    console.error("Error:", error);
});
```

No additional response fields.

## Platform Support

This plugin supports Android and iOS. Note that iOS functionalities are limited to retrieving network information due to platform restrictions.

## Permissions

Ensure your application requests the necessary permissions. Android requires permissions for accessing WiFi state, location, and changing WiFi connectivity. iOS may require location permissions for accessing network information.

## Contributing

Contributions are welcome! Feel free to submit pull requests or open issues on the [GitHub repository](https://github.com/EYALIN/community-cordova-plugin-wifi).

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

[community_plugins]: https://github.com/EYALIN?tab=repositories&q=community&type=&language=&sort=
