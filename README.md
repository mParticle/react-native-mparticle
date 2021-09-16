# react-native-mparticle

[![npm version](https://badge.fury.io/js/react-native-mparticle.svg)](https://badge.fury.io/js/react-native-mparticle)
[![Standard - JavaScript Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](http://standardjs.com/)

React Native allows developers to use a single code base to deploy features to multiple platforms. With the mParticle React Native library, you can leverage a single API to deploy your data to hundreds of integrations from your iOS and Android apps.

### Supported Features
| Method | Android | iOS |
| ---    | ---     | --- |
| Custom Events | <li> [X] </li> | <li> [X]  </li> | |
| Page Views | <li> [X]  </li> | <li> [X]  </li> | | 
| Identity | <li> [X]  </li> | <li> [X]  </li> | |
| eCommerce | <li> [X]  </li> | <li> [X]  </li> | |
| Consent | <li> [X]  </li> | <li> [X]  </li> | |

# Installation

1. **Download and install the mParticle React Native library** from npm:

```bash
$ npm install react-native-mparticle --save
```

2. **Install the native dependencies**. You can use `rnpm` (now part of `react-native` core via `link`) to add native dependencies automatically:

```bash
$ react-native link
```

## <a name="iOS"></a>iOS

1. **Copy your mParticle key and secret** from [your app's dashboard][1].

[1]: https://app.mparticle.com/setup/inputs/apps

2. **Install the SDK** using CocoaPods:

```bash
$ # Update your Podfile to depend on 'mParticle-Apple-SDK' version 7.2.0 or later
$ pod install
```

The mParticle SDK is initialized by calling the `startWithOptions` method within the `application:didFinishLaunchingWithOptions:` delegate call.

Preferably the location of the initialization method call should be one of the last statements in the `application:didFinishLaunchingWithOptions:`.

The `startWithOptions` method requires an options argument containing your key and secret and an initial Identity request.

> Note that you must initialize the SDK in the `application:didFinishLaunchingWithOptions:` method. Other parts of the SDK rely on the `UIApplicationDidBecomeActiveNotification` notification to function properly. Failing to start the SDK as indicated will impair it. Also, please do **not** use _GCD_'s `dispatch_async` to start the SDK.

For more help, see [the iOS set up docs](https://docs.mparticle.com/developers/sdk/ios/getting-started/#create-an-input).

3. Import and start the mParticle Apple SDK into Swift or Objective-C.


#### Swift Example

```swift
import mParticle_Apple_SDK

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
       // Override point for customization after application launch.
        let mParticleOptions = MParticleOptions(key: "<<<App Key Here>>>", secret: "<<<App Secret Here>>>")
        
       //Please see the Identity page for more information on building this object
        let request = MPIdentityApiRequest()
        request.email = "email@example.com"
        mParticleOptions.identifyRequest = request
        mParticleOptions.onIdentifyComplete = { (apiResult, error) in
            NSLog("Identify complete. userId = %@ error = %@", apiResult?.user.userId.stringValue ?? "Null User ID", error?.localizedDescription ?? "No Error Available")
        }
        mParticleOptions.onAttributionComplete = { (attributionResult, error) in
                    NSLog(@"Attribution Complete. attributionResults = %@", attributionResult.linkInfo)
        }
        
       //Start the SDK
        MParticle.sharedInstance().start(with: mParticleOptions)
        
       return true
}
```

#### Objective-C Example

For apps supporting iOS 8 and above, Apple recommends using the import syntax for **modules** or **semantic import**. However, if you prefer the traditional CocoaPods and static libraries delivery mechanism, that is fully supported as well.

If you are using mParticle as a framework, your import statement will be as follows:

```objective-c
@import mParticle_Apple_SDK;                // Apple recommended syntax, but requires "Enable Modules (C and Objective-C)" in pbxproj
#import <mParticle_Apple_SDK/mParticle.h>   // Works when modules are not enabled

```

Otherwise, for CocoaPods without `use_frameworks!`, you can use either of these statements:

```objective-c
#import <mParticle-Apple-SDK/mParticle.h>
#import "mParticle.h"
```

Next, you'll need to start the SDK:

```objective-c
- (BOOL)application:(UIApplication *)application
        didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    MParticleOptions *mParticleOptions = [MParticleOptions optionsWithKey:@"REPLACE ME"
                                                                   secret:@"REPLACE ME"];
    
    //Please see the Identity page for more information on building this object
    MPIdentityApiRequest *request = [MPIdentityApiRequest requestWithEmptyUser];
    request.email = @"email@example.com";
    mParticleOptions.identifyRequest = request;
    mParticleOptions.onIdentifyComplete = ^(MPIdentityApiResult * _Nullable apiResult, NSError * _Nullable error) {
        NSLog(@"Identify complete. userId = %@ error = %@", apiResult.user.userId, error);
    };
    mParticleOptions.onAttributionComplete(MPAttributionResult * _Nullable attributionResult, NSError * _Nullable error) {
        NSLog(@"Attribution Complete. attributionResults = %@", attributionResult.linkInfo)
    }
    
    [[MParticle sharedInstance] startWithOptions:mParticleOptions];
    
    return YES;
}
```

See [Identity](http://docs.mparticle.com/developers/sdk/ios/identity/) for more information on supplying an `MPIdentityApiRequest` object during SDK initialization.


## <a name="Android"></a>Android

1. Copy your mParticle key and secret from [your workspace's dashboard](https://app.mparticle.com/setup/inputs/apps) and construct an `MParticleOptions` object.

2. Call `start` from the `onCreate` method of your app's `Application` class. It's crucial that the SDK be started here for proper session management. If you don't already have an `Application` class, create it and then specify its fully-qualified name in the `<application>` tag of your app's `AndroidManifest.xml`.

For more help, see [the Android set up docs](https://docs.mparticle.com/developers/sdk/android/getting-started/#create-an-input).

```java
package com.example.myapp;

import android.app.Application;
import com.mparticle.MParticle;

public class MyApplication extends Application {
    @Override
    public void onCreate() {
        super.onCreate();
        MParticleOptions options = MParticleOptions.builder(this)
            .credentials("REPLACE ME WITH KEY","REPLACE ME WITH SECRET")
            .setLogLevel(MParticle.LogLevel.VERBOSE)
            .identify(identifyRequest)
            .identifyTask(
                new BaseIdentityTask()
                        .addFailureListener(this)
                        .addSuccessListener(this)
                    )
            .attributionListener(this)
            .build();

        MParticle.start(options);
    }
}
```

> **Warning:** Don't log events in your `Application.onCreate()`. Android may instantiate your `Application` class in the background without your knowledge, eventwhile the user isn't even using their device, and lead to unexpected results. 


# Usage

## Import the mParticle Module

```js
import MParticle from 'react-native-mparticle'
```

## Logging Events

To log basic events:

```js
MParticle.logEvent('Test event', MParticle.EventType.Other, { 'Test key': 'Test value' })
```

To log commerce events:

```js
const product = new MParticle.Product('Test product for cart', '1234', 19.99)
const transactionAttributes = new MParticle.TransactionAttributes('Test transaction id')
const event = MParticle.CommerceEvent.createProductActionEvent(MParticle.ProductActionType.AddToCart, [product], transactionAttributes)

MParticle.logCommerceEvent(event)
```

```js
const promotion = new MParticle.Promotion('Test promotion id', 'Test promotion name', 'Test creative', 'Test position')
const event = MParticle.CommerceEvent.createPromotionEvent(MParticle.PromotionActionType.View, [promotion])

MParticle.logCommerceEvent(event)
```

```js
const product = new MParticle.Product('Test product that was viewed', '5678', 29.99)
const impression = new MParticle.Impression('Test impression list name', [product])
const event = MParticle.CommerceEvent.createImpressionEvent([impression])

MParticle.logCommerceEvent(event)
```

To log screen events:

```js
MParticle.logScreenEvent('Test screen', { 'Test key': 'Test value' })
```

## User

Get the current user in order to apply and remove attributes, tags, etc.

Use `Identify` or `currentUser` methods to retrieve the `userID` for these calls

```js
MParticle.User.setUserAttribute('User ID', 'Test key', 'Test value')
```

```js
MParticle.User.setUserAttribute('User ID', MParticle.UserAttributeType.FirstName, 'Test first name')
```

```js
MParticle.User.setUserAttributeArray('User ID', 'Test key', ['Test value 1', 'Test value 2'])
```

```js
MParticle.User.setUserTag('User ID', 'Test value')
```

```js
MParticle.User.removeUserAttribute('User ID', 'Test key')
```

```js
MParticle.Identity.getUserIdentities((userIdentities) => {
	console.debug(userIdentities);
});
```

## IdentityRequest

```js
var request = new MParticle.IdentityRequest()
```

**Set** a user Alias to be ran anytime the user’s identity changes
```js
request.onUserAlias = (previousUser, newUser) => {
    console.debug(previousUser.userID);
    console.debug(newUser.userID);
};
```

**Setting** user identities:

```js
var request = new MParticle.IdentityRequest();
request.setUserIdentity('example@example.com', MParticle.UserIdentityType.Email);
```

## Identity

```js
MParticle.Identity.getCurrentUser((currentUser) => {
    console.debug(currentUser.userID);
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
```
var attributions = MParticle.getAttributions();
```

In order to listen for Attributions asynchronously, you need to set the proper field in `MParticleOptions` as shown in the [Android](#Android) or the [iOS](#iOS) SDK start examples.

## Kits
Check if a kit is active

```
var isKitActive = MParticle.isKitActive(kitId);
```

Check and set the SDK's opt out status

```
var isOptedOut = MParticle.getOptOut();
MParticle.setOptOut(!isOptedOut);
```

## Push Registration

The method `MParticle.logPushRegistration()` accepts 2 parameters. For Android, provide both the `pushToken` and `senderId`. For iOS, provide the push token in the first parameter, and simply pass `null` for the second parameter.

### Android

```
MParticle.logPushRegistration(pushToken, senderId);
```

### iOS

```
MParticle.logPushRegistration(pushToken, null);
```

## GDPR Consent
Add a GDPRConsent

```
var gdprConsent = GDPRConsent()
    .setConsented(true)
    .setDocument("the document")
    .setTimestamp(new Date().getTime())  // optional, native SDK will automatically set current timestamp if omitted
    .setLocation("the location")
    .setHardwareId("the hardwareId");

MParticle.addGDPRConsentState(gdprConsent, "the purpose");
```

Remove a GDPRConsent
```
MParticle.removeGDPRConsentStateWithPurpose("the purpose");
```

## CCPA Consent
Add a CCPAConsent

```
var ccpaConsent = CCPAConsent()
    .setConsented(true)
    .setDocument("the document")
    .setTimestamp(new Date().getTime())  // optional, native SDK will automatically set current timestamp if omitted
    .setLocation("the location")
    .setHardwareId("the hardwareId");

MParticle.addCCPAConsentState(ccpaConsent);
```

Remove CCPAConsent
```
MParticle.removeCCPAConsentState();
```


# License

Apache 2.0
