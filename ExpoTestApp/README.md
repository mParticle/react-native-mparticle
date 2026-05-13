# mParticle Expo Test App

This app tests the Expo config plugin integration for the mParticle React Native SDK.

## Setup

1. First, build and pack the main library:

   ```bash
   cd ..
   yarn install
   yarn dev:pack
   ```

2. Install dependencies in the test app:

   ```bash
   cd ExpoTestApp
   npm install
   ```

3. Update the API keys in `app.json`:

   ```json
   {
     "expo": {
       "plugins": [
         [
           "expo-build-properties",
           {
             "ios": {
               "deploymentTarget": "15.6"
             }
           }
         ],
         [
           "react-native-mparticle",
           {
             "iosApiKey": "YOUR_IOS_API_KEY",
             "iosApiSecret": "YOUR_IOS_API_SECRET",
             "androidApiKey": "YOUR_ANDROID_API_KEY",
             "androidApiSecret": "YOUR_ANDROID_API_SECRET",
             "logLevel": "verbose",
             "environment": "development",
             "iosCustomBaseURL": "https://cname.example.com",
             "iosKits": ["mParticle-Rokt"],
             "androidKits": ["android-rokt-kit"]
           }
         ]
       ]
     }
   }
   ```

## Running the App

### iOS

```bash
npm run prebuild
npm run ios
```

### Android

```bash
npm run prebuild
npm run android
```

## Testing

The app provides buttons to test various mParticle SDK functionality:

### Core mParticle Features

- **Log Event**: Logs a custom event with the specified name
- **Log Screen**: Logs a screen view event
- **Log Commerce**: Logs a commerce event (add to cart)
- **Identify**: Identifies a test user
- **Get User**: Gets the current user
- **Set Attribute**: Sets a user attribute
- **Check Opt-Out**: Checks the current opt-out status

### Rokt Placements

The app also includes Rokt placement testing via the mParticle Rokt kit:

- **Embedded**: Loads an embedded Rokt placement that renders in-line within the app content. The placement appears in the designated placeholder area below the buttons.
- **Overlay**: Loads a full-screen overlay Rokt placement that appears on top of the app content.
- **Bottom Sheet**: Loads a bottom sheet Rokt placement that slides up from the bottom of the screen.
- **Shoppable Ads**: Calls `MParticle.Rokt.selectShoppableAds` with a staging placement identifier and checkout-style attributes (see implementation guide below).
- **Close Rokt**: Calls `MParticle.Rokt.close()`.
- **Rokt Session**: Calls `MParticle.Rokt.setSessionId()` and `MParticle.Rokt.getSessionId()`.

The Rokt section also demonstrates:

- Platform-specific attributes (iOS vs Android configurations)
- Rokt event listeners for callbacks and placement events
- Using `RoktLayoutView` as an embedded placeholder component

### Implementation guide: Shoppable Ads (`selectShoppableAds`) and iOS payment extensions

This mirrors the recent SDK work (Shoppable Ads API on iOS and the Expo test app wiring) and how to pair it with native payment registration.

#### JavaScript: `selectShoppableAds`

Use `MParticle.Rokt.selectShoppableAds(identifier, attributes, roktConfig?)` when you need the Shoppable Ads experience instead of `selectPlacements`.

- **identifier**: Rokt page / placement identifier configured for your account (the Expo test app uses a staging example such as `StgRoktShoppableAds`; replace with your production identifier).
- **attributes**: String key/value pairs passed to Rokt (shipping, billing, payment hints, sandbox flags, etc.). The demo in `App.tsx` includes fields like `country`, `shippingstate`, `paymenttype`, `stripeApplePayAvailable`, `applePayCapabilities`, and `sandbox`—adjust to match your integration and Rokt’s attribute contract.
- **roktConfig**: Optional; the demo uses `MParticle.Rokt.createRoktConfig('system')` for color mode. Add a cache config if you use caching elsewhere.

Example (same pattern as `ExpoTestApp/App.tsx`):

```javascript
const config = MParticle.Rokt.createRoktConfig('system');

MParticle.Rokt.selectShoppableAds('YOUR_PLACEMENT_ID', attributes, config)
  .then(() => {
    /* success */
  })
  .catch(error => {
    /* handle */
  });
```

Listen for `RoktCallback` and `RoktEvents` on `RoktEventManager` to observe load/unload and Shoppable Ads–related events emitted by the native bridge.

**Android:** `selectShoppableAds` is not implemented on Android yet; the native module logs a warning and does not run the Shoppable Ads flow. Plan for iOS-only behavior until Android support ships.

#### iOS native: `RoktPaymentExtension` (payment extensions)

