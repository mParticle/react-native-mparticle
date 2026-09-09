# Migration Guides

This document provides migration guidance for changes in `react-native-mparticle`.

## Migrating from versions < 3.0.0

`3.0.0` moved iOS to the mParticle Apple SDK **9.x**. Later 3.x releases raised
the Android floor to mParticle Android SDK **6.x** (`3.3.0`) and the Rokt iOS
floor to **5.3** (`3.3.2`). Going from 2.9.x to the current release takes all
three at once.

### Every app

#### React Native 0.76 or newer is required

3.x declares it as a peer dependency.

### iOS

#### iOS deployment target raised to 15.6

The podspec now declares `ios 15.6` / `tvos 15.6`, above React Native's own
`min_ios_version_supported` (15.1), so set it explicitly in `ios/Podfile` —
along with any app target or extension pinned lower:

```ruby
platform :ios, '15.6'
```

Expo apps set the same value through `expo-build-properties`; the mParticle
config plugin does not set it:

```json
["expo-build-properties", { "ios": { "deploymentTarget": "15.6" } }]
```

#### Apple SDK split into ObjC and Swift pods

9.0 split `mParticle-Apple-SDK` into `mParticle-Apple-SDK-ObjC` (module
`mParticle_Apple_SDK_ObjC`) and `mParticle-Apple-SDK-Swift`. This wrapper now
depends on the ObjC pod plus `RoktContracts`, so:

- Remove any 8.x `pod 'mParticle-Apple-SDK'` pin, any `pod 'Rokt-Widget'`, and
  any `DcuiSchema` pin — a stale `DcuiSchema` pin makes CocoaPods report
  conflicting requirements.
- For Rokt, declare `pod 'mParticle-Rokt', '>= 9.3.1', '< 10.0'`.
- Delete `ios/Podfile.lock` or run `pod update`, so it does not hold 8.x pods or
  an older Rokt iOS build.
- Widen the `pre_install` dynamic-framework exception to the new pod names — a
  list carried over from 2.x links the split and Rokt pods statically, which can
  fail to build:

```ruby
pre_install do |installer|
  installer.pod_targets.each do |pod|
    if ['mParticle-Apple-SDK', 'mParticle-Apple-SDK-ObjC',
        'mParticle-Apple-SDK-Swift', 'mParticle-Rokt', 'Rokt-Widget',
        'RoktContracts', 'RoktUXHelper', 'DcuiSchema'].include?(pod.name)
      def pod.build_type;
        Pod::BuildType.new(:linkage => :dynamic, :packaging => :framework)
      end
    end
  end
end
```

The Expo config plugin generates this list, including the transitive Rokt pods,
when `iosKits` is set — but it skips the hook entirely if your Podfile already
mentions `mParticle-Apple-SDK`, which is exactly the case when upgrading. Check
the generated Podfile rather than assuming the list was refreshed.

#### `mParticle-Apple-SDK` is now an umbrella pod

`mParticle-Apple-SDK` is now a thin, Swift-only umbrella over
`mParticle-Apple-SDK-ObjC`, installed only when something declares it —
`mParticle-Rokt` 9.x does, this wrapper does not. Without a kit:

- **Swift**: `import mParticle_Apple_SDK` stops resolving. Add
  `pod 'mParticle-Apple-SDK', '>= 9.2.2', '< 10.0'`, or import
  `mParticle_Apple_SDK_ObjC` instead.
- **Objective-C**: `#import <mParticle_Apple_SDK/mParticle.h>` stops resolving,
  and the umbrella pod does not bring it back — it ships no headers. Import
  `<mParticle_Apple_SDK_ObjC/mParticle.h>` instead.

(`mParticle_Apple_SDK_NoLocation` no longer exists in 9.x.)

This bites Expo apps with a Swift AppDelegate hardest: the config plugin writes
`import mParticle_Apple_SDK` but never declares the umbrella pod, so an Expo app
configured without `iosKits` generates code that does not compile. Objective-C
AppDelegates are unaffected — the plugin writes `#import "mParticle.h"` there,
which resolves from the ObjC pod.

#### Fabric dependency provider must be set

Required from React Native 0.77, which is where `RCTAppDependencyProvider` was
introduced. On 0.76 third-party Fabric components are still registered without
it, so this step does not apply. Easy to miss because it fails at runtime rather
than at build time: without it no third-party Fabric component is registered, so
`<RoktLayoutView>` mounts as `RCTUnimplementedViewComponentView` and embedded
placements never appear.

```objective-c
#import <ReactAppDependencyProvider/RCTAppDependencyProvider.h>

// in application:didFinishLaunchingWithOptions:
self.dependencyProvider = [RCTAppDependencyProvider new];
```

#### Removed AppDelegateProxy

