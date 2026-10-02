# react-native-mparticle

[![npm version](https://badge.fury.io/js/react-native-mparticle.svg)](https://badge.fury.io/js/react-native-mparticle)
[![Standard - JavaScript Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](http://standardjs.com/)

React Native allows developers to use a single code base to deploy features to multiple platforms. With the mParticle React Native library, you can leverage a single API to deploy your data to hundreds of integrations from your iOS and Android apps.

### Supported Features

| Method        | Android | iOS |
| ------------- | ------- | --- |
| Custom Events | ✓       | ✓   |
| Page Views    | ✓       | ✓   |
| Identity      | ✓       | ✓   |
| eCommerce     | ✓       | ✓   |
| Consent       | ✓       | ✓   |
| Rokt          | ✓       | ✓   |

# Installation

**Download and install the mParticle React Native library** from npm:

```bash
npm install react-native-mparticle --save
```

## Expo

This library supports Expo projects using the [Expo Config Plugin](https://docs.expo.dev/config-plugins/introduction/). The plugin automatically configures the native iOS and Android projects during `expo prebuild`.

### Installation - Expo

1. Install the library:

```bash
npx expo install react-native-mparticle
```

2. Add the plugin to your `app.json` or `app.config.js`:

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
          "androidApiSecret": "YOUR_ANDROID_API_SECRET"
        }
      ]
    ]
  }
}
```

**Also set the iOS deployment target.** `react-native-mparticle.podspec` requires iOS 15.6 — above React Native's own floor of 15.1 — and this plugin does not set it, so add `expo-build-properties` alongside it (see `ExpoTestApp/app.json`):

```json
["expo-build-properties", { "ios": { "deploymentTarget": "15.6" } }]
```

**With `iosDependencyManager: 'cocoapods'` and no `iosKits`, declare the umbrella pod.** Swift Package Manager, the default, always links the core SDK, so this applies only to CocoaPods. On a Swift AppDelegate (Expo SDK 53+) the plugin writes `import mParticle_Apple_SDK`, but nothing installs that pod on its own: this library depends on `mParticle-Apple-SDK-ObjC`, and the umbrella arrives transitively only with a kit (`mParticle-Rokt` depends on `mParticle-Apple-SDK`). Without a kit, add `pod 'mParticle-Apple-SDK', '>= 9.2.2', '< 10.0'` to the generated `ios/Podfile`, and re-apply it after any `expo prebuild --clean`, which rewrites that file. Objective-C templates get `#import "mParticle.h"` instead, which resolves without the umbrella.

3. Run prebuild:

```bash
npx expo prebuild --clean
```

4. Run the app:

```bash
npx expo run:ios
# or
npx expo run:android
```

### Plugin Configuration Options

