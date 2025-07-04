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
├── ios/             # Native iOS SDK implementation
├── js/              # JavaScript/TypeScript SDK implementation
├── sample/          # Sample app for testing
└── ...
```

## Initial Setup

Install dependencies:
```bash
npm install
```

## Running the Sample App

The sample app is a great way to test your changes and see the SDK in action.

### iOS Sample App

1. Navigate to the sample directory:
```bash
cd sample
```

2. Install JavaScript dependencies:
```bash
yarn install
```

3. Install iOS dependencies:
```bash
cd ios
pod install
cd ..
```

4. Start the Metro bundler:
```bash
yarn start
```

5. Open the iOS workspace:
```bash
open ios/MParticleSample.xcworkspace
```

6. In Xcode:
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

## Development Workflow

### Building the SDK

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