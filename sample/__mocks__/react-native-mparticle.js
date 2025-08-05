/* eslint-disable */
/**
 * Mock for react-native-mparticle
 * This mock provides a simple API that mimics the essential functionality
 */

// Mock classes
class User {
  constructor(userId) {
    this.userId = userId;
  }
  
  getMpid() {
    return this.userId;
  }
  
  setUserAttribute() {}
  getUserAttributes(callback) {
    callback({ testAttribute: 'testValue' });
  }
  setUserTag() {}
  incrementUserAttribute() {}
  removeUserAttribute() {}
  getUserIdentities(callback) {
    callback({ email: 'test@example.com' });
  }
  getFirstSeen(callback) {
    callback(Date.now() - 86400000);
  }
  getLastSeen(callback) {
    callback(Date.now());
  }
}

class IdentityRequest {
  setEmail(email) {
    this.email = email;
    return this;
  }
  
  setCustomerID(customerId) {
    this.customerId = customerId;
    return this;
  }
  
  setUserIdentity(userIdentity, identityType) {
    this[identityType] = userIdentity;
    return this;
  }
}

class Identity {
  static getCurrentUser(completion) {
    var currentUser = new User('mockUserId123');
    completion(currentUser);
  }
  
  static login(request, completion) {
    completion(null, 'mockUserId123', 'mockPreviousUserId456');
  }
  
  static logout(request, completion) {
    completion(null, 'mockUserId123');
  }
  
  static identify(request, completion) {
    completion(null, 'mockUserId123', 'mockPreviousUserId456');
  }
  
  static modify(request, completion) {
    completion(null, 'mockUserId123', 'mockPreviousUserId456');
  }
  
  static aliasUsers(request, completion) {
    completion(true, null);
  }
}

class Product {
  constructor(name, sku, price, quantity = 1) {
    this.name = name;
    this.sku = sku;
    this.price = price;
    this.quantity = quantity;
  }
}

class TransactionAttributes {
  constructor(transactionId) {
    this.transactionId = transactionId;
  }
}

class CommerceEvent {
  static createProductActionEvent(productActionType, products, transactionAttributes) {
    return new CommerceEvent();
  }
}

class AliasRequest {
  sourceMpid(mpid) {
    this.sourceMpid = mpid;
    return this;
  }
  
  destinationMpid(mpid) {
    this.destinationMpid = mpid;
    return this;
  }
  
  startTime(time) {
    this.startTime = time;
    return this;
  }
  
  endTime(time) {
    this.endTime = time;
    return this;
  }
}

// Mock Rokt
const Rokt = {
  selectPlacements: () => Promise.resolve()
};

// Constants
const EventType = {
  Navigation: 1,
  Location: 2,
  Search: 3,
  Transaction: 4,
  UserContent: 5,
  UserPreference: 6,
  Social: 7,
  Other: 8,
  Media: 9
};

const UserIdentityType = {
  Email: 7,
  CustomerId: 1,
  Alias: 8
};

const ProductActionType = {
  AddToCart: 1,
  RemoveFromCart: 2,
  Checkout: 3,
  Purchase: 7
};

// Main mock object
const MParticle = {
  // Classes
  User,
  IdentityRequest,
  Identity,
  Product,
  TransactionAttributes,
  CommerceEvent,
  AliasRequest,
  Rokt,
  
  // Constants
  EventType,
  UserIdentityType,
  ProductActionType,
  
  // Methods
  logEvent: () => {},
  logCommerceEvent: () => {},
  logPushRegistration: () => {},
  getSession: (callback) => callback({ sessionId: 'mockSessionId123' }),
  setOptOut: () => {},
  getOptOut: (callback) => callback(false),
  isKitActive: (kitId, callback) => callback(true),
  getAttributions: (callback) => callback({ attributionResults: 'mock results' }),
  upload: () => {},
  setUploadInterval: () => {},
  setLocation: () => {}
};

module.exports = MParticle; 