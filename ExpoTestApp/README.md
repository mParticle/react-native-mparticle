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

The Rokt section also demonstrates:

- Platform-specific attributes (iOS vs Android configurations)
- Rokt event listeners for callbacks and placement events
- Using `RoktLayoutView` as an embedded placeholder component

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

| Option | Type | Description |
|--------|------|-------------|
| `iosApiKey` | string | mParticle iOS API key |
| `iosApiSecret` | string | mParticle iOS API secret |
| `androidApiKey` | string | mParticle Android API key |
| `androidApiSecret` | string | mParticle Android API secret |
| `logLevel` | string | Log level: `none`, `error`, `warning`, `debug`, `verbose` |
| `environment` | string | Environment: `development`, `production`, `autoDetect` |
| `useEmptyIdentifyRequest` | boolean | Initialize with empty identify request (default: true) |
| `dataPlanId` | string | Data plan ID for validation |
| `dataPlanVersion` | number | Data plan version |
| `iosKits` | string[] | iOS kit pod names (e.g., `["mParticle-Rokt"]`) |
| `androidKits` | string[] | Android kit dependencies (e.g., `["android-rokt-kit"]`) |
