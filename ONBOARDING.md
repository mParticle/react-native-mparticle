# Developer Onboarding Guide

This guide will help you set up your development environment for working on the react-native-mparticle SDK.

## Prerequisites

- Node.js and npm
- React Native development environment set up ([React Native Environment Setup Guide](https://reactnative.dev/docs/environment-setup))
- For iOS:
  - macOS
  - Xcode (latest version recommended)
  - CocoaPods
  - Ruby (for CocoaPods)
- For Android:
  - Android Studio
  - Java Development Kit (JDK)
  - Android SDK

## Project Structure

```
react-native-mparticle/
├── android/          # Native Android SDK implementation
├── ios/              # Native iOS SDK implementation
├── js/               # JavaScript/TypeScript SDK implementation
├── plugin/           # Expo config plugin source
│   └── src/          # Plugin TypeScript source files
├── sample/           # Sample app for testing (manual RN setup)
├── ExpoTestApp/      # Expo test app for testing config plugin
└── ...
```

## Initial Setup

Install dependencies:

```bash
yarn install
```

## Running the Sample App

The sample app is a great way to test your changes and see the SDK in action.

### iOS Sample App

1. Navigate to the sample directory:

```bash
cd sample
```

2. Install dependencies (iOS pods are installed automatically via postinstall):

```bash
yarn install
```

3. Start the Metro bundler:

```bash
yarn start
```

4. Open the iOS workspace:

```bash
open ios/MParticleSample.xcworkspace
```

5. In Xcode:
   - Select your target device/simulator
   - Update signing configuration if needed
   - Build and run (⌘R)

### Android Sample App

1. Navigate to the sample directory:

```bash
cd sample
```

2. Install JavaScript dependencies:

```bash
npm install
# or
yarn install
```

3. Start the Metro bundler:

```bash
npm start
# or
yarn start
```

4. Open Android Studio:
   - Open the `android` folder in Android Studio
   - Let Gradle sync complete
   - Update any required SDK packages if prompted

5. Run the app:
   - Select your target device/emulator
   - Click Run (or press ⇧F10)

### Expo Test App

The ExpoTestApp is used for testing the Expo config plugin integration.

1. Build and pack the main library:

```bash
# From the root directory
yarn dev:pack
```

2. Navigate to the ExpoTestApp:

```bash
cd ExpoTestApp
```

3. Install dependencies:

```bash
npm install
```

4. Update API keys in `app.json` (plugins section):

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

5. Run prebuild to generate native projects:

```bash
npm run prebuild
```

6. Run the app:

```bash
# iOS
npm run ios

# Android
npm run android
```

#### Verifying Plugin Integration

After prebuild, verify the plugin configured the native projects correctly:

**iOS (`ios/<AppName>/AppDelegate.swift`):**

- Check for `import mParticle_Apple_SDK`
- Check for `MParticleOptions` initialization in `didFinishLaunchingWithOptions`

**Android (`android/app/src/main/java/.../MainApplication.kt`):**

- Check for mParticle imports
- Check for `MParticleOptions` initialization in `onCreate()`

#### Rebuilding After Plugin Changes

When making changes to the Expo plugin:

```bash
# From the root directory
yarn build:plugin
yarn dev:pack

# From ExpoTestApp directory
rm -rf node_modules ios android
npm install
npm run prebuild
```

## Development Workflow

### Building the SDK

#### TypeScript/JavaScript

```bash
yarn build
```

#### Expo Plugin

```bash
yarn build:plugin
```

#### Pack for Local Testing

```bash
yarn dev:pack
```

This creates `react-native-mparticle-latest.tgz` which can be used for local testing in the ExpoTestApp or other projects.

#### Android

```bash
cd android
./gradlew build
```

#### iOS

```bash
cd ios
pod install
```

### Running Tests

```bash
# Run JavaScript tests
npm test

# Run Android tests
cd android
./gradlew test

# Run iOS tests
cd ios/RNMParticle.xcodeproj
xcodebuild test
```

## Troubleshooting

### Common iOS Issues

1. "Missing config.h" error:
   This error occurs because the mParticle SDK contains Swift code which requires special handling. To fix this:

   a. Open your `sample/ios/Podfile` and add this block before the target definition:

   ```ruby
   pre_install do |installer|
     installer.pod_targets.each do |pod|
       if pod.name == 'mParticle-Apple-SDK'
         def pod.build_type;
           Pod::BuildType.new(:linkage => :dynamic, :packaging => :framework)
         end
       end
     end
   end
   ```

   b. Clean and reinstall pods:

   ```bash
   cd sample/ios
   pod cache clean --all
   rm -rf Pods Podfile.lock
   pod install
   ```

   c. If using Xcode 12 or later, ensure your project's Build Settings has "Allow Non-modular Includes In Framework Modules" set to Yes

2. Pod install fails:
   - Try cleaning the pod cache: `pod cache clean --all`
   - Delete Podfile.lock and try again
   - Ensure CocoaPods is up to date: `bundle update`

3. Build errors:
   - Clean build folder in Xcode (⇧⌘K)
   - Delete derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData`
   - Ensure all dependencies are properly installed

### Common Android Issues

1. Gradle sync fails:
   - Check Android Studio SDK Manager for missing packages
   - Update Gradle version if needed
   - Clean project and rebuild

2. Build errors:
   - Run `./gradlew clean`
   - Invalidate caches in Android Studio
   - Ensure all dependencies are properly installed

## Contributing

1. Create a feature branch
2. Make your changes
3. Test thoroughly
4. Create a pull request
5. Ensure CI passes
6. Request review

## Release Process

1. Update version numbers:
   - package.json
   - android/build.gradle
   - ios/RNMParticle.podspec

2. Update CHANGELOG.md

3. Create release PR

4. After merge, create a new release on GitHub

5. Publish to npm:

```bash
npm publish
```
