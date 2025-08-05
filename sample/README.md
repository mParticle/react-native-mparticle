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

## Additional Resources

- [mParticle Documentation](https://docs.mparticle.com/)
- [React Native mParticle SDK Documentation](https://github.com/mParticle/react-native-mparticle)
- [React Native Documentation](https://reactnative.dev/)