If your app handles push or deep links, you must now forward the delegate
callbacks yourself. Apple SDK 9.0 removed `AppDelegateProxy`, which used to
intercept `UIApplicationDelegate` messages automatically, and nothing in this
wrapper replaces it. Apps that already set `proxyAppDelegate = NO` need no new
forwarding, but must still delete the assignment — 9.0 removed the property, so
leaving it in place fails to compile. See [Removed AppDelegateProxy](https://github.com/mParticle/mparticle-apple-sdk/blob/main/MIGRATING.md#removed-appdelegateproxy)
and [Removed Deprecated UIApplicationDelegate Methods](https://github.com/mParticle/mparticle-apple-sdk/blob/main/MIGRATING.md#removed-deprecated-uiapplicationdelegate-methods)
in the Apple SDK migration guide for the replacements. `logPushRegistration()`
from JavaScript is unaffected.

### Android

#### Rokt API moved from `android-core` to `android-rokt-kit`

The Rokt API surface moved out of `android-core` into `android-rokt-kit`, which
this wrapper declares `compileOnly`. A 2.x app that reached Rokt through
`android-core` alone still compiles and installs, then throws on the first
`MParticle.Rokt.*` call — the most likely silent breakage in this upgrade.

```gradle
implementation "com.mparticle:android-core:[6.0.0, 7.0)"
// required for MParticle.Rokt.* and RoktLayoutView
implementation "com.mparticle:android-rokt-kit:[6.0.0, 7.0)"
```

`android-rokt-kit` requires `compileSdk` 35+ and Android Gradle Plugin 8.6+.
With the Expo config plugin, list the kit in `androidKits` instead. This wrapper
declares `android-core` as `[6.0.1, 7.0)`, so core resolves `6.0.1` or newer
regardless; the kit is `compileOnly` here, so its version is entirely yours to
choose.

Android SDK 6.0.0 also removed several `android-core` APIs. If your
`MainApplication` or a native module calls the core SDK directly, check it
against [Migrating from versions < 6.0.0](https://github.com/mParticle/mparticle-android-sdk/blob/main/MIGRATING.md#migrating-from-versions--600)
in the Android SDK migration guide. Code that only goes through this wrapper's
JavaScript API needs no change.

### Behavior changes to check in your own code

- **`MParticle.setLocation(latitude, longitude)` is a no-op on iOS.** Apple SDK
  9 removed location support; it still works on Android. The unrelated
  `setLocation()` builders on GDPR and CCPA consent are unchanged.
- **`CommerceEvent.createProductActionEvent()` no longer fabricates transaction
  attributes.** 2.x defaulted the third argument to
  `new TransactionAttributes('')`, sending an empty transaction ID on every
  product-action event. Pass one explicitly if an integration relied on it.
- **`RoktLayoutView` sizes itself differently** — `alignSelf: 'stretch'` plus the
  measured height, rather than `flex: 1`, which collapsed placements to zero
  height inside auto-height column parents. It also no longer applies
  placement-reported margins. Give the surrounding container explicit dimensions
  if your layout depended on either.
- **`MParticle.Rokt.*` throws when the native kit is missing**, with an
  `RNMPRokt is unavailable` error, instead of the undefined-property error 2.x
  produced.
- **Queued events can be dropped once, on the first launch after upgrading** —
  but only if your `Podfile.lock` held an Apple SDK older than 8.27.0 (September
  2024), since 9.x dropped migration from those database versions. Identity and
  session state re-establish on the next launch. Most 2.9.x apps resolved a
  newer 8.x and are unaffected.

### New in 3.x

- `MParticle.Rokt.selectShoppableAds(identifier, attributes, roktConfig?)` — iOS
  only; a no-op on Android.
- `MParticle.Rokt.close()`, `setSessionId()`, `getSessionId()`.
- Device-based consent: `setDeviceConsentState()`, `getDeviceConsentState()`,
  `clearDeviceConsentState()`.
- `null` custom attribute values, normalized to an empty string before they
  reach the native layer.
- `customBaseUrl` and `pinningDisabled` options in the Expo config plugin.

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

## Migrating to mParticle-Rokt 9.3.1+ (Rokt iOS 5.3 floor)

This update aligns the React Native wrapper with `mParticle-Rokt` **9.3.1+**,
which requires `Rokt-Widget` `~> 5.3` (and `RoktContracts` `~> 2.0`), so the
Rokt iOS floor is enforced by the kit's own dependency graph rather than only by
an app-level pin. `9.3.0` is excluded because it still allows `Rokt-Widget`
`~> 5.2`.

### Dependency Changes

For standard Rokt placements on iOS, use:

```ruby
pod 'mParticle-Rokt', '>= 9.3.1', '< 10.0'
```

Do not add `Rokt-Widget` yourself — apps receive it through `mParticle-Rokt`.
Run `pod update` so an existing `Podfile.lock` does not hold an older Rokt iOS
build.

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

The plugin pins generated `mParticle-Rokt` pods to `>= 9.3.1, < 10.0`. It does
not add payment-extension pods or URL callback forwarding in this release.

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
