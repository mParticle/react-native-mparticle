import {
  Rokt,
  CacheConfig,
  IRoktConfig,
  ColorMode,
  RoktEventManager,
} from './rokt/rokt';
import RoktLayoutView, { RoktLayoutViewProps } from './rokt/rokt-layout-view';

// ******** Types ********
export interface UserAttributes {
  [key: string]: string | string[] | number | boolean;
}

export interface UserIdentities {
  [key: number]: string;
}

export interface CustomAttributes {
  [key: string]: string | number | boolean;
}

export interface MParticleErrorResponse {
  message: string;
  code: number;
}

export interface AttributionResult {
  [key: string]: any;
}

export type CompletionCallback<T> = (result: T) => void;
export type ErrorCallback = (error: MParticleError | null) => void;
export type IdentityCallback = (
  error: MParticleError | null,
  userId: string | null,
  previousUserId: string | null
) => void;

// ******** Constants ********
export declare const EventType: {
  readonly Navigation: 1;
  readonly Location: 2;
  readonly Search: 3;
  readonly Transaction: 4;
  readonly UserContent: 5;
  readonly UserPreference: 6;
  readonly Social: 7;
  readonly Other: 8;
  readonly Media: 9;
};

export declare const UserAttributeType: {
  readonly FirstName: '$FirstName';
  readonly LastName: '$LastName';
  readonly Address: '$Address';
  readonly State: '$State';
  readonly City: '$City';
  readonly Zipcode: '$Zip';
  readonly Country: '$Country';
  readonly Age: '$Age';
  readonly Gender: '$Gender';
  readonly MobileNumber: '$Mobile';
};

export declare const UserIdentityType: {
  readonly Other: 0;
  readonly CustomerId: 1;
  readonly Facebook: 2;
  readonly Twitter: 3;
  readonly Google: 4;
  readonly Microsoft: 5;
  readonly Yahoo: 6;
  readonly Email: 7;
  readonly Alias: 8;
  readonly FacebookCustomAudienceId: 9;
  readonly Other2: 10;
  readonly Other3: 11;
  readonly Other4: 12;
  readonly Other5: 13;
  readonly Other6: 14;
  readonly Other7: 15;
  readonly Other8: 16;
  readonly Other9: 17;
  readonly Other10: 18;
  readonly MobileNumber: 19;
  readonly PhoneNumber2: 20;
  readonly PhoneNumber3: 21;
  readonly IOSAdvertiserId: 22;
  readonly IOSVendorId: 23;
  readonly PushToken: 24;
  readonly DeviceApplicationStamp: 25;
};

export declare const ProductActionType: {
  readonly AddToCart: 1;
  readonly RemoveFromCart: 2;
  readonly Checkout: 3;
  readonly CheckoutOption: 4;
  readonly Click: 5;
  readonly ViewDetail: 6;
  readonly Purchase: 7;
  readonly Refund: 8;
  readonly AddToWishlist: 9;
  readonly RemoveFromWishlist: 10;
};

export declare const PromotionActionType: {
  readonly View: 0;
  readonly Click: 1;
};

export declare const ATTAuthStatus: {
  readonly NotDetermined: 0;
  readonly Restricted: 1;
  readonly Denied: 2;
  readonly Authorized: 3;
};

// ******** Main API ********
export declare const upload: () => void;
export declare const setUploadInterval: (uploadInterval: number) => void;
export declare const logEvent: (
  eventName: string,
  type?: number,
  attributes?: CustomAttributes | null
) => void;
export declare const logMPEvent: (event: Event) => void;
export declare const logCommerceEvent: (commerceEvent: CommerceEvent) => void;
export declare const logScreenEvent: (
  screenName: string,
  attributes?: CustomAttributes | null,
  shouldUploadEvent?: boolean
) => void;
export declare const setATTStatus: (status: number) => void;
export declare const setATTStatusWithCustomTimestamp: (
  status: number,
  timestamp: number
) => void;
export declare const setOptOut: (optOut: boolean) => void;
export declare const getOptOut: (
  completion: CompletionCallback<boolean>
) => void;
export declare const addGDPRConsentState: (
  newConsentState: GDPRConsent,
  purpose: string
) => void;
export declare const removeGDPRConsentStateWithPurpose: (
  purpose: string
) => void;
export declare const setCCPAConsentState: (
  newConsentState: CCPAConsent
) => void;
export declare const removeCCPAConsentState: () => void;
export declare const isKitActive: (
  kitId: number,
  completion: CompletionCallback<boolean>
) => void;
export declare const getAttributions: (
  completion: CompletionCallback<AttributionResult>
) => void;
export declare const logPushRegistration: (
  registrationField1: string,
  registrationField2: string
) => void;
export declare const getSession: (
  completion: CompletionCallback<string>
) => void;
export declare const setLocation: (latitude: number, longitude: number) => void;

// ******** Identity ********
export declare class User {
  readonly userId: string;
  constructor(userId: string);
  getMpid(): string;
  setUserAttribute(
    key: string,
    value: string | string[] | number | boolean
  ): void;
  setUserAttributeArray(key: string, value: string[]): void;
  getUserAttributes(completion: CompletionCallback<UserAttributes>): void;
  setUserTag(value: string): void;
  incrementUserAttribute(key: string, value: number): void;
  removeUserAttribute(key: string): void;
  getUserIdentities(completion: CompletionCallback<UserIdentities>): void;
  getFirstSeen(completion: CompletionCallback<number>): void;
  getLastSeen(completion: CompletionCallback<number>): void;
}

export declare class IdentityRequest {
  [key: number]: string;
  setEmail(email: string): this;
  setCustomerID(customerId: string): this;
  setUserIdentity(userIdentity: string, identityType: number): this;
  /**
   * @deprecated This method is deprecated and will be removed in a future version.
   */
  setOnUserAlias(onUserAlias: any): void;
}

export declare class Identity {
  static getCurrentUser(completion: CompletionCallback<User>): void;
  static identify(
    identityRequest: IdentityRequest,
    completion: IdentityCallback
  ): void;
  static login(
    identityRequest: IdentityRequest,
    completion: IdentityCallback
  ): void;
  static logout(
    identityRequest: IdentityRequest,
    completion: IdentityCallback
  ): void;
  static modify(
    identityRequest: IdentityRequest,
    completion: IdentityCallback
  ): void;
  static aliasUsers(
    aliasRequest: AliasRequest,
    completion: CompletionCallback<void>
  ): void;
}

// ******** Commerce ********
export declare class Impression {
  readonly impressionListName: string;
  readonly products: Product[];
  constructor(impressionListName: string, products: Product[]);
}

export declare class Promotion {
  readonly id: string;
  readonly name: string;
  readonly creative: string;
  readonly position: string;
  constructor(id: string, name: string, creative: string, position: string);
}

export declare class AliasRequest {
  sourceMpid(mpid: string): this;
  destinationMpid(mpid: string): this;
  endTime(endTime: number): this;
  startTime(startTime: number): this;
}

export declare class TransactionAttributes {
  readonly transactionId: string;
  affiliation?: string;
  revenue?: number;
  shipping?: number;
  tax?: number;
  couponCode?: string;
  constructor(transactionId: string);
  setAffiliation(affiliation: string): this;
  setRevenue(revenue: string | number): this;
  setShipping(shipping: string | number): this;
  setTax(tax: string | number): this;
  setCouponCode(couponCode: string): this;
}

export declare class Product {
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
  constructor(name: string, sku: string, price: number, quantity?: number);
  setBrand(brand: string): this;
  setCouponCode(couponCode: string): this;
  setPosition(position: number): this;
  setCategory(category: string): this;
  setVariant(variant: string): this;
  setCustomAttributes(customAttributes: CustomAttributes): this;
}

export declare class GDPRConsent {
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
  );
  setConsented(consented: boolean): this;
  setDocument(doc: string): this;
  setTimestamp(timestamp: number): this;
  setLocation(location: string): this;
  setHardwareId(hardwareId: string): this;
}

export declare class CCPAConsent {
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
  );
  setConsented(consented: boolean): this;
  setDocument(doc: string): this;
  setTimestamp(timestamp: number): this;
  setLocation(location: string): this;
  setHardwareId(hardwareId: string): this;
}

