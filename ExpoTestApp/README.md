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
           "react-native-mparticle",
           {
             "iosApiKey": "YOUR_IOS_API_KEY",
             "iosApiSecret": "YOUR_IOS_API_SECRET",
             "androidApiKey": "YOUR_ANDROID_API_KEY",
             "androidApiSecret": "YOUR_ANDROID_API_SECRET",
             "logLevel": "verbose",
             "environment": "development",
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

#### iOS native: `RoktStripePaymentExtension` (payment extensions)

Shoppable Ads flows that use Apple Pay / Stripe integration expect a **payment extension** to be registered on mParticle’s Rokt interface after the SDK starts.

In `ios/MParticleExpoTest/AppDelegate.swift`, the test app:

1. Imports the Stripe payment extension module provided with the Rokt / kit stack: `import RoktStripePaymentExtension`.
2. After `MParticle.sharedInstance().start(with: mParticleOptions)`, constructs `RoktStripePaymentExtension(applePayMerchantId: "...")` with your **Apple Pay merchant ID** (replace `merchant.dummy` with your real `merchant.*` identifier from Apple Developer).
3. Registers it: `MParticle.sharedInstance().rokt.register(paymentExtension)`.

```swift
import RoktStripePaymentExtension

// After MParticle.sharedInstance().start(with: mParticleOptions):
if let paymentExtension = RoktStripePaymentExtension(applePayMerchantId: "merchant.your.id") {
  MParticle.sharedInstance().rokt.register(paymentExtension)
}
```

**Important:**

- The Expo config plugin **does not** generate the payment extension block today. After `expo prebuild`, add or merge this code into `AppDelegate.swift` (inside the same app launch path as mParticle init). If you regenerate native projects with `--clean`, re-apply this snippet.
- Ensure the **mParticle Rokt kit** (and transitive Rokt dependencies) are installed so `RoktStripePaymentExtension` resolves—same as configuring `iosKits`: `["mParticle-Rokt"]` in `app.json`.

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

- MParticleOptions initialization in `didFinishLaunchingWithOptions`:

  ```swift
  let mParticleOptions = MParticleOptions(key: "YOUR_IOS_API_KEY", secret: "YOUR_IOS_API_SECRET")
  mParticleOptions.logLevel = .verbose
  mParticleOptions.environment = .development
  let identifyRequest = MPIdentityApiRequest.withEmptyUser()
  mParticleOptions.identifyRequest = identifyRequest
  MParticle.sharedInstance().start(with: mParticleOptions)
  ```

For Shoppable Ads with Apple Pay / Stripe, you may also need to register `RoktStripePaymentExtension` after `start`—see **Implementation guide: Shoppable Ads (`selectShoppableAds`) and iOS payment extensions** above.

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
  [[MParticle sharedInstance] startWithOptions:mParticleOptions];
  ```

#### Podfile

Check `ios/Podfile` for:

- pre_install hook for mParticle dynamic framework linking:

  ```ruby
  pre_install do |installer|
    installer.pod_targets.each do |pod|
      if pod.name == 'mParticle-Apple-SDK' || pod.name == 'mParticle-Rokt' || pod.name == 'Rokt-Widget'
        def pod.build_type;
          Pod::BuildType.new(:linkage => :dynamic, :packaging => :framework)
        end
      end
    end
  end
  ```

- Kit pods (if specified):

  ```ruby
  pod 'mParticle-Rokt'
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
| `androidKits`             | string[] | Android kit dependencies (e.g., `["android-rokt-kit"]`)   |
