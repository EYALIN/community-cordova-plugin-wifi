# Release Notes

## 1.1.1 (2026-10-10)

1.1.0 on npm cannot be installed: its `plugin.xml` contains a `--` sequence inside an XML comment
(a literal `--variable` token), XML forbids that, and cordova fails with `Malformed comment` on
`cordova plugin add`. Nobody could install 1.1.0, so **everything listed under 1.1.0 below
actually ships in 1.1.1.** Consumers on 1.1.0 should move to `^1.1.1`.

### Fixes in 1.1.1

- `plugin.xml` comment reworded, and the file is well-formed (checked with `xmllint`). The
  `android` namespace is now declared on the root element.
- The wifi-info entitlement hook no longer touches the Entitlements plists when
  `WIFI_INFO_ENTITLEMENT` is not set at all. Previously it removed
  `com.apple.developer.networking.wifi-info` on every prepare, including a key the app had added
  itself. The key is still removed when the variable is explicitly `false`.
- The hook also reads the variable from a `<variable>` inside this plugin's `<plugin>` element in
  `config.xml` (written by older cordova-cli `--save`), and accepts any attribute order or quote
  style in `<preference>`.
- TypeScript: `WifiDetails` now types the capitalised iOS keys (`SSID`, `BSSID`, `SignalStrength`,
  ...) as optional, and `IpInfo.signal` documents the per-platform scale.

## 1.1.0 (2026-10-07, never installable: use 1.1.1)

### iOS: real SSID/BSSID via NEHotspotNetwork ([#2](https://github.com/EYALIN/community-cordova-plugin-wifi/issues/2))

- `getAllWifiDetails` now reads SSID / BSSID through `NEHotspotNetwork.fetchCurrentWithCompletionHandler:`
  (iOS 14+), replacing the deprecated `CNCopyCurrentNetworkInfo`, which Apple has stopped returning
  data for (notably on iOS 26). The deprecated API is kept only as a fallback for apps whose
  deployment target is below iOS 14.
- `getIpInfo()` on iOS: `signal` is now `NEHotspotNetwork.signalStrength` (`0.0`-`1.0`, `-1` when
  unavailable). 1.0.x always returned `-1` there.
- New iOS-only fields: `signalStrength` (normalized `0.0`-`1.0`, a different scale from Android's dBm),
  `isSecure`, and `reason` (`location_denied`, `location_restricted`, `location_services_disabled`,
  `no_wifi_or_entitlement`; empty on success).
- `getAllWifiDetails` now requests "When In Use" location authorization itself when it is not yet
  determined, and waits for the answer. A denial resolves with `"Unavailable"` fields and a `reason`;
  it does not reject.
- `NetworkExtension.framework` is linked.

### iOS: the wifi-info entitlement is opt-in

The `com.apple.developer.networking.wifi-info` entitlement is written only when the app asks for it,
so apps that don't need the SSID aren't forced to add a capability to their App ID:

```bash
cordova plugin add community-cordova-plugin-wifi --variable WIFI_INFO_ENTITLEMENT=true
```

The app's App ID must also have **Access WiFi Information** enabled in the Apple Developer portal,
or iOS returns `reason: "no_wifi_or_entitlement"`. See the README, "iOS Requirements".

## 1.0.14

- Version bump only (no functional change from 1.0.13).

## 1.0.13

- Android: run Wi-Fi work off the main thread (ANR fix).
