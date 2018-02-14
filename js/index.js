'use strict'

import { NativeModules } from 'react-native'

// ******** Constants ********

const EventType = {
  Navigation: 1,
  Location: 2,
  Search: 3,
  Transaction: 4,
  UserContent: 5,
  UserPreference: 6,
  Social: 7,
  Other: 8
}

const UserAttributeType = {
  FirstName: '$FirstName',
  LastName: '$LastName',
  Address: '$Address',
  State: '$State',
  City: '$City',
  Zipcode: '$Zip',
  Country: '$Country',
  Age: '$Age',
  Gender: '$Gender',
  MobileNumber: '$Mobile'
}

const UserIdentityType = {
  Other: 0,
  CustomerId: 1,
  Facebook: 2,
  Twitter: 3,
  Google: 4,
  Microsoft: 5,
  Yahoo: 6,
  Email: 7,
  Alias: 8,
  FacebookCustomAudienceId: 9,
  Other2: 10,
  Other3: 11,
  Other4: 12
}

const ProductActionType = {
  AddToCart: 1,
  RemoveFromCart: 2,
  Checkout: 3,
  CheckoutOption: 4,
  Click: 5,
  ViewDetail: 6,
  Purchase: 7,
  Refund: 8,
  AddToWishlist: 9,
  RemoveFromWishlist: 10
}

const PromotionActionType = {
  View: 0,
  Click: 1
}

// ******** Main API ********

const logEvent = (eventName, type = EventType.Other, attributes = null) => {
  NativeModules.MParticle.logEvent(eventName, type, attributes)
}

const logCommerceEvent = (commerceEvent) => {
  NativeModules.MParticle.logCommerceEvent(commerceEvent)
}

const logScreenEvent = (screenName, attributes = null) => {
  NativeModules.MParticle.logScreenEvent(screenName, attributes)
}

// ******** Identity ********
class User {
  constructor (userID) {
    this.userID = userID
  }

  setUserAttribute (key, value) {
  if (value && value.constructor === Array) {
      setUserAttributeArray(key, value)
    } else {
      NativeModules.MParticle.setUserAttribute(key, value)
    }
  }

  setUserAttributeArray (key, value) {
    NativeModules.MParticle.setUserAttributeArray(key, value)
  }

  setUserTag (value) {
    NativeModules.MParticle.setUserTag(value)
  }

  incrementUserAtrribute (key, value) {
    NativeModules.MParticle.incrementUserAtrribute(key, value)
  }

  removeUserAttribute (key) {
    NativeModules.MParticle.removeUserAttribute(key)
  }

  static getUserIdentities (completion) {
    NativeModules.MParticle.getUserIdentities((error, userIdentities) => {
        completion(userIdentities)
      });
  }
}

class IdentityRequest {
  constructor () {
  }

  setEmail (email) {
    this.email = email
    return this
  }

  setCustomerID (customerId) {
    this.customerId = customerId
    return this
  }

  setUserIdentity (userIdentity, identityType) {
    switch (identityType) {
      case UserIdentityType.Other:
        this.other = userIdentity;
        break;
      case UserIdentityType.CustomerId:
        this.customerId = userIdentity;
        break;
      case UserIdentityType.Facebook:
        this.facebook = userIdentit;
        break;
      case UserIdentityType.Twitter:
        this.twitter = userIdentity;
        break;
      case UserIdentityType.Google:
        this.google = userIdentity;
        break;
      case UserIdentityType.Microsoft:
        this.microsoft = userIdentity;
        break;
      case UserIdentityType.Yahoo:
        this.yahoo = userIdentity;
        break;
      case UserIdentityType.Email:
        this.email = userIdentity;
        break;
      case UserIdentityType.FacebookCustomAudienceId:
        this.facebookCustom = userIdentity;
        break;
      case UserIdentityType.Other2:
        this.other2 = userIdentity;
        break;
      case UserIdentityType.Other3:
        this.other3 = userIdentity;
        break;
      case UserIdentityType.Other4:
        this.other4 = userIdentity;
        break;
      default: 
        break;
    }
    return this
  }

  setOnUserAlias (onUserAlias) {
    this.onUserAlias = onUserAlias
    return this
  }
}

class Identity {

  static getCurrentUser (completion) {
    NativeModules.MParticle.getCurrentUserWithCompletion((error, userId) => {
      var currentUser = new User(userId)
      completion(currentUser)
    });
  }

  static identify (IdentityRequest, completion) {
    NativeModules.MParticle.identify(IdentityRequest, (error, userId) => {
      var currentUser = new User(userId)
      completion(currentUser)
    });
  }