| Option                    | Type     | Required | Description                                                                                                      |
| ------------------------- | -------- | -------- | ---------------------------------------------------------------------------------------------------------------- |
| `iosApiKey`               | string   | Yes      | iOS API key from mParticle dashboard                                                                             |
| `iosApiSecret`            | string   | Yes      | iOS API secret from mParticle dashboard                                                                          |
| `androidApiKey`           | string   | Yes      | Android API key from mParticle dashboard                                                                         |
| `androidApiSecret`        | string   | Yes      | Android API secret from mParticle dashboard                                                                      |
| `logLevel`                | string   | No       | Log level: `'none'`, `'error'`, `'warning'`, `'debug'`, `'verbose'`                                              |
| `environment`             | string   | No       | Environment: `'development'`, `'production'`, `'autoDetect'`                                                     |
| `dataPlanId`              | string   | No       | Data plan ID for validation                                                                                      |
| `dataPlanVersion`         | number   | No       | Data plan version (ignored unless `dataPlanId` is also set)                                                      |
| `iosKits`                 | string[] | No       | iOS kits by CocoaPods name (e.g., `['mParticle-Rokt']`); see [kit names](#swift-package-manager)                 |
| `iosDependencyManager`    | string   | No       | `'spm'` (default) takes the iOS SDK and kits from Swift Package Manager; `'cocoapods'` is the deprecated opt-out |
| `iosSdkVersion`           | string   | No       | With `'spm'`, the exact mParticle core SDK version, also used for kits without a version                         |
| `iosSpmKits`              | object[] | No       | With `'spm'`, kits not in the kit list, as `{ url, product, version? }` Swift packages                           |
| `customBaseUrl`           | string   | No       | Custom base URL for global CNAME setup on iOS and Android; must be an absolute `https://` URL or prebuild fails  |
| `pinningDisabled`         | boolean  | No       | Disable SSL pinning (`MPNetworkOptions` on iOS; `setPinningDisabledInDevelopment` on Android)                    |
| `androidKits`             | string[] | No       | Android kit artifact names (e.g., `['android-rokt-kit']`)                                                        |
| `useEmptyIdentifyRequest` | boolean  | No       | Use empty user identify request at init (default: `true`)                                                        |

### Example with Kits

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
          "environment": "development",
          "logLevel": "verbose",
          "iosKits": ["mParticle-Rokt", "mParticle-Braze-14"],
          "androidKits": ["android-rokt-kit", "android-amplitude-kit"]
        }
      ]
    ]
  }
}
```

For global CNAME setup, add the optional shared `customBaseUrl` setting:

```json
{
  "customBaseUrl": "https://cname.example.com"
}
```

### Swift Package Manager (Expo)

The plugin takes the iOS mParticle SDK and kits from Swift Package Manager by default ([details](#swift-package-manager)). `iosKits` names are the CocoaPods names of the kits; list any kit that is not in the kit list in `iosSpmKits`, or prebuild fails with an error naming it.

```json
{
  "iosKits": ["mParticle-Rokt"]
}
```

Expo regenerates `ios/` on `expo prebuild --clean`, so there is no committed `Package.resolved`. Set `iosSdkVersion` to pin the core SDK (and kits without a version) exactly. The core SDK package is always linked, so `import mParticle_Apple_SDK` resolves without declaring the umbrella pod.

To stay on CocoaPods, which is deprecated, set `"iosDependencyManager": "cocoapods"`. When you switch `iosDependencyManager` in either direction, run `npx expo prebuild --clean`, so the previous mode's Podfile lines and Swift packages are not left behind.

### What the Plugin Does

**iOS:**

- Adds mParticle SDK initialization to `AppDelegate` (supports both Swift and Objective-C)
- Sets `MPNetworkOptions` (`customBaseURL` and/or `pinningDisabled`) before startup when those plugin options are configured
- Writes `$RNMParticleSPMKits` (and `$RNMParticleSPMCoreVersion` when `iosSdkVersion` is set) at the top of the Podfile. On `pod install`, this package links the core SDK and those kits into the app target as Swift packages pinned to exact versions
- With `iosDependencyManager: 'cocoapods'`, instead: sets `$RNMParticleDisableSPM = true`, configures a `pre_install` hook in the Podfile for dynamic framework linking, covering the kit's transitive pods (skipped if the Podfile already mentions `mParticle-Apple-SDK`), and adds the kit pods — `mParticle-Rokt` is pinned to `>= 9.3.1, < 10.0`, other kits are added unpinned

**Android:**

- Adds mParticle SDK initialization to `MainApplication` (supports both Kotlin and Java)
- Sets `NetworkOptions` (`setCustomBaseURL` and/or `setPinningDisabledInDevelopment`) before startup when those plugin options are configured
- Adds specified kit Maven dependencies to `build.gradle`

### Version Support

| Expo SDK | React Native | iOS AppDelegate | Android MainApplication |
| -------- | ------------ | --------------- | ----------------------- |
| 53+      | 0.79+        | Swift           | Kotlin                  |
| 52       | 0.76         | Objective-C++   | Kotlin                  |

`package.json` declares React Native `>= 0.76.0` as a peer dependency, so earlier Expo SDKs are below the supported floor. The plugin still contains Objective-C and Java generators for those older templates, but they are outside the supported range.

The plugin generates code for the language Expo reports — `swift`, `objc` or `objcpp` for the AppDelegate, `kt` or `java` for `MainApplication`. Anything else logs a warning and injects nothing.

---

## iOS (Manual Setup)

1. **Copy your mParticle key and secret** from [your app's dashboard][1].

[1]: https://app.mparticle.com/setup/inputs/apps

2. **Install the SDK.** React Native and this package install with CocoaPods, and the mParticle core SDK and its kits come from Swift Package Manager, linked into your app target ([details](#swift-package-manager)).

First, set the iOS deployment target to 15.6. `react-native-mparticle.podspec` declares `ios 15.6` / `tvos 15.6`, above React Native's own `min_ios_version_supported` (15.1), so set it explicitly in `ios/Podfile` — along with any app target or extension pinned lower:

```ruby
platform :ios, '15.6'
```

List your kits by CocoaPods name at the top of `ios/Podfile`, before any `target` block:

```ruby
$RNMParticleSPMKits = ['mParticle-Rokt']
```

Then run `bundle exec pod install`. It prints each Swift package it links, such as `[mParticle] MyApp <- mParticle-Rokt 9.6.1`; commit the `.xcodeproj` change and `Package.resolved`. Every CocoaPods linkage works, and no `pre_install` hook is needed. To take the SDKs from CocoaPods instead, see [CocoaPods (deprecated)](#cocoapods-deprecated).

3. Import and start the mParticle Apple SDK into Swift or Objective-C.

The mParticle SDK is initialized by calling the `startWithOptions` method within the `application:didFinishLaunchingWithOptions:` delegate call.

Preferably the location of the initialization method call should be one of the last statements in the `application:didFinishLaunchingWithOptions:`.

The `startWithOptions` method requires an options argument containing your key and secret and an initial Identity request.

> Note that you must initialize the SDK in the `application:didFinishLaunchingWithOptions:` method. Other parts of the SDK rely on the `UIApplicationDidBecomeActiveNotification` notification to function properly. Failing to start the SDK as indicated will impair it. Also, please do **not** use _GCD_'s `dispatch_async` to start the SDK.

For more help, see [the iOS set up docs](https://docs.mparticle.com/developers/sdk/ios/getting-started/#create-an-input).

> **React Native 0.77+ requires a Fabric dependency provider.** Set it in `application:didFinishLaunchingWithOptions:` before starting mParticle. Without it no third-party Fabric component is registered, so `<RoktLayoutView>` mounts as `RCTUnimplementedViewComponentView` and embedded placements never appear. This fails at runtime, not at build time. See `sample/ios/MParticleSample/AppDelegate.swift`.
>
> ```swift
> import ReactAppDependencyProvider
>
> let delegate = ReactNativeDelegate()
> delegate.dependencyProvider = RCTAppDependencyProvider()
>
> reactNativeDelegate = delegate
> reactNativeFactory = RCTReactNativeFactory(delegate: delegate)
> ```

> **With CocoaPods and no iOS kit, declare the umbrella pod.** Swift Package Manager, the default, always links the core SDK, so this applies only to [CocoaPods](#cocoapods-deprecated). `mParticle-Apple-SDK` is now a thin Swift umbrella over `mParticle-Apple-SDK-ObjC`, and this wrapper depends on the ObjC pod directly — so the umbrella is installed only when something else declares it, as `mParticle-Rokt` 9.x does. Without a kit, add `pod 'mParticle-Apple-SDK', '>= 9.2.2', '< 10.0'` (matching this library's own floor) for `import mParticle_Apple_SDK` to resolve, or import `mParticle_Apple_SDK_ObjC` instead.

#### Swift Example

```swift
import mParticle_Apple_SDK

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        //override point for customization after application launch.
        let mParticleOptions = MParticleOptions(key: "<<<App Key Here>>>", secret: "<<<App Secret Here>>>")

        //optional- Please see the Identity page for more information on building this object
        let request = MPIdentityApiRequest.withEmptyUser()
        request.email = "email@example.com"
        mParticleOptions.identifyRequest = request
        //optional
        mParticleOptions.onIdentifyComplete = { (apiResult, error) in
            NSLog("Identify complete. userId = %@ error = %@", apiResult?.user.userId.stringValue ?? "Null User ID", error?.localizedDescription ?? "No Error Available")
        }
        //optional
        mParticleOptions.onAttributionComplete = { (attributionResult, error) in
            print("Attribution complete. linkInfo = \(String(describing: attributionResult?.linkInfo))")
        }

        // Optional global CNAME setup. Configure before start.
        let networkOptions = MPNetworkOptions()
        networkOptions.customBaseURL = URL(string: "https://cname.example.com")
        mParticleOptions.networkOptions = networkOptions

        MParticle.sharedInstance().start(with: mParticleOptions)
        return true
}
```

#### Objective-C Example

Your import statement should be this:

```objective-c
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK_ObjC/mParticle.h>)
    #import <mParticle_Apple_SDK_ObjC/mParticle.h>
