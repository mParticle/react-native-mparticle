# react-native-mparticle

[![npm version](https://badge.fury.io/js/react-native-mparticle.svg)](https://badge.fury.io/js/react-native-mparticle)
[![Standard - JavaScript Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](http://standardjs.com/)

# Installation

**First, download the library** from npm:

```bash
$ npm install react-native-mparticle --save
```

**Second, install the native dependencies**. You can use `rnpm` (now part of `react-native` core via `link`) to add native dependencies automatically:

```bash
$ react-native link
```

**Grab your mParticle key and secret** from [your app's dashboard][1] and move on to the OS-specific instructions below.

[1]: https://app.mparticle.com/apps

## iOS

**Install the SDK** using CocoaPods:

```bash
$ # Update your Podfile to depend on 'mParticle-Apple-SDK' version 7.2.0 or later
$ pod install
```

The mParticle SDK is initialized by calling the `startWithOptions` method within the `application:didFinishLaunchingWithOptions:` delegate call. Preferably the location of the initialization method call should be one of the last statements in the `application:didFinishLaunchingWithOptions:`. The `startWithOptions` method requires an options argument containing your key and secret and an initial Identity request.

> Note that it is imperative for the SDK to be initialized in the `application:didFinishLaunchingWithOptions:` method. Other parts of the SDK rely on the `UIApplicationDidBecomeActiveNotification` notification to function properly. Failing to start the SDK as indicated will impair it. Also, please do **not** use _GCD_'s `dispatch_async` to start the SDK.

#### Swift

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
        
       //Start the SDK
        MParticle.sharedInstance().start(with: mParticleOptions)
        
       return true
}
```

#### Objective-C

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
    
    [[MParticle sharedInstance] startWithOptions:mParticleOptions];
    
    return YES;
}
```

Please see [Identity](http://docs.mparticle.com/developers/sdk/ios/identity/) for more information on supplying an `MPIdentityApiRequest` object during SDK initialization.


## Android

1. Grab your mParticle key and secret from [your workspace's dashboard](https://app.mparticle.com/apps) and construct an `MParticleOptions` object.

2. Call `start` from the `onCreate` method of your app's `Application` class. It's crucial that the SDK be started here for proper session management. If you don't already have an `Application` class, create it and then specify its fully-qualified name in the `<application>` tag of your app's `AndroidManifest.xml`.

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
            .build();

        MParticle.start(options);
    }
}
```

> **Warning:** It's generally not a good idea to log events in your `Application.onCreate()`. Android may instantiate your `Application` class for a lot of reasons, in the background, while the user isn't even using their device. 


# Usage

## Import

**Importing** the module:

```js
import MParticle from 'react-native-mparticle'
```

## Events

**Logging** events:

```js
MParticle.logEvent('Test event', MParticle.EventType.Other, { 'Test key': 'Test value' })
```

**Logging** commerce events:

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

**Logging** screen events:

```js
MParticle.logScreenEvent('Test screen', { 'Test key': 'Test value' })
```

## User
**Setting** user attributes and tags:

Use Identify or currentUser to retrieve the userID for these calls
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

**Using** static methods to update and change identity


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

# License

Apache 2.0
