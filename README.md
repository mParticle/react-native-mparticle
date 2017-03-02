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
$ # Update your Podfile to depend on 'mParticle-Apple-SDK'
$ pod install
```

**Start mParticle** within `application:didFinishLaunchingWithOptions:`:

```objective-c
[[MParticle sharedInstance] startWithKey:@"APP KEY" secret:@"APP SECRET"];
```

## Android

**Add your key and secret** as string resources in your app:

```xml
<?xml version="1.0" encoding="utf-8" ?>
<!-- ex. src/main/res/values/mparticle.xml -->
<resources>
    <string name="mp_key">APP KEY</string>
    <string name="mp_secret">APP SECRET</string>
</resources>
```

**Start mParticle** in your application's `onCreate`:

```objective-c
MParticle.start(this);
```

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
const product = new MParticle.Product('Test product for cart', 1234, 19.99)
const transactionAttributes = new MParticle.TransactionAttributes('Test transaction id')
const event = MParticle.CommerceEvent.createProductActionEvent(ProductActionType.AddToCart, [product], transactionAttributes)

MParticle.logCommerceEvent(event)
```

```js
const promotion = new MParticle.Promotion('Test promotion id', 'Test promotion name', 'Test creative', 'Test position')
const event = MParticle.CommerceEvent.createPromotionEvent(MParticle.PromotionActionType.View, [promotion])

MParticle.logCommerceEvent(event)
```

```js
const product = new MParticle.Product('Test product that was viewed', 5678, 29.99)
const impression = new MParticle.Impression('Test impression list name', [product])
const event = MParticle.CommerceEvent.createImpressionEvent([impression])

MParticle.logCommerceEvent(event)
```

**Logging** screen events:

```js
MParticle.logScreenEvent('Test screen', { 'Test key': 'Test value' })
```

## User Attributes

**Setting** user attributes and tags:

```js
MParticle.setUserAttribute('Test key', 'Test value')
```

```js
MParticle.setUserAttribute(MParticle.UserAttributeType.FirstName, 'Test first name')
```

```js
MParticle.setUserAttributeArray('Test key', ['Test value 1', 'Test value 2'])
```

```js
MParticle.setUserTag('Test key')
```

```js
MParticle.removeUserAttribute('Test key')
```

## User Identities

**Setting** user identities:

```js
MParticle.setUserIdentity('example@example.com', MParticle.UserIdentityType.Email)
```

# License

Apache 2.0