#else
    #import "mParticle.h"
#endif
```

Apple SDK 9 moved the Objective-C headers into the `mParticle_Apple_SDK_ObjC` module. The umbrella `mParticle-Apple-SDK` pod is Swift-only and ships no `mParticle.h`, so `<mParticle_Apple_SDK/mParticle.h>` no longer resolves.

Next, you'll need to start the SDK:

```objective-c
- (BOOL)application:(UIApplication *)application
        didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    MParticleOptions *mParticleOptions = [MParticleOptions optionsWithKey:@"REPLACE ME"
                                                                   secret:@"REPLACE ME"];

    //optional - Please see the Identity page for more information on building this object
    MPIdentityApiRequest *request = [MPIdentityApiRequest requestWithEmptyUser];
    request.email = @"email@example.com";
    mParticleOptions.identifyRequest = request;
    //optional
    mParticleOptions.onIdentifyComplete = ^(MPIdentityApiResult * _Nullable apiResult, NSError * _Nullable error) {
        NSLog(@"Identify complete. userId = %@ error = %@", apiResult.user.userId, error);
    };
    //optional
    mParticleOptions.onAttributionComplete = ^(MPAttributionResult * _Nullable attributionResult, NSError * _Nullable error) {
        NSLog(@"Attribution Complete. attributionResults = %@", attributionResult.linkInfo);
    };

    // Optional global CNAME setup. Configure before start.
    MPNetworkOptions *networkOptions = [[MPNetworkOptions alloc] init];
    networkOptions.customBaseURL = [NSURL URLWithString:@"https://cname.example.com"];
    mParticleOptions.networkOptions = networkOptions;

    [[MParticle sharedInstance] startWithOptions:mParticleOptions];

    return YES;
}
```

### Rokt iOS Setup

For standard Rokt placements, add the mParticle Rokt kit:

```ruby
$RNMParticleSPMKits = ['mParticle-Rokt']
```

With [CocoaPods](#cocoapods-deprecated), declare the pod instead: `pod 'mParticle-Rokt', '>= 9.3.1', '< 10.0'`. Kit `9.3.1` is the first release requiring `Rokt-Widget` `~> 5.3` (`9.3.0` still allows `~> 5.2`), so Rokt iOS resolves transitively from this floor — do not declare `Rokt-Widget` yourself.

In Expo apps, use `iosKits: ["mParticle-Rokt"]` for standard Rokt placements. With `iosDependencyManager: 'cocoapods'`, the Expo plugin pins `mParticle-Rokt` to `>= 9.3.1, < 10.0`. It does not add payment-extension pods or URL callback forwarding in this release.

See [MIGRATING.md](./MIGRATING.md) for release-specific migration guidance.

For Android Rokt integrations, including `MParticle.Rokt.*` APIs and
`RoktLayoutView`, `android-core` and `android-rokt-kit` `6.0.1` or newer are
required — that is the range this library compiles against. Apps that include
`android-rokt-kit` must build with `compileSdk` 35+ and Android Gradle Plugin
8.6+. Android CNAME setup through `customBaseUrl` also requires `android-core`
`6.0.1` or newer.

See [Identity](http://docs.mparticle.com/developers/sdk/ios/identity/) for more information on supplying an `MPIdentityApiRequest` object during SDK initialization.

4. Remember to start Metro with:

```bash
npm start
```

and build your workspace from xCode.

### Swift Package Manager

This package takes the mParticle SDKs from Swift Package Manager by default. React Native and this package still install with CocoaPods, but the mParticle core SDK and its kits are Swift packages linked into your app target. CocoaPods trunk becomes read-only on 2 December 2026 ([announcement](https://blog.cocoapods.org/CocoaPods-Specs-Repo/)), so taking the SDKs from CocoaPods is [deprecated](#cocoapods-deprecated). iOS only: a Podfile with a tvOS target that uses this package must opt out, for the whole Podfile.

Every mParticle and Rokt SDK must come from Swift Package Manager, and none from CocoaPods. If the core comes from one and a kit from the other, the app contains two copies of the SDK: it builds and archives without warnings, then crashes at runtime.

**Podfile settings.** Both are optional. Set them at the top of `ios/Podfile`, before any `target` block, which is where this package's podspec is evaluated:

```ruby
$RNMParticleSPMKits = ['mParticle-Rokt', 'mParticle-Braze-14']
$RNMParticleSPMCoreVersion = '9.6.1'
```

- `$RNMParticleSPMKits` lists kits by CocoaPods name. [`ios/mparticle_spm_kits.json`](./ios/mparticle_spm_kits.json) maps every kit of the mParticle Apple SDK to its Swift package, including `mParticle-Kochava-9` and `mParticle-Kochava-No-Tracking-9`, which ship only as Swift packages, and `RoktSDKPlus`, which already includes `mParticle-Rokt`. For any other kit, give `{ url: '…', product: '…', version: '…' }`.
- `$RNMParticleSPMCoreVersion` pins the core SDK. It defaults to the version this release was tested with. A kit without a version gets the core's, since mParticle kits are released with the core.

**What `pod install` changes.** On each `pod install`, this package edits your app's `.xcodeproj`: it adds a Swift package reference for the core SDK and each kit, pinned to the exact version, and links each package's product into every iOS application target that uses this package. It prints every change (`[mParticle] MyApp <- mParticle-Rokt 9.6.1`), and running it again changes nothing. It stops `pod install` with an error if a pod would add a second copy of the SDKs. Commit the `.xcodeproj` change and `ios/<App>.xcworkspace/xcshareddata/swiftpm/Package.resolved`, so every build resolves the same versions.

**Linkage.** This package's pod is always built as a static framework, so it works with each CocoaPods linkage:

| Podfile linkage                         | Supported |
| --------------------------------------- | --------- |
| Static libraries (React Native default) | ✓         |
| `use_frameworks! :linkage => :static`   | ✓         |
| `use_frameworks! :linkage => :dynamic`  | ✓         |

**Troubleshooting.**

- `pod install` fails with `[mParticle] This package takes the mParticle SDKs from Swift Package Manager, but these pods would add a second copy`: remove the kit pods you declared, such as `pod 'mParticle-Rokt'`, and their entries in any `pre_install` hook, then list the kits in `$RNMParticleSPMKits`. The error also lists the pods those kits pull in. To stay on CocoaPods for now, set `$RNMParticleDisableSPM = true` instead.
- `pod install` fails with `[mParticle] $RNMParticleSPMKits: unknown kit`: use a name from `ios/mparticle_spm_kits.json`, or give the kit's `url:` and `product:`.
- `pod install` fails with `[mParticle] Swift Package Manager mode is iOS only`: a tvOS target uses this package. Set `$RNMParticleDisableSPM = true` at the top of the Podfile.
- The build fails with `[mParticle] Swift Package Manager mode is on, but the mParticle-Apple-SDK Swift package is not linked into the app target`: the package was removed from the app target after `pod install`. Run `pod install` again.
- A Debug build shows the red box `[mParticle] The mParticle SDK is loaded more than once`: the SDK comes from both CocoaPods and Swift Package Manager. Remove the mParticle and Rokt pods and any Swift packages you added by hand, then run `pod install`.

### CocoaPods (deprecated)

To take the mParticle SDKs from CocoaPods instead, set this at the top of `ios/Podfile`, before any `target` block, and declare the kit pods, such as `pod 'mParticle-Rokt', '>= 9.3.1', '< 10.0'`:

```ruby
$RNMParticleDisableSPM = true
```

CocoaPods trunk becomes read-only on 2 December 2026, and a future release will remove this option. If the app target still links the mParticle Swift packages, `pod install` warns: remove them from the target, or the app contains two copies of the SDK. `ios/mparticle_spm_kits.json` marks the kits that have no pod.

Depending on your app and its other dependencies, integrate the pods in one of three ways.

A. Static Libraries are the React Native default, but the Apple SDK and the Rokt pods contain Swift code, so they need an exception in the form of a pre-install command in the Podfile. Apple SDK 9 split `mParticle-Apple-SDK` into `mParticle-Apple-SDK-ObjC` and `mParticle-Apple-SDK-Swift`, so the list covers both, plus the Rokt kit and its transitive pods:

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

With `iosDependencyManager: 'cocoapods'`, the Expo config plugin generates the same list, including the transitive Rokt pods, from `iosKits`; `sample/ios/Podfile` carries it for a bare app (`MP_USE_COCOAPODS=1`).

Then run the following command

```bash
bundle exec pod install
```

B&C. Frameworks are the default for Swift development and while it isn't preferred by React Native it is supported. Additionally you can define whether the frameworks are built staticly or dynamically.

This reads `USE_FRAMEWORKS` from the environment, so your Podfile needs the block that acts on it (see `sample/ios/Podfile`):

```ruby
linkage = ENV['USE_FRAMEWORKS']
if linkage != nil
  use_frameworks! :linkage => linkage.to_sym
end
```

Then run either of the following commands

```bash
USE_FRAMEWORKS=static bundle exec pod install
```

or

```bash
USE_FRAMEWORKS=dynamic bundle exec pod install
```

### Experimental: React Native Swift Package Manager mode

> **Not for production.** React Native's own Swift Package Manager mode (React Native 0.87 or later) is experimental, and so is this package's support for it. Use this package's default mode above, which installs React Native with CocoaPods, for apps you ship.

This package ships a `Package.swift`, so `npx react-native spm add` links it without a scaffolded manifest. The app target must also link the mParticle core SDK and each kit as Swift packages, for example in Xcode (File › Add Package Dependencies):

- `https://github.com/mParticle/mparticle-apple-sdk`, product `mParticle-Apple-SDK`
- `https://github.com/mparticle-integrations/mp-apple-integration-rokt`, product `mParticle-Rokt`

Use exactly these URLs, with no `.git` suffix on the first, so Swift Package Manager treats them as the same packages the kits depend on. Then start mParticle in your Swift `AppDelegate` with `import mParticle_Apple_SDK`, as in the CocoaPods setup.

## Android (Manual Setup)

1. Copy your mParticle key and secret from [your workspace's dashboard](https://app.mparticle.com/setup/inputs/apps) and construct an `MParticleOptions` object.

2. Call `start` from the `onCreate` method of your app's `Application` class. It's crucial that the SDK be started here for proper session management. If you don't already have an `Application` class, create it and then specify its fully-qualified name in the `<application>` tag of your app's `AndroidManifest.xml`.

For more help, see [the Android set up docs](https://docs.mparticle.com/developers/sdk/android/getting-started/#create-an-input).

```kotlin
package com.example.myapp

import android.app.Application
import com.mparticle.MParticle
import com.mparticle.MParticleOptions
import com.mparticle.networking.NetworkOptions

class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        val options: MParticleOptions = MParticleOptions.builder(this)
            .credentials("REPLACE ME WITH KEY", "REPLACE ME WITH SECRET")
            //optional
            .logLevel(MParticle.LogLevel.VERBOSE)
            //optional
            .identify(identifyRequest)
            //optional global CNAME setup
            .networkOptions(
                NetworkOptions.builder()
                    .setCustomBaseURL("https://cname.example.com")
                    .build()
            )
            //optional
            .identifyTask(
                BaseIdentityTask()
                    .addFailureListener { errorResponse -> }
                    .addSuccessListener{ result -> }
            )
            //optional
            .attributionListener(this)
            .build()
        MParticle.start(options)
    }
}
```

> **Warning:** Don't log events in your `Application.onCreate()`. Android may instantiate your `Application` class in the background without your knowledge, including when the user isn't using their device, and lead to unexpected results.

### Android Dependencies

This library exposes `com.mparticle:android-core` as an `api` dependency, so you don't have to declare it. `android-rokt-kit` is `compileOnly` here, so apps using `MParticle.Rokt.*` or `RoktLayoutView` must declare it themselves in `android/app/build.gradle`:

```gradle
implementation "com.mparticle:android-rokt-kit:[6.0.1, 7.0)"
```

With the Expo config plugin, list the kit in `androidKits` instead.

# Usage

## Import the mParticle Module

```js
import MParticle from 'react-native-mparticle';
```

## Logging Events

To log basic events:

```js
MParticle.logEvent('Test event', MParticle.EventType.Other, {
  'Test key': 'Test value',
});
```

To log commerce events:

```js
const product = new MParticle.Product('Test product for cart', '1234', 19.99);
const event = MParticle.CommerceEvent.createProductActionEvent(
  MParticle.ProductActionType.AddToCart,
  [product]
);

MParticle.logCommerceEvent(event);
```

Transaction attributes are optional for product actions such as AddToCart.
Purchase and Refund events must include `TransactionAttributes` with a unique
transaction ID.

```js
const transactionAttributes = new MParticle.TransactionAttributes(
  'Test transaction id'
).setRevenue(19.99);

const event = MParticle.CommerceEvent.createProductActionEvent(
  MParticle.ProductActionType.Purchase,
  [product],
  transactionAttributes
);

MParticle.logCommerceEvent(event);
```

```js
const promotion = new MParticle.Promotion(
  'Test promotion id',
  'Test promotion name',
  'Test creative',
  'Test position'
);
const event = MParticle.CommerceEvent.createPromotionEvent(
  MParticle.PromotionActionType.View,
  [promotion]
);

MParticle.logCommerceEvent(event);
```

```js
const product = new MParticle.Product(
  'Test product that was viewed',
  '5678',
  29.99
);
const impression = new MParticle.Impression('Test impression list name', [
  product,
]);
const event = MParticle.CommerceEvent.createImpressionEvent([impression]);

MParticle.logCommerceEvent(event);
```

To log screen events:

```js
MParticle.logScreenEvent('Test screen', { 'Test key': 'Test value' });
```

### Null Custom Attribute Values

Custom event and product attributes accept `null`. The React Native SDK
preserves an explicitly null attribute as an empty string on both platforms, so
`{ coupon_code: null }` appears as `{ coupon_code: "" }` in Live Stream. Omit
the key when the attribute should be absent.

Because `null` and `""` intentionally produce the same output, use a separate
boolean or status attribute when analytics must distinguish those states.

## Location

`setLocation` sets the location attached to subsequent events on Android. It is
a **no-op on iOS** — mParticle Apple SDK 9 removed location support — and logs a
notice instead.

```js
MParticle.setLocation(37.7749, -122.4194);
```

The `setLocation()` builders on GDPR and CCPA consent below are unrelated and
work on both platforms.

## User

`User` methods are instance methods. Get the current user from `Identity`, or
construct a `User` from an MPID you already hold. `getCurrentUser` always
invokes its callback with a `User`, so check `userId` before writing attributes
if identity may not have resolved yet:

```js
MParticle.Identity.getCurrentUser(currentUser => {
  currentUser.setUserAttribute('Test key', 'Test value');
  currentUser.setUserAttribute(
    MParticle.UserAttributeType.FirstName,
    'Test first name'
  );
  currentUser.setUserAttributeArray('Test key', [
    'Test value 1',
    'Test value 2',
  ]);
  currentUser.setUserTag('Test value');
  currentUser.incrementUserAttribute('Test key', 1);
  currentUser.removeUserAttribute('Test key');
});
```

```js
const user = new MParticle.User(mpid);
```

Reads are callback-based:

```js
MParticle.Identity.getCurrentUser(currentUser => {
  currentUser.getUserAttributes(attributes => console.debug(attributes));
  currentUser.getUserIdentities(userIdentities =>
    console.debug(userIdentities)
  );
  currentUser.getFirstSeen(firstSeen => console.debug(firstSeen));
  currentUser.getLastSeen(lastSeen => console.debug(lastSeen));
});
```

## IdentityRequest

```js
var request = new MParticle.IdentityRequest();
```

**Setting** user identities:

```js
var request = new MParticle.IdentityRequest();
request.setUserIdentity(
  'example@example.com',
  MParticle.UserIdentityType.Email
);
```

## Identity

```js
MParticle.Identity.getCurrentUser(currentUser => {
  console.debug(currentUser.userId); // or currentUser.getMpid()
});
```

```js
var request = new MParticle.IdentityRequest();

MParticle.Identity.identify(request, (error, userId) => {
  if (error) {
    console.debug(error); //error is an MParticleError
  } else {
    console.debug(userId);
  }
});
```

```js
var request = new MParticle.IdentityRequest();
request.email = 'test email';

MParticle.Identity.login(request, (error, userId) => {
  if (error) {
    console.debug(error); //error is an MParticleError
  } else {
    console.debug(userId);
  }
});
```

```js
var request = new MParticle.IdentityRequest();

MParticle.Identity.logout(request, (error, userId) => {
  if (error) {
    console.debug(error);
  } else {
    console.debug(userId);
  }
});
```

```js
var request = new MParticle.IdentityRequest();
request.email = 'test email 2';

MParticle.Identity.modify(request, (error, userId) => {
  if (error) {
    console.debug(error); //error is an MParticleError
  } else {
    console.debug(userId);
  }
});
```

## Attribution

```js
MParticle.getAttributions(attributionResults => {
  console.debug(attributionResults);
});
```

In order to listen for Attributions asynchronously, you need to set the proper field in `MParticleOptions` as shown in the [Android](#android-manual-setup) or the [iOS](#ios-manual-setup) SDK start examples.

## Kits

Check if a kit is active

```js
MParticle.isKitActive(kitId, isActive => {
  console.debug(isActive);
});
```

Check and set the SDK's opt out status

```js
MParticle.getOptOut(isOptedOut => {
  MParticle.setOptOut(!isOptedOut);
});
```

## Rokt

`MParticle.Rokt.*` needs the native Rokt kit (`mParticle-Rokt` on iOS,
`android-rokt-kit` on Android), and the platforms fail differently without it.
On Android the native module is not registered, so the placement and session
methods reject with `RNMPRokt is unavailable`. On iOS the module is always
registered, so those calls resolve and silently do nothing — watch the events
below to tell a missing kit from a placement that did not serve.

```js
const attributes = { email: 'user@example.com' };
const cacheConfig = MParticle.Rokt.createCacheConfig(30, attributes);
const config = MParticle.Rokt.createRoktConfig('system', cacheConfig);

MParticle.Rokt.selectPlacements(
  'MSDKOverlayLayout',
  attributes,
  undefined,
  config
);
```

`selectPlacements`, `selectShoppableAds` and `purchaseFinalized` resolve as soon
as the request reaches the native kit — they do not wait for the placement, so a
later native failure does not reject them. `close` and `setSessionId` do wait for
the native call, and `getSessionId` resolves with the current session ID (or
`null`), but no Rokt method reports success or failure through its promise —
watch the events below for the outcome.

For embedded placements, render `RoktLayoutView` and pass its `placeholderName`
in the `placeholders` array. The view does not need to be mounted when you call
`selectPlacements`: the SDK waits up to 2 seconds for each named placeholder, so
calling it from `useEffect` is fine. If a call is still waiting when `close()`
runs, or when a newer call with the same identifier replaces it, that call emits
`PlacementFailure` instead.

```jsx
useEffect(() => {
  MParticle.Rokt.selectPlacements(
    'MSDKEmbeddedLayout',
    attributes,
    ['Location1'],
    config
  );
}, []);

return <MParticle.RoktLayoutView placeholderName="Location1" />;
```

The earlier map of `placeholderName` to `findNodeHandle(ref)` is no longer
supported: see [MIGRATING](./MIGRATING.md#migrating-embedded-placements-to-placeholder-names).

| Method                                                | Notes                                                 |
| ----------------------------------------------------- | ----------------------------------------------------- |
| `selectShoppableAds(identifier, attributes, config?)` | iOS only — logs a warning and does nothing on Android |
| `purchaseFinalized(placementId, catalogItemId, ok)`   | Both platforms                                        |
| `close()`                                             | Both platforms                                        |
| `setSessionId(sessionId)` / `getSessionId()`          | Both platforms                                        |

Rokt callbacks and events are emitted as `RoktCallback` and `RoktEvents` on both
platforms. `MParticle.RoktEventManager` is an iOS-only native module — on
Android the same events arrive on React Native's device event emitter:

```js
import { DeviceEventEmitter, NativeEventEmitter, Platform } from 'react-native';

const emitter =
  Platform.OS === 'ios'
    ? new NativeEventEmitter(MParticle.RoktEventManager)
    : DeviceEventEmitter;

const subscription = emitter.addListener('RoktEvents', event =>
  console.debug(event)
);
```

Engagement signals arrive as an `event` field inside a `RoktEvents` payload
(for example `FirstPositiveEngagement`), not as separate event names.

## Session and Uploads

```js
// Session UUID; null on iOS and undefined on Android when there is no session
MParticle.getSession(session => console.debug(session));

MParticle.setUploadInterval(10); // seconds
MParticle.upload();
```

## Push Registration

The method `MParticle.logPushRegistration()` accepts 2 parameters, both typed `string`. On Android the call is dropped unless both `pushToken` and `senderId` are non-empty. On iOS the second parameter is ignored, so pass an empty string.

### Android

```js
MParticle.logPushRegistration(pushToken, senderId);
```

### iOS

```js
MParticle.logPushRegistration(pushToken, '');
```

## GDPR Consent

Add a GDPRConsent

```js
var gdprConsent = new MParticle.GDPRConsent()
  .setConsented(true)
  .setDocument('the document')
  .setTimestamp(new Date().getTime()) // optional, native SDK will automatically set current timestamp if omitted
  .setLocation('the location')
  .setHardwareId('the hardwareId');

MParticle.addGDPRConsentState(gdprConsent, 'the purpose');
```

Remove a GDPRConsent

```js
MParticle.removeGDPRConsentStateWithPurpose('the purpose');
```

## CCPA Consent

Add a CCPAConsent

```js
var ccpaConsent = new MParticle.CCPAConsent()
  .setConsented(true)
  .setDocument('the document')
  .setTimestamp(new Date().getTime()) // optional, native SDK will automatically set current timestamp if omitted
  .setLocation('the location')
  .setHardwareId('the hardwareId');

MParticle.setCCPAConsentState(ccpaConsent);
```

Remove CCPAConsent

```js
MParticle.removeCCPAConsentState();
```

## Device Consent

Device-based consent is written as one state object and read back whole:

```js
MParticle.setDeviceConsentState({
  gdpr: { 'the purpose': gdprConsent },
  ccpa: ccpaConsent,
});

MParticle.getDeviceConsentState(consentState => console.debug(consentState));

MParticle.clearDeviceConsentState();
```

A state with no GDPR purposes and no CCPA consent is stored as no state at all,
so `getDeviceConsentState` yields `null`.

# License

Apache 2.0
