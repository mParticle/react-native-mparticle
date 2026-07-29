# Migration Guides

This document provides migration guidance for changes in `react-native-mparticle`.

## Migrating Android apps to mParticle Android SDK 6.0.0

The React Native JavaScript API is unchanged. Existing calls to
`MParticle.Rokt.selectPlacements`, `close()`, `setSessionId()`,
`getSessionId()`, and `purchaseFinalized()` continue to use the same
JavaScript signatures and event names.

### Android Rokt Dependencies

Android apps that use Rokt must include matching 6.x mParticle artifacts:

```gradle
implementation "com.mparticle:android-core:[6.0.0, 7.0)"
implementation "com.mparticle:android-rokt-kit:[6.0.0, 7.0)"
```

Apps that include `android-rokt-kit` `6.0.0` must build with `compileSdk` 35+
and Android Gradle Plugin 8.6+.

### Android Expo Config Plugin

If you use the Expo config plugin with `androidKits`, the plugin injects kit
dependencies with the `[6.0.0, 7.0)` range.

`selectShoppableAds` remains a no-op on Android in this release.

## Migrating to mParticle-Rokt 9.3+ (Rokt iOS 5.3 floor)

This update aligns the React Native wrapper with `mParticle-Rokt` **9.3+**,
which requires `Rokt-Widget` `~> 5.3` (and `RoktContracts` `~> 2.0`). Use kit
`9.3.2` or newer so CocoaPods cannot resolve Rokt iOS `5.2.x`.

### Dependency Changes

For standard Rokt placements on iOS, use:

```ruby
pod 'mParticle-Rokt', '~> 9.3'
pod 'Rokt-Widget', '~> 5.3'
```

Do not add `Rokt-Widget` to this React Native wrapper's podspec. Apps receive
it through `mParticle-Rokt` `9.3+`; the companion `Rokt-Widget` pin makes the
5.3 floor explicit in app Podfiles / Expo-generated Podfiles.

### React Native Rokt API

The wrapper exposes these Rokt APIs to JavaScript:

```ts
MParticle.Rokt.close(): Promise<void>
MParticle.Rokt.setSessionId(sessionId: string): Promise<void>
MParticle.Rokt.getSessionId(): Promise<string | null>
```

`close()` is supported on iOS and Android. Session APIs are backed by the iOS
mParticle Rokt kit. On Android, apps that use these session APIs must use
`android-core` and `android-rokt-kit` `6.0.0` or newer.

### Expo Config Plugin

Use `iosKits: ["mParticle-Rokt"]` for standard Rokt placements:

```json
[
  "react-native-mparticle",
  {
    "iosApiKey": "YOUR_IOS_API_KEY",
    "iosApiSecret": "YOUR_IOS_API_SECRET",
    "iosKits": ["mParticle-Rokt"]
  }
]
```

The plugin pins generated `mParticle-Rokt` pods to `~> 9.3` and companion
`Rokt-Widget` to `~> 5.3`. It does not add payment-extension pods or URL
callback forwarding in this release.

For global CNAME setup, configure the shared `customBaseUrl` setting:

```json
{
  "customBaseUrl": "https://cname.example.com"
}
```

The plugin applies this through `MPNetworkOptions.customBaseURL` on iOS and
`NetworkOptions.setCustomBaseURL` on Android before mParticle starts. There is
no runtime JavaScript setter because the Rokt kit reads this setting during
initialization.

### Notes

- The React Native API intentionally does not expose `handleURLCallback`.
