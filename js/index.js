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

const logMPEvent = (event) => {
  NativeModules.MParticle.logMPEvent(event)
}

const logCommerceEvent = (commerceEvent) => {
  NativeModules.MParticle.logCommerceEvent(commerceEvent)
}

const logScreenEvent = (screenName, attributes = null) => {
  NativeModules.MParticle.logScreenEvent(screenName, attributes)
}

// ******** Identity ********
class User {
  constructor (userId) {
    this.userId = userId
  }

  static setUserAttribute (userId, key, value) {
    if (value && value.constructor === Array) {
      NativeModules.Mparticle.setUserAttributeArray(userId, key, value)
    } else {
      NativeModules.MParticle.setUserAttribute(userId, key, value)
    }
  }

  static setUserAttributeArray (userId, key, value) {
    NativeModules.MParticle.setUserAttributeArray(userId, key, value)
  }

  static setUserTag (userId, value) {
    NativeModules.MParticle.setUserTag(userId, value)
  }

  static incrementUserAtrribute (userId, key, value) {
    NativeModules.MParticle.incrementUserAtrribute(userId, key, value)
  }

  static removeUserAttribute (userId, key) {
    NativeModules.MParticle.removeUserAttribute(userId, key)
  }

  static getUserIdentities (userId, completion) {
    NativeModules.MParticle.getUserIdentities(userId, (error, userIdentities) => {
      completion(userIdentities)
    })
  }
}

class IdentityRequest {

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
        this.other = userIdentity
        break
      case UserIdentityType.CustomerId:
        this.customerId = userIdentity
        break
      case UserIdentityType.Facebook:
        this.facebook = userIdentity
        break
      case UserIdentityType.Twitter:
        this.twitter = userIdentity
        break
      case UserIdentityType.Google:
        this.google = userIdentity
        break
      case UserIdentityType.Microsoft:
        this.microsoft = userIdentity
        break
      case UserIdentityType.Yahoo:
        this.yahoo = userIdentity
        break
      case UserIdentityType.Email:
        this.email = userIdentity
        break
      case UserIdentityType.FacebookCustomAudienceId:
        this.facebookCustom = userIdentity
        break
      case UserIdentityType.Other2:
        this.other2 = userIdentity
        break
      case UserIdentityType.Other3:
        this.other3 = userIdentity
        break
      case UserIdentityType.Other4:
        this.other4 = userIdentity
        break
      default:
        break
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
    })
  }

  static identify (IdentityRequest, completion) {
    NativeModules.MParticle.identify(IdentityRequest, (error, userId) => {
      if (error == undefined) {
        completion(error, userId)
      } else {
        var parsedError = new MParticleError(error)
        completion(parsedError, userId)
      }
    })
  }

  static login (IdentityRequest, completion) {
    NativeModules.MParticle.login(IdentityRequest, (error, userId) => {
      if (IdentityRequest.onUserAlias !== undefined) {
        MParticle.Identity.getCurrentUser((oldUser) => {
          var currentUser = new User(userId)
          IdentityRequest.onUserAlias(oldUser, currentUser)
        })
      }

      if (error == undefined) {
        var parsedError = new MParticleError(error)
        completion(parsedError, userId)
      } else {
        completion(error, userId)
      }
    })
  }

  static logout (IdentityRequest, completion) {
    NativeModules.MParticle.logout(IdentityRequest, (error, userId) => {
      if (IdentityRequest.onUserAlias !== undefined) {
        MParticle.Identity.getCurrentUser((oldUser) => {
          var currentUser = new User(userId)
          IdentityRequest.onUserAlias(oldUser, currentUser)
        })
      }

      if (error == undefined) {
        completion(error, userId)
      } else {
        var parsedError = new MParticleError(error)
        completion(parsedError, userId)
      }
    })
  }

  static modify (IdentityRequest, completion) {
    NativeModules.MParticle.modify(IdentityRequest, (error, userId) => {
      if (IdentityRequest.onUserAlias !== undefined) {
        MParticle.Identity.getCurrentUser((oldUser) => {
          var currentUser = new User(userId)
          IdentityRequest.onUserAlias(oldUser, currentUser)
        })
      }

      if (error == undefined) {
        completion(error, userId)
      } else {
        var parsedError = new MParticleError(error)
        completion(parsedError, userId)
      }
    })
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

class Event {

  setCategory (category) {
    this.category = category
    return this
  }

  setDuration (duration) {
    this.duration = duration
    return this
  }

  setEndTime (endTime) {
    this.endTime = endTime
    return this
  }

  setInfo (info) {
    this.info = info
    return this
  }

  setName (name) {
    this.name = name
    return this
  }

  setStartTime (startTime) {
    this.startTime = startTime
    return this
  }

  setType (type) {
    this.type = type
    return this
  }

  setCustomFlags (customFlags) {
    this.customFlags = customFlags
    return this
  }
}

class MParticleError {
  constructor (errorResponse) {
    this.httpCode = errorResponse.httpCode

    this.responseCode = errorResponse.responseCode

    this.message = errorResponse.message

    this.mpid = errorResponse.mpid

    this.errors = errorResponse.errors
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
  Event,
  MParticleError,

  logEvent,             // Methods
  logMPEvent,
  logCommerceEvent,
  logScreenEvent

}

export default MParticle