  static login (IdentityRequest, completion) {
    if(IdentityRequest.onUserAlias !== undefined) {
      MParticle.Identity.getCurrentUser(oldUser) => {
        NativeModules.MParticle.login(IdentityRequest, (error, userId) => {
          var currentUser = User(userId)
          IdentityRequest.onUserAlias(oldUser, currentUser)
          completion(currentUser)
        }
      });
    } else {
      NativeModules.MParticle.login(IdentityRequest, (error, userId) => {
        var currentUser = User(userId)
        completion(currentUser)
      }
    }
  }

  static logout (IdentityRequest, completion) {
    if(IdentityRequest.onUserAlias !== undefined) {
      MParticle.Identity.getCurrentUser(oldUser) => {
        NativeModules.MParticle.logout(IdentityRequest, (error, userId) => {
          var currentUser = User(userId)
          IdentityRequest.onUserAlias(oldUser, currentUser)
          completion(currentUser)
        }
      });
    } else {
      NativeModules.MParticle.logout(IdentityRequest, (error, userId) => {
        var currentUser = User(userId)
        completion(currentUser)
      }
    }
  }

  static modify (IdentityRequest, completion) {
    if(IdentityRequest.onUserAlias !== undefined) {
      MParticle.Identity.getCurrentUser(oldUser) => {
        NativeModules.MParticle.modify(IdentityRequest, (error, userId) => {
          var currentUser = User(userId)
          IdentityRequest.onUserAlias(oldUser, currentUser)
          completion(currentUser)
        }
      });
    } else {
      NativeModules.MParticle.modify(IdentityRequest, (error, userId) => {
        var currentUser = User(userId)
        completion(currentUser)
      }
    }
  }

// ******** Commerce ********

class Impression {
  constructor (impressionListName, products) {
    this.impressionListName = impressionListName
    this.products = products
  }
}

class Promotion {
  constructor (id, name, creative, position) {
    this.id = id
    this.name = name
    this.creative = creative
    this.position = position
  }
}

class TransactionAttributes {
  constructor (transactionId) {
    this.transactionId = transactionId
  }

  setAffiliation (affiliation) {
    this.affiliation = affiliation
    return this
  }

  setRevenue (revenue) {
    this.revenue = revenue
    return this
  }

  setShipping (shipping) {
    this.shipping = shipping
    return this
  }

  setTax (tax) {
    this.tax = tax
    return this
  }

  setCouponCode (couponCode) {
    this.couponCode = couponCode
    return this
  }
}

class Product {
  constructor (name, sku, price, quantity = 1) {
    this.name = name
    this.sku = sku
    this.price = price
    this.quantity = quantity
  }

  setBrand (brand) {
    this.brand = brand
    return this
  }

  setCouponCode (couponCode) {
    this.couponCode = couponCode
    return this
  }

  setPosition (position) {
    this.position = position
    return this
  }

  setCategory (category) {
    this.category = category
    return this
  }

  setVariant (variant) {
    this.variant = variant
    return this
  }

  setCustomAttributes (customAttributes) {
    this.customAttributes = customAttributes
    return this
  }
}

class CommerceEvent {

  static createProductActionEvent (productActionType, products, transactionAttributes = {}) {
    return new CommerceEvent()
                    .setProductActionType(productActionType)
                    .setProducts(products)
                    .setTransactionAttributes(transactionAttributes)
  }

  static createPromotionEvent (promotionActionType, promotions) {
    return new CommerceEvent()
                    .setPromotionActionType(promotionActionType)
                    .setPromotions(promotions)
  }

  static createImpressionEvent (impressions) {
    return new CommerceEvent()
                    .setImpressions(impressions)
  }

  setTransactionAttributes (transactionAttributes) {
    this.transactionAttributes = transactionAttributes
    return this
  }

  setProductActionType (productActionType) {
    this.productActionType = productActionType
    return this
  }

  setPromotionActionType (promotionActionType) {
    this.promotionActionType = promotionActionType
    return this
  }

  setProducts (products) {
    this.products = products
    return this
  }

  setPromotions (promotions) {
    this.promotions = promotions
    return this
  }

  setImpressions (impressions) {
    this.impressions = impressions
    return this
  }

  setScreenName (screenName) {
    this.screenName = screenName
    return this
  }

  setCurrency (currency) {
    this.currency = currency
    return this
  }

  setCustomAttributes (customAttributes) {
    this.customAttributes = customAttributes
    return this
  }

  setCheckoutOptions (checkoutOptions) {
    this.checkoutOptions = checkoutOptions
    return this
  }

  setProductActionListName (productActionListName) {
    this.productActionListName = productActionListName
    return this
  }

  setProductActionListSource (productActionListSource) {
    this.productActionListSource = productActionListSource
    return this
  }

  setCheckoutStep (checkoutStep) {
    this.checkoutStep = checkoutStep
    return this
  }

  setNonInteractive (nonInteractive) {
    this.nonInteractive = nonInteractive
    return this
  }
}

// ******** Exports ********

const MParticle = {

  EventType,            // Constants
  UserIdentityType,
  UserAttributeType,
  ProductActionType,
  PromotionActionType,

  Product,              // Classes
  Impression,
  Promotion,
  CommerceEvent,
  TransactionAttributes,
  IdentityRequest,
  Identity,
  User,

  logEvent,             // Methods
  logCommerceEvent,
  logScreenEvent

}

export default MParticle