Shoppable Ads flows that use Apple Pay expect a **payment extension** to be registered on mParticle’s Rokt interface after the SDK starts.

In `ios/MParticleExpoTest/AppDelegate.swift`, the test app:

1. Installs the Rokt kit with `iosKits`: `["mParticle-Rokt"]` or, manually, `pod 'mParticle-Rokt', '~> 9.2'`.
2. Imports the payment extension module: `import RoktPaymentExtension`.
3. After `MParticle.sharedInstance().start(with: mParticleOptions)`, constructs `RoktPaymentExtension(applePayMerchantId: "...")` with your **Apple Pay merchant ID** (replace `merchant.dummy` with your real `merchant.*` identifier from Apple Developer).
4. Registers it: `MParticle.sharedInstance().rokt.registerPaymentExtension(paymentExtension)`.

```swift
import RoktPaymentExtension

// After MParticle.sharedInstance().start(with: mParticleOptions):
if let paymentExtension = RoktPaymentExtension(applePayMerchantId: "merchant.your.id") {
  MParticle.sharedInstance().rokt.registerPaymentExtension(paymentExtension)
}
```

**Important:**

- The Expo config plugin **does not** generate the payment extension block today. After `expo prebuild`, add or merge this code into `AppDelegate.swift` (inside the same app launch path as mParticle init). If you regenerate native projects with `--clean`, re-apply this snippet.
- Use `iosKits`: `["mParticle-Rokt"]` for standard Rokt placements. Add `RoktPaymentExtension` to `iosKits` only when you are wiring the native payment extension registration.
- In manually managed iOS apps, use `pod 'mParticle-Rokt', '~> 9.2'` for standard placements and add `pod 'RoktPaymentExtension', '~> 2.0'` for the payment-extension install path.

#### URL callback forwarding

Forward redirect URLs to Rokt from native iOS URL handlers before other linking handlers. This is intentionally not exposed as a React Native JavaScript API because iOS payment-extension redirects must be handled synchronously from the OS URL callback.

The Expo config plugin injects this AppDelegate forwarding when `iosKits` includes `["mParticle-Rokt"]` and the generated AppDelegate uses Expo's standard URL handler. Verify the generated AppDelegate after `npm run prebuild` if your app has custom URL handling.

Swift `AppDelegate`:

```swift
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
  if MParticle.sharedInstance().rokt.handleURLCallback(with: url) {
    return true
  }

  return RCTLinkingManager.application(app, open: url, options: options)
}
```

SwiftUI:

```swift
WindowGroup {
  ContentView()
    .onOpenURL { url in
      _ = MParticle.sharedInstance().rokt.handleURLCallback(with: url)
    }
}
```

Swift `SceneDelegate`:

```swift
func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
  guard let url = URLContexts.first?.url else {
    return
  }

  if MParticle.sharedInstance().rokt.handleURLCallback(with: url) {
    return
  }

  RCTLinkingManager.application(UIApplication.shared, open: url, options: [:])
}
```

All activity is logged in the Activity Log section at the bottom of the screen.

## Verifying Plugin Integration

After running `npm run prebuild`, you can verify the plugin worked correctly:

### Verify iOS Integration

#### Swift AppDelegate (Expo SDK 53+)

Check `ios/MParticleExpoTest/AppDelegate.swift` for:

- Import statement:

  ```swift
  import mParticle_Apple_SDK
  ```

- Rokt URL callback forwarding when `iosKits` includes `mParticle-Rokt`:

  ```swift
  if MParticle.sharedInstance().rokt.handleURLCallback(with: url) {
    return true
  }
  ```

- MParticleOptions initialization in `didFinishLaunchingWithOptions`:

  ```swift
  let mParticleOptions = MParticleOptions(key: "YOUR_IOS_API_KEY", secret: "YOUR_IOS_API_SECRET")
  mParticleOptions.logLevel = .verbose
  mParticleOptions.environment = .development
  let identifyRequest = MPIdentityApiRequest.withEmptyUser()
  mParticleOptions.identifyRequest = identifyRequest
  let networkOptions = MPNetworkOptions()
  networkOptions.customBaseURL = URL(string: "https://cname.example.com")
  mParticleOptions.networkOptions = networkOptions
  MParticle.sharedInstance().start(with: mParticleOptions)
  ```

For Shoppable Ads with Apple Pay, you may also need to register `RoktPaymentExtension` after `start` - see **Implementation guide: Shoppable Ads (`selectShoppableAds`) and iOS payment extensions** above.

#### Objective-C AppDelegate (Legacy)

For older Expo SDK versions, check `ios/MParticleExpoTest/AppDelegate.mm` for:

- Import statement:

  ```objc
  #import "mParticle.h"
  ```

- MParticleOptions initialization:

  ```objc
  MParticleOptions *mParticleOptions = [MParticleOptions optionsWithKey:@"YOUR_IOS_API_KEY"
                                                                 secret:@"YOUR_IOS_API_SECRET"];
  mParticleOptions.logLevel = MPILogLevelVerbose;
  mParticleOptions.environment = MPEnvironmentDevelopment;
  MPIdentityApiRequest *identifyRequest = [MPIdentityApiRequest requestWithEmptyUser];
  mParticleOptions.identifyRequest = identifyRequest;
  MPNetworkOptions *networkOptions = [[MPNetworkOptions alloc] init];
  networkOptions.customBaseURL = [NSURL URLWithString:@"https://cname.example.com"];
  mParticleOptions.networkOptions = networkOptions;
  [[MParticle sharedInstance] startWithOptions:mParticleOptions];
  ```

#### Podfile

Check `ios/Podfile` for:

- pre_install hook for mParticle dynamic framework linking:

  ```ruby
  pre_install do |installer|
    installer.pod_targets.each do |pod|
      if pod.name == 'mParticle-Apple-SDK' || pod.name == 'mParticle-Apple-SDK-ObjC' || pod.name == 'mParticle-Apple-SDK-Swift' || pod.name == 'mParticle-Rokt' || pod.name == 'RoktPaymentExtension' || pod.name == 'Rokt-Widget' || pod.name == 'RoktContracts'
        def pod.build_type;
          Pod::BuildType.new(:linkage => :dynamic, :packaging => :framework)
        end
      end
    end
  end
  ```

- Kit pods (if specified):

  ```ruby
  pod 'mParticle-Rokt', '~> 9.2'
  ```

### Verify Android Integration

#### Kotlin MainApplication (Expo SDK 53+)

Check `android/app/src/main/java/.../MainApplication.kt` for:

- Import statements:

  ```kotlin
  import com.mparticle.MParticle
  import com.mparticle.MParticleOptions
  import com.mparticle.identity.IdentityApiRequest
  ```

- MParticleOptions initialization in `onCreate()`:

  ```kotlin
  val mParticleOptions = MParticleOptions.builder(this)
      .credentials("YOUR_ANDROID_API_KEY", "YOUR_ANDROID_API_SECRET")
      .logLevel(MParticle.LogLevel.VERBOSE)
      .environment(MParticle.Environment.Development)
      .identify(IdentityApiRequest.withEmptyUser().build())
      .build()
  MParticle.start(mParticleOptions)
  ```

#### Java MainApplication (Legacy)

For older Expo SDK versions, check `android/app/src/main/java/.../MainApplication.java` for:

- Import statements:

  ```java
  import com.mparticle.MParticle;
  import com.mparticle.MParticleOptions;
  import com.mparticle.identity.IdentityApiRequest;
  ```

- MParticleOptions initialization:

  ```java
  MParticleOptions.Builder optionsBuilder = MParticleOptions.builder(this)
      .credentials("YOUR_ANDROID_API_KEY", "YOUR_ANDROID_API_SECRET")
      .logLevel(MParticle.LogLevel.VERBOSE)
      .environment(MParticle.Environment.Development)
      .identify(IdentityApiRequest.withEmptyUser().build());
  MParticle.start(optionsBuilder.build());
  ```

#### build.gradle

Check `android/app/build.gradle` for kit dependencies (if specified):

```gradle
dependencies {
    // mParticle kits
    implementation "com.mparticle:android-rokt-kit:+"
}
```

## Plugin Configuration Options

| Option                    | Type     | Description                                               |
| ------------------------- | -------- | --------------------------------------------------------- |
| `iosApiKey`               | string   | mParticle iOS API key                                     |
| `iosApiSecret`            | string   | mParticle iOS API secret                                  |
| `androidApiKey`           | string   | mParticle Android API key                                 |
| `androidApiSecret`        | string   | mParticle Android API secret                              |
| `logLevel`                | string   | Log level: `none`, `error`, `warning`, `debug`, `verbose` |
| `environment`             | string   | Environment: `development`, `production`, `autoDetect`    |
| `useEmptyIdentifyRequest` | boolean  | Initialize with empty identify request (default: true)    |
| `dataPlanId`              | string   | Data plan ID for validation                               |
| `dataPlanVersion`         | number   | Data plan version                                         |
| `iosKits`                 | string[] | iOS kit pod names (e.g., `["mParticle-Rokt"]`)            |
| `iosCustomBaseURL`        | string   | iOS custom base URL for global CNAME setup                |
| `androidKits`             | string[] | Android kit dependencies (e.g., `["android-rokt-kit"]`)   |
