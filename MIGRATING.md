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
which requires `Rokt-Widget` `~> 5.3` (and `RoktContracts` `~> 2.0`), so the
Rokt iOS floor is enforced by the kit's own dependency graph rather than only by
an app-level pin.

### Dependency Changes

For standard Rokt placements on iOS, use:

```ruby
pod 'mParticle-Rokt', '~> 9.3'
pod 'Rokt-Widget', '~> 5.3'
```

Kit `9.3.2+` already enforces the `5.3` floor transitively, so the explicit
`Rokt-Widget` line is not required to prevent `5.2.x`. Declaring it keeps the
floor visible in the Podfile and forces a resolve even when an existing
`Podfile.lock` still holds a `5.2.x` build.

Do not add `Rokt-Widget` to this React Native wrapper's podspec — apps receive
it through `mParticle-Rokt`.

`Rokt-Widget` `5.3` resolves `RoktUXHelper` `1.0.0`, which requires an exact
`DcuiSchema` version. Remove any `DcuiSchema` pin (for example the previously
recommended `2.7.0`), otherwise CocoaPods reports conflicting `DcuiSchema`
requirements.

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
