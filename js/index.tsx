'use strict';

import { Platform } from 'react-native';
import {
  Rokt,
  CacheConfig,
  IRoktConfig,
  ColorMode,
  RoktEventManager,
} from './rokt/rokt';
import RoktLayoutView, { RoktLayoutViewProps } from './rokt/rokt-layout-view';
import type {
  Spec as NativeMParticleInterface,
  CallbackError,
  UserAttributes as NativeUserAttributes,
} from './codegenSpecs/NativeMParticle';
import { getNativeModule } from './utils/architecture';

const MParticleModule: NativeMParticleInterface =
  getNativeModule<NativeMParticleInterface>('RNMParticle', 'MParticle');

// ******** Types ********
export interface UserAttributes extends NativeUserAttributes {
  [key: string]: string | string[] | number | boolean;
}

export interface UserIdentities {
  [key: number]: string;
}

export interface CustomAttributes {
  [key: string]: string | number | boolean;
}

export interface MParticleErrorResponse {
  httpCode: number;
  message?: string; // iOS only
  responseCode?: number; // iOS only
  mpid?: string;
  errors?: string; // Both platforms return error details as concatenated strings
}

export interface AttributionResult {
  [key: string]: any;
}

export type CompletionCallback<T> = (result: T) => void;
export type ErrorCallback = (error: MParticleError | null) => void;
export type IdentityCallback = (
  error: MParticleError | null,
  userId: string | null,
  previousUserId?: string | null // previousUserId is optional in some cases
) => void;

// ******** Constants ********

export const EventType = {
  Navigation: 1,
  Location: 2,
  Search: 3,
  Transaction: 4,
  UserContent: 5,
  UserPreference: 6,
  Social: 7,
  Other: 8,
  Media: 9,
} as const;

export const UserAttributeType = {
  FirstName: '$FirstName',
  LastName: '$LastName',
  Address: '$Address',
  State: '$State',
  City: '$City',
  Zipcode: '$Zip',
  Country: '$Country',
  Age: '$Age',
  Gender: '$Gender',
  MobileNumber: '$Mobile',
} as const;

export const UserIdentityType = {
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
  Other4: 12,
  Other5: 13,
  Other6: 14,
  Other7: 15,
  Other8: 16,
  Other9: 17,
  Other10: 18,
  MobileNumber: 19,
  PhoneNumber2: 20,
  PhoneNumber3: 21,
  IOSAdvertiserId: 22,
  IOSVendorId: 23,
  PushToken: 24,
  DeviceApplicationStamp: 25,
} as const;

export const ProductActionType = {
  AddToCart: 1,
  RemoveFromCart: 2,
  Checkout: 3,
  CheckoutOption: 4,
  Click: 5,
  ViewDetail: 6,
  Purchase: 7,
  Refund: 8,
  AddToWishlist: 9,
  RemoveFromWishlist: 10,
} as const;

export const PromotionActionType = {
  View: 0,
  Click: 1,
} as const;

export const ATTAuthStatus = {
  NotDetermined: 0,
  Restricted: 1,
  Denied: 2,
  Authorized: 3,
} as const;

// ******** Main API ********

export const upload = (): void => {
  MParticleModule.upload();
};

export const setUploadInterval = (uploadInterval: number): void => {
  MParticleModule.setUploadInterval(uploadInterval);
};

export const logEvent = (
  eventName: string,
  type: number = EventType.Other,
  attributes: CustomAttributes | null = null
): void => {
  MParticleModule.logEvent(eventName, type, attributes);
};

export const logMPEvent = (event: Event): void => {
  MParticleModule.logMPEvent(event);
};

export const logCommerceEvent = (commerceEvent: CommerceEvent): void => {
  MParticleModule.logCommerceEvent(commerceEvent);
};

export const logScreenEvent = (
  screenName: string,
  attributes: CustomAttributes | null = null,
  shouldUploadEvent = true
): void => {
  MParticleModule.logScreenEvent(screenName, attributes, shouldUploadEvent);
};

// ATT Status methods - iOS only, will be no-op on Android
export const setATTStatus = (status: number): void => {
  if (Platform.OS === 'ios') {
    MParticleModule.setATTStatus(status);
  }
};

export const setATTStatusWithCustomTimestamp = (
  status: number,
  timestamp: number
): void => {
  if (Platform.OS === 'ios') {
    MParticleModule.setATTStatusWithCustomTimestamp(status, timestamp);
  }
};

