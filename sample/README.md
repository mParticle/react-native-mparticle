# mParticle React Native Sample App

This sample app demonstrates how to integrate and use the mParticle React Native SDK.

## Prerequisites

- Node.js (>= 18)
- Yarn package manager
- React Native development environment set up
- For iOS: Xcode and iOS Simulator
- For Android: Android Studio and Android SDK

## Setup Instructions

### 1. Configure mParticle Keys

Before running the sample app, you need to replace the placeholder mParticle keys with your actual mParticle app credentials.

#### iOS Configuration

Edit `ios/MParticleSample/AppDelegate.mm` and replace the placeholder keys:

```objc
MParticleOptions *mParticleOptions = [MParticleOptions optionsWithKey:@"YOUR_IOS_API_KEY"
                                                               secret:@"YOUR_IOS_SECRET_KEY"];
```

#### Android Configuration

Edit `android/app/src/main/java/com/mparticlesample/MainApplication.kt` and replace the placeholder keys:

```kotlin
val options = MParticleOptions.builder(this)
  .credentials("YOUR_ANDROID_API_KEY", "YOUR_ANDROID_SECRET_KEY")
  .logLevel(MParticle.LogLevel.VERBOSE)
  .identify(identityRequest.build())
  .build()
```

### 2. Build and Install the Package

From the **root directory**, run the following commands:

```bash
# Build the TypeScript source and create a package
yarn dev:pack

# Install dependencies in the sample app
cd sample
yarn install
```

Alternatively, you can use the combined command from the root directory:

```bash
# Build, pack, and install in sample directory in one command
yarn dev:link
```

### 3. Install iOS Dependencies (iOS only)

```bash
cd sample/ios
pod install
```

The sample Podfile pins `mParticle-Rokt` `~> 9.2`, **`Rokt-Widget` `5.2.0`**, and **`DcuiSchema` `2.7.0`**. Rokt’s pods allow `DcuiSchema` to float within `~> 2.6`; when CocoaPods resolves **2.8.0+**, the schema adds `image` styling that can desync from the `RoktUXHelper` sources in that widget line and break Swift compile (`StyleTransformer` / `BaseStyles`). Bump these pins together when you adopt a newer Rokt iOS stack.

The sample Android app pins `com.mparticle:android-core` and
`com.mparticle:android-rokt-kit` to `5.79.2` so the Rokt session APIs and
Android CNAME support are available. Payment-extension installation and native
URL callback forwarding are not configured in this release.

## Running the Sample App

### iOS

From the **sample directory**:

```bash
yarn ios
```

### Android

From the **sample directory**:

```bash
yarn android
```

## Development Workflow

When making changes to the mParticle React Native SDK:

1. Make your changes to the SDK source code
2. Rebuild and reinstall the package:

   ```bash
   # From root directory
   yarn dev:link
   ```

3. Restart the sample app to see your changes

## Troubleshooting

### Common Issues

1. **Metro bundler cache issues**: Clear the cache with:

   ```bash
   cd sample
   npx react-native start --reset-cache
   ```

2. **iOS build issues**: Clean and rebuild:

   ```bash
   cd sample/ios
   xcodebuild clean
   cd ..
   yarn ios
   ```

3. **Android build issues**: Clean and rebuild:

   ```bash
   cd sample/android
   ./gradlew clean
   cd ..
   yarn android
   ```

4. **Package not found**: Make sure you've run `yarn dev:pack` or `yarn dev:link` from the root directory

## Available Scripts

From the sample directory:

- `yarn start` - Start the Metro bundler
- `yarn ios` - Run on iOS simulator
- `yarn android` - Run on Android emulator
- `yarn lint` - Run ESLint
- `yarn test` - Run Jest tests

## iOS native unit tests (SDK bridge)

The sample Xcode project includes **`RCTConvertCommerceMappingTests`**, which asserts that JavaScript `ProductActionType` / `PromotionActionType` integers map to the correct Apple SDK enums, and that **`+[RCTConvert MPCommerceEvent:]`** builds `MPCommerceEvent` / `MPPromotionContainer` with those mappings (the object graph used before `-[MParticle logCommerceEvent:]`) — see comments in that file for scope vs. the TurboModule codegen path.

From `sample/ios` after `pod install`:

```bash
xcodebuild -workspace MParticleSample.xcworkspace \
  -scheme MParticleSample \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  test -only-testing:MParticleSampleTests/RCTConvertCommerceMappingTests
```

Pull requests run these tests in CI (see `.github/workflows/pull-request.yml`).

## Deferred-init edge case (Android)

The sample includes a small, opt-in example that reproduces a late-initialisation race on
Android: starting mParticle from a native module at first-frame paint (a partner pattern used
to cut startup cost) instead of in `MainApplication.onCreate()`. Because the Rokt SDK caches
the current `Activity` only on `onActivityResumed` (≤ v5), deferring init past the host
Activity's resume leaves overlay/bottom-sheet placements unable to display until the next
resume. iOS is unaffected. Fixed upstream in the Rokt Android SDK (`sdk-android-source`
[#1062](https://github.com/ROKT/sdk-android-source/pull/1062),
[#1063](https://github.com/ROKT/sdk-android-source/pull/1063)).

It is **disabled by default**. To reproduce:

1. Set `DEFERRED_INIT_EXAMPLE = true` in
   `android/app/src/main/java/com/mparticlesample/DeferredInitModule.kt`.
2. Run the app and watch `adb logcat -s DeferredInitRepro`.

The `EAGER` tracker (registered at process start) captures `MainActivity`; the `DEFERRED`
tracker (registered when init runs at first frame) stays `null` until you background and
reopen the app — demonstrating the race. See `DeferredInitModule.kt` for the full write-up.

> **Note:** When the flag is enabled, mParticle is not started until first-frame paint, so any
> mParticle JS calls made earlier (e.g. `Identity.login` in the component constructor,
> `getSession` in `componentDidMount`) run before the SDK is started and are no-ops until then.
> This is itself an inherent hazard of deferred initialisation and is expected in this example;
> gate such calls behind init completion in a real deferred-init integration. With the flag off
> (default) mParticle starts eagerly in `onCreate()`, so these calls behave normally.

## Additional Resources

- [mParticle Documentation](https://docs.mparticle.com/)
- [React Native mParticle SDK Documentation](https://github.com/mParticle/react-native-mparticle)
- [React Native Documentation](https://reactnative.dev/)