export declare class CommerceEvent {
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
    transactionAttributes?: TransactionAttributes
  ): CommerceEvent;
  static createPromotionEvent(
    promotionActionType: number,
    promotions: Promotion[]
  ): CommerceEvent;
  static createImpressionEvent(impressions: Impression[]): CommerceEvent;
  setTransactionAttributes(transactionAttributes: TransactionAttributes): this;
  setProductActionType(productActionType: number): this;
  setPromotionActionType(promotionActionType: number): this;
  setProducts(products: Product[]): this;
  setPromotions(promotions: Promotion[]): this;
  setImpressions(impressions: Impression[]): this;
  setScreenName(screenName: string): this;
  setCurrency(currency: string): this;
  setCustomAttributes(customAttributes: CustomAttributes): this;
  setCheckoutOptions(checkoutOptions: string): this;
  setProductActionListName(productActionListName: string): this;
  setProductActionListSource(productActionListSource: string): this;
  setCheckoutStep(checkoutStep: number): this;
  setNonInteractive(nonInteractive: boolean): this;
  setShouldUploadEvent(shouldUploadEvent: boolean): this;
}

export declare class Event {
  category?: string;
  duration?: number;
  endTime?: number;
  info?: CustomAttributes;
  name?: string;
  startTime?: number;
  type?: number;
  shouldUploadEvent?: boolean;
  customFlags?: { [key: string]: string };
  setCategory(category: string): this;
  setDuration(duration: number): this;
  setEndTime(endTime: number): this;
  setInfo(info: CustomAttributes): this;
  setName(name: string): this;
  setStartTime(startTime: number): this;
  setType(type: number): this;
  setShouldUploadEvent(shouldUploadEvent: boolean): this;
  setCustomFlags(customFlags: { [key: string]: string }): this;
}

export declare class MParticleError {
  readonly message: string;
  readonly code: number;
  constructor(errorResponse: MParticleErrorResponse);
}

// Export Rokt functionality
export {
  Rokt,
  CacheConfig,
  IRoktConfig,
  ColorMode,
  RoktLayoutView,
  RoktLayoutViewProps,
  RoktEventManager,
};

// Default export
declare const _default: {
  EventType: typeof EventType;
  UserAttributeType: typeof UserAttributeType;
  UserIdentityType: typeof UserIdentityType;
  ProductActionType: typeof ProductActionType;
  PromotionActionType: typeof PromotionActionType;
  ATTAuthStatus: typeof ATTAuthStatus;
  upload: typeof upload;
  setUploadInterval: typeof setUploadInterval;
  logEvent: typeof logEvent;
  logMPEvent: typeof logMPEvent;
  logCommerceEvent: typeof logCommerceEvent;
  logScreenEvent: typeof logScreenEvent;
  setATTStatus: typeof setATTStatus;
  setATTStatusWithCustomTimestamp: typeof setATTStatusWithCustomTimestamp;
  setOptOut: typeof setOptOut;
  getOptOut: typeof getOptOut;
  addGDPRConsentState: typeof addGDPRConsentState;
  removeGDPRConsentStateWithPurpose: typeof removeGDPRConsentStateWithPurpose;
  setCCPAConsentState: typeof setCCPAConsentState;
  removeCCPAConsentState: typeof removeCCPAConsentState;
  isKitActive: typeof isKitActive;
  getAttributions: typeof getAttributions;
  logPushRegistration: typeof logPushRegistration;
  getSession: typeof getSession;
  setLocation: typeof setLocation;
  User: typeof User;
  IdentityRequest: typeof IdentityRequest;
  Identity: typeof Identity;
  Impression: typeof Impression;
  Promotion: typeof Promotion;
  AliasRequest: typeof AliasRequest;
  TransactionAttributes: typeof TransactionAttributes;
  Product: typeof Product;
  GDPRConsent: typeof GDPRConsent;
  CCPAConsent: typeof CCPAConsent;
  CommerceEvent: typeof CommerceEvent;
  Event: typeof Event;
  MParticleError: typeof MParticleError;
  Rokt: typeof Rokt;
  CacheConfig: typeof CacheConfig;
  RoktLayoutView: typeof RoktLayoutView;
  RoktEventManager: typeof RoktEventManager;
};

export default _default;