export const setOptOut = (optOut: boolean): void => {
  MParticleModule.setOptOut(optOut);
};

export const getOptOut = (completion: CompletionCallback<boolean>): void => {
  MParticleModule.getOptOut(completion);
};

export const addGDPRConsentState = (
  newConsentState: GDPRConsent,
  purpose: string
): void => {
  MParticleModule.addGDPRConsentState(newConsentState, purpose);
};

export const removeGDPRConsentStateWithPurpose = (purpose: string): void => {
  MParticleModule.removeGDPRConsentStateWithPurpose(purpose);
};

export const setCCPAConsentState = (newConsentState: CCPAConsent): void => {
  MParticleModule.setCCPAConsentState(newConsentState);
};

export const removeCCPAConsentState = (): void => {
  MParticleModule.removeCCPAConsentState();
};

export const isKitActive = (
  kitId: number,
  completion: CompletionCallback<boolean>
): void => {
  MParticleModule.isKitActive(kitId, completion);
};

export const getAttributions = (
  completion: CompletionCallback<AttributionResult>
): void => {
  MParticleModule.getAttributions(completion);
};

export const logPushRegistration = (
  registrationField1: string,
  registrationField2: string
): void => {
  MParticleModule.logPushRegistration(registrationField1, registrationField2);
};

export const getSession = (
  completion: CompletionCallback<string | null>
): void => {
  MParticleModule.getSession(completion);
};

export const setLocation = (latitude: number, longitude: number): void => {
  MParticleModule.setLocation(latitude, longitude);
};

// ******** Identity ********
export class User {
  readonly userId: string;

  constructor(userId: string) {
    this.userId = userId;
  }

  getMpid(): string {
    return this.userId;
  }

  setUserAttribute(
    key: string,
    value: string | string[] | number | boolean
  ): void {
    if (value && value.constructor === Array) {
      MParticleModule.setUserAttributeArray(this.userId, key, value);
    } else {
      MParticleModule.setUserAttribute(this.userId, key, value.toString());
    }
  }

  setUserAttributeArray(key: string, value: string[]): void {
    MParticleModule.setUserAttributeArray(this.userId, key, value);
  }

  getUserAttributes(completion: CompletionCallback<UserAttributes>): void {
    MParticleModule.getUserAttributes(
      this.userId,
      (error: CallbackError | null, result: NativeUserAttributes | null) => {
        if (error?.message) {
          console.log(error.message);
        }
        completion((result as UserAttributes) || {});
      }
    );
  }

  setUserTag(value: string): void {
    MParticleModule.setUserTag(this.userId, value);
  }

  incrementUserAttribute(key: string, value: number): void {
    MParticleModule.incrementUserAttribute(this.userId, key, value);
  }

  removeUserAttribute(key: string): void {
    MParticleModule.removeUserAttribute(this.userId, key);
  }

  getUserIdentities(completion: CompletionCallback<UserIdentities>): void {
    MParticleModule.getUserIdentities(
      this.userId,
      (error: CallbackError | null, result: UserIdentities | null) => {
        if (error?.message) {
          console.log(error.message);
        }
        completion(result || {});
      }
    );
  }

  getFirstSeen(completion: CompletionCallback<string>): void {
    MParticleModule.getFirstSeen(this.userId, completion);
  }

  getLastSeen(completion: CompletionCallback<string>): void {
    MParticleModule.getLastSeen(this.userId, completion);
  }
}

export class IdentityRequest {
  [key: number]: string;
  email?: string;
  customerId?: string;

  setEmail(email: string): this {
    this.email = email;
    this[UserIdentityType.Email] = email;
    return this;
  }

  setCustomerID(customerId: string): this {
    this.customerId = customerId;
    this[UserIdentityType.CustomerId] = customerId;
    return this;
  }

  setUserIdentity(userIdentity: string, identityType: number): this {
    this[identityType] = userIdentity;
    return this;
  }

  /**
   * @deprecated This method is deprecated and will be removed in a future version.
   */
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  setOnUserAlias(_onUserAlias: any): void {
    console.log(
      "Warning: deprecated method 'setUserAlias(onUserAlias)', will be removed in future releases"
    );
  }
}

