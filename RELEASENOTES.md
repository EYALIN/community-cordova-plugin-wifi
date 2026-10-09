# Release Notes

## 1.1.1 (2026-10-09)

### Fix: `cordova plugin add` fails on 1.1.0 with `Malformed comment`

Patch release that ships the `plugin.xml` comment fix described under 1.1.0. The 1.1.0 package on
npm still contains a `--` sequence inside an XML comment, so cordova cannot parse its `plugin.xml`
and the install fails. 1.1.1 has a well-formed `plugin.xml` (checked with `xmllint`). There is no
functional change from 1.1.0. Consumers on 1.1.0 should move to `^1.1.1`.

## 1.1.0 (2026-10-07, fixed same day)

### Fix: malformed XML comment broke `cordova plugin add` for every consumer

`plugin.xml` had a `<!-- ... -->` comment whose body contained a literal `--variable` token.
XML forbids `--` anywhere inside a comment, so cordova's XML parser threw `Malformed comment`
on every `cordova plugin add community-cordova-plugin-wifi@1.1.0`, published and all — nobody
could install this version. Reworded the comment to avoid the double-hyphen; no functional
change. **The published 1.1.0 package on npm still has the broken comment** until a patch
release goes out.

### iOS: real SSID/BSSID via NEHotspotNetwork ([#2](https://github.com/EYALIN/community-cordova-plugin-wifi/issues/2))

- `getAllWifiDetails` now reads SSID / BSSID through `NEHotspotNetwork.fetchCurrentWithCompletionHandler:`
  (iOS 14+), replacing the deprecated `CNCopyCurrentNetworkInfo`, which Apple has stopped returning
  data for (notably on iOS 26). The deprecated API is kept only as a fallback for apps whose
  deployment target is below iOS 14.
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

## 1.0.13

- Android: run Wi-Fi work off the main thread (ANR fix).
