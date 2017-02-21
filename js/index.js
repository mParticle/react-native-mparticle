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
  FacebookCustomAudienceId: 9
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

const setUserAttribute = (key, value) => {
  if (value && value.constructor === Array) {
    setUserAttributeArray(key, value)
  } else {
    NativeModules.MParticle.setUserAttribute(key, value)
  }
}

const setUserAttributeArray = (key, values) => {
  NativeModules.MParticle.setUserAttributeArray(key, values)
}

const setUserTag = (tag) => {
  NativeModules.MParticle.setUserTag(tag)
}

const removeUserAttribute = (key) => {
  NativeModules.MParticle.removeUserAttribute(key)
}

const setUserIdentity = (userIdentity, identityType) => {
  NativeModules.MParticle.setUserIdentity(userIdentity, identityType)
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

class Product {
  constructor (name, sku, price, quantity) {
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

  logEvent,             // Methods
  logCommerceEvent,
  logScreenEvent,
  setUserAttribute,
  setUserAttributeArray,
  setUserTag,
  removeUserAttribute,
  setUserIdentity

}

export default MParticle