export class Identity {
  static getCurrentUser(completion: CompletionCallback<User>): void {
    MParticleModule.getCurrentUserWithCompletion(
      (error: CallbackError | null, userId: string | null) => {
        if (error) {
          console.log(error.message);
        }
        const currentUser = new User(userId || '');
        completion(currentUser);
      }
    );
  }

  static identify(
    identityRequest: IdentityRequest,
    completion: IdentityCallback
  ): void {
    MParticleModule.identify(
      identityRequest,
      (
        error: CallbackError | null,
        userId: string | null,
        previousUserId: string | null
      ) => {
        if (error == null || error === undefined) {
          completion(error, userId, previousUserId);
        } else {
          const parsedError = new MParticleError(error);
          completion(parsedError, userId, previousUserId);
        }
      }
    );
  }

  static login(
    identityRequest: IdentityRequest,
    completion: IdentityCallback
  ): void {
    MParticleModule.login(
      identityRequest,
      (
        error: CallbackError | null,
        userId: string | null,
        previousUserId: string | null
      ) => {
        if (error == null || error === undefined) {
          completion(error, userId, previousUserId);
        } else {
          const parsedError = new MParticleError(error);
          completion(parsedError, userId, previousUserId);
        }
      }
    );
  }

  static logout(
    identityRequest: IdentityRequest,
    completion: IdentityCallback
  ): void {
    MParticleModule.logout(
      identityRequest,
      (
        error: CallbackError | null,
        userId: string | null,
        previousUserId: string | null
      ) => {
        if (error == null || error === undefined) {
          completion(error, userId, previousUserId);
        } else {
          const parsedError = new MParticleError(error);
          completion(parsedError, userId, previousUserId);
        }
      }
    );
  }

  static modify(
    identityRequest: IdentityRequest,
    completion: IdentityCallback
  ): void {
    MParticleModule.modify(
      identityRequest,
      (
        error: CallbackError | null,
        userId: string | null,
        previousUserId: string | null
      ) => {
        if (error == null || error === undefined) {
          completion(error, userId, previousUserId);
        } else {
          const parsedError = new MParticleError(error);
          completion(parsedError, userId, previousUserId);
        }
      }
    );
  }

  static aliasUsers(
    aliasRequest: AliasRequest,
    completion: CompletionCallback<boolean>
  ): void {
    MParticleModule.aliasUsers(
      aliasRequest as any,
      (success: boolean, message?: string) => {
        if (message) {
          console.log(message);
        }
        completion(success);
      }
    );
  }
}

// ******** Commerce ********

export class Impression {
  readonly impressionListName: string;
  readonly products: Product[];

  constructor(impressionListName: string, products: Product[]) {
    this.impressionListName = impressionListName;
    this.products = products;
  }
}

export class Promotion {
  readonly id: string;
  readonly name: string;
  readonly creative: string;
  readonly position: string;

  constructor(id: string, name: string, creative: string, position: string) {
    this.id = id;
    this.name = name;
    this.creative = creative;
    this.position = position;
  }
}

export class AliasRequest {
  sourceMpid(mpid: string): this {
    (this as any).sourceMpid = mpid;
    return this;
  }

  destinationMpid(mpid: string): this {
    (this as any).destinationMpid = mpid;
    return this;
  }

  endTime(endTime: number): this {
    (this as any).endTime = endTime;
    return this;
  }

  startTime(startTime: number): this {
    (this as any).startTime = startTime;
    return this;
  }
}

export class TransactionAttributes {
  readonly transactionId: string;
  affiliation?: string;
  revenue?: number;
  shipping?: number;
  tax?: number;
  couponCode?: string;

  constructor(transactionId: string) {
    this.transactionId = transactionId;
  }

  setAffiliation(affiliation: string): this {
    this.affiliation = affiliation;
    return this;
  }

  setRevenue(revenue: string | number): this {
    this.revenue = typeof revenue === 'string' ? parseFloat(revenue) : revenue;
    return this;
  }

  setShipping(shipping: string | number): this {
    this.shipping =
      typeof shipping === 'string' ? parseFloat(shipping) : shipping;
    return this;
  }

  setTax(tax: string | number): this {
    this.tax = typeof tax === 'string' ? parseFloat(tax) : tax;
    return this;
  }

  setCouponCode(couponCode: string): this {
    this.couponCode = couponCode;
    return this;
  }
}

export class Product {
  readonly name: string;
  readonly sku: string;
  readonly price: number;
  readonly quantity: number;
  brand?: string;
  couponCode?: string;
  position?: number;
  category?: string;
  variant?: string;
  customAttributes?: CustomAttributes;

  constructor(name: string, sku: string, price: number, quantity = 1) {
    this.name = name;
    this.sku = sku;
    this.price = price;
    this.quantity = quantity;
  }

  setBrand(brand: string): this {
    this.brand = brand;
    return this;
  }

  setCouponCode(couponCode: string): this {
    this.couponCode = couponCode;
    return this;
  }

  setPosition(position: number): this {
    this.position = position;
    return this;
  }

  setCategory(category: string): this {
    this.category = category;
    return this;
  }

  setVariant(variant: string): this {
    this.variant = variant;
    return this;
  }

  setCustomAttributes(customAttributes: CustomAttributes): this {
    this.customAttributes = customAttributes;
    return this;
  }
}

export class GDPRConsent {
  consented?: boolean;
  document?: string;
  timestamp?: number;
  location?: string;
  hardwareId?: string;

  constructor(
    consented?: boolean,
    doc?: string,
    timestamp?: number,
    location?: string,
    hardwareId?: string
  ) {
    this.consented = consented;
    this.document = doc;
    this.timestamp = timestamp;
    this.location = location;
    this.hardwareId = hardwareId;
  }

  setConsented(consented: boolean): this {
    this.consented = consented;
    return this;
  }

  setDocument(doc: string): this {
    this.document = doc;
    return this;
  }

  setTimestamp(timestamp: number): this {
    this.timestamp = timestamp;
    return this;
  }

  setLocation(location: string): this {
    this.location = location;
    return this;
  }

  setHardwareId(hardwareId: string): this {
    this.hardwareId = hardwareId;
    return this;
  }
}

export class CCPAConsent {
  consented?: boolean;
  document?: string;
  timestamp?: number;
  location?: string;
  hardwareId?: string;

  constructor(
    consented?: boolean,
    doc?: string,
    timestamp?: number,
    location?: string,
    hardwareId?: string
  ) {
    this.consented = consented;
    this.document = doc;
    this.timestamp = timestamp;
    this.location = location;
    this.hardwareId = hardwareId;
  }

  setConsented(consented: boolean): this {
    this.consented = consented;
    return this;
  }

  setDocument(doc: string): this {
    this.document = doc;
    return this;
  }

  setTimestamp(timestamp: number): this {
    this.timestamp = timestamp;
    return this;
  }

  setLocation(location: string): this {
    this.location = location;
    return this;
  }

  setHardwareId(hardwareId: string): this {
    this.hardwareId = hardwareId;
    return this;
  }
}

export class CommerceEvent {
  productActionType?: number;
  promotionActionType?: number;
  products?: Product[];
  transactionAttributes?: TransactionAttributes;
  promotions?: Promotion[];
  impressions?: Impression[];
  screenName?: string;
  currency?: string;
  customAttributes?: CustomAttributes;
  checkoutOptions?: string;
  productActionListName?: string;
  productActionListSource?: string;
  checkoutStep?: number;
  nonInteractive?: boolean;
  shouldUploadEvent?: boolean;

  static createProductActionEvent(
    productActionType: number,
    products: Product[],
    transactionAttributes: TransactionAttributes = new TransactionAttributes('')
  ): CommerceEvent {
    return new CommerceEvent()
      .setProductActionType(productActionType)
      .setProducts(products)
      .setTransactionAttributes(transactionAttributes);
  }

  static createPromotionEvent(
    promotionActionType: number,
    promotions: Promotion[]
  ): CommerceEvent {
    return new CommerceEvent()
      .setPromotionActionType(promotionActionType)
      .setPromotions(promotions);
  }

  static createImpressionEvent(impressions: Impression[]): CommerceEvent {
    return new CommerceEvent().setImpressions(impressions);
  }

  setTransactionAttributes(transactionAttributes: TransactionAttributes): this {
    this.transactionAttributes = transactionAttributes;
    return this;
  }

  setProductActionType(productActionType: number): this {
    this.productActionType = productActionType;
    return this;
  }

  setPromotionActionType(promotionActionType: number): this {
    this.promotionActionType = promotionActionType;
    return this;
  }

  setProducts(products: Product[]): this {
    this.products = products;
    return this;
  }

  setPromotions(promotions: Promotion[]): this {
    this.promotions = promotions;
    return this;
  }

  setImpressions(impressions: Impression[]): this {
    this.impressions = impressions;
    return this;
  }

  setScreenName(screenName: string): this {
    this.screenName = screenName;
    return this;
  }

  setCurrency(currency: string): this {
    this.currency = currency;
    return this;
  }

  setCustomAttributes(customAttributes: CustomAttributes): this {
    this.customAttributes = customAttributes;
    return this;
  }

  setCheckoutOptions(checkoutOptions: string): this {
    this.checkoutOptions = checkoutOptions;
    return this;
  }

  setProductActionListName(productActionListName: string): this {
    this.productActionListName = productActionListName;
    return this;
  }

  setProductActionListSource(productActionListSource: string): this {
    this.productActionListSource = productActionListSource;
    return this;
  }

  setCheckoutStep(checkoutStep: number): this {
    this.checkoutStep = checkoutStep;
    return this;
  }

  setNonInteractive(nonInteractive: boolean): this {
    this.nonInteractive = nonInteractive;
    return this;
  }

  setShouldUploadEvent(shouldUploadEvent: boolean): this {
    this.shouldUploadEvent = shouldUploadEvent;
    return this;
  }
}

export class Event {
  category?: string;
  duration?: number;
  endTime?: number;
  info?: CustomAttributes;
  name?: string;
  startTime?: number;
  type?: number;
  shouldUploadEvent?: boolean;
  customFlags?: { [key: string]: string };

  setCategory(category: string): this {
    this.category = category;
    return this;
  }

  setDuration(duration: number): this {
    this.duration = duration;
    return this;
  }

  setEndTime(endTime: number): this {
    this.endTime = endTime;
    return this;
  }

  setInfo(info: CustomAttributes): this {
    this.info = info;
    return this;
  }

  setName(name: string): this {
    this.name = name;
    return this;
  }

  setStartTime(startTime: number): this {
    this.startTime = startTime;
    return this;
  }

  setType(type: number): this {
    this.type = type;
    return this;
  }

  setShouldUploadEvent(shouldUploadEvent: boolean): this {
    this.shouldUploadEvent = shouldUploadEvent;
    return this;
  }

  setCustomFlags(customFlags: { [key: string]: string }): this {
    this.customFlags = customFlags;
    return this;
  }
}

export class MParticleError {
  readonly message: string;
  readonly code: number;
  readonly httpCode: number;
  readonly responseCode?: number;
  readonly mpid?: string;
  readonly errors?: string;

  constructor(errorResponse: CallbackError | MParticleErrorResponse) {
    this.httpCode = errorResponse.httpCode || 0;
    this.responseCode = errorResponse.responseCode;
    // Handle platform differences in error messages
    this.message =
      errorResponse.message || errorResponse.errors || 'Unknown error';
    this.mpid = errorResponse.mpid;
    this.errors = errorResponse.errors;
    // For backward compatibility with type definitions
    this.code = errorResponse.responseCode || errorResponse.httpCode || 0;
  }
}

// Export Rokt functionality
export type { IRoktConfig, ColorMode, RoktLayoutViewProps };
export { Rokt, CacheConfig, RoktLayoutView };

// ******** Exports ********

const MParticle = {
  EventType, // Constants
  UserIdentityType,
  UserAttributeType,
  ProductActionType,
  PromotionActionType,
  ATTAuthStatus,

  Product, // Classes
  Impression,
  Promotion,
  CommerceEvent,
  TransactionAttributes,
  IdentityRequest,
  AliasRequest,
  Identity,
  User,
  Event,
  MParticleError,
  GDPRConsent,
  CCPAConsent,
  Rokt,
  CacheConfig,
  RoktEventManager,
  RoktLayoutView,

  upload, // Methods
  setUploadInterval,
  logEvent,
  logMPEvent,
  logCommerceEvent,
  logScreenEvent,
  setATTStatus,
  setATTStatusWithCustomTimestamp,
  setOptOut,
  getOptOut,
  addGDPRConsentState,
  removeGDPRConsentStateWithPurpose,
  setCCPAConsentState,
  removeCCPAConsentState,
  isKitActive,
  getAttributions,
  logPushRegistration,
  getSession,
  setLocation,
};

export default MParticle;
