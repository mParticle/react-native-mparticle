declare module 'react-native-mparticle';
export default MParticle;
declare namespace MParticle {
    export { EventType };
    export { UserIdentityType };
    export { UserAttributeType };
    export { ProductActionType };
    export { PromotionActionType };
    export { ATTAuthStatus };
    export { Product };
    export { Impression };
    export { Promotion };
    export { CommerceEvent };
    export { TransactionAttributes };
    export { IdentityRequest };
    export { AliasRequest };
    export { Identity };
    export { User };
    export { Event };
    export { MParticleError };
    export { GDPRConsent };
    export { CCPAConsent };
    export { upload };
    export { setUploadInterval };
    export { logEvent };
    export { logMPEvent };
    export { logCommerceEvent };
    export { logScreenEvent };
    export { setATTStatus };
    export { setATTStatusWithCustomTimestamp };
    export { setOptOut };
    export { getOptOut };
    export { addGDPRConsentState };
    export { removeGDPRConsentStateWithPurpose };
    export { setCCPAConsentState };
    export { removeCCPAConsentState };
    export { isKitActive };
    export { getAttributions };
    export { logPushRegistration };
    export { getSession };
}
declare namespace EventType {
    const Navigation: number;
    const Location: number;
    const Search: number;
    const Transaction: number;
    const UserContent: number;
    const UserPreference: number;
    const Social: number;
    const Other: number;
}
declare namespace UserIdentityType {
    const Other_1: number;
    export { Other_1 as Other };
    export const CustomerId: number;
    export const Facebook: number;
    export const Twitter: number;
    export const Google: number;
    export const Microsoft: number;
    export const Yahoo: number;
    export const Email: number;
    export const Alias: number;
    export const FacebookCustomAudienceId: number;
    export const Other2: number;
    export const Other3: number;
    export const Other4: number;
    export const Other5: number;
    export const Other6: number;
    export const Other7: number;
    export const Other8: number;
    export const Other9: number;
    export const Other10: number;
    export const MobileNumber: number;
    export const PhoneNumber2: number;
    export const PhoneNumber3: number;
    export const IOSAdvertiserId: number;
    export const IOSVendorId: number;
    export const PushToken: number;
    export const DeviceApplicationStamp: number;
}
declare namespace UserAttributeType {
    export const FirstName: string;
    export const LastName: string;
    export const Address: string;
    export const State: string;
    export const City: string;
    export const Zipcode: string;
    export const Country: string;
    export const Age: string;
    export const Gender: string;
    const MobileNumber_1: string;
    export { MobileNumber_1 as MobileNumber };
}
declare namespace ProductActionType {
    const AddToCart: number;
    const RemoveFromCart: number;
    const Checkout: number;
    const CheckoutOption: number;
    const Click: number;
    const ViewDetail: number;
    const Purchase: number;
    const Refund: number;
    const AddToWishlist: number;
    const RemoveFromWishlist: number;
}
declare namespace PromotionActionType {
    export const View: number;
    const Click_1: number;
    export { Click_1 as Click };
}
declare namespace ATTAuthStatus {
    const NotDetermined: number;
    const Restricted: number;
    const Denied: number;
    const Authorized: number;
}
declare class Product {
    constructor(name: any, sku: any, price: any, quantity?: number);
    name: any;
    sku: any;
    price: any;
    quantity: number;
    setBrand(brand: any): Product;
    brand: any;
    setCouponCode(couponCode: any): Product;
    couponCode: any;
    setPosition(position: any): Product;
    position: any;
    setCategory(category: any): Product;
    category: any;
    setVariant(variant: any): Product;
    variant: any;
    setCustomAttributes(customAttributes: any): Product;
    customAttributes: any;
}
declare class Impression {
    constructor(impressionListName: any, products: any);
    impressionListName: any;
    products: any;
}
declare class Promotion {
    constructor(id: any, name: any, creative: any, position: any);
    id: any;
    name: any;
    creative: any;
    position: any;
}
declare class CommerceEvent {
    static createProductActionEvent(productActionType: any, products: any, transactionAttributes?: {}): CommerceEvent;
    static createPromotionEvent(promotionActionType: any, promotions: any): CommerceEvent;
    static createImpressionEvent(impressions: any): CommerceEvent;
    setTransactionAttributes(transactionAttributes: any): CommerceEvent;
    transactionAttributes: any;
    setProductActionType(productActionType: any): CommerceEvent;
    productActionType: any;
    setPromotionActionType(promotionActionType: any): CommerceEvent;
    promotionActionType: any;
    setProducts(products: any): CommerceEvent;
    products: any;
    setPromotions(promotions: any): CommerceEvent;
    promotions: any;
    setImpressions(impressions: any): CommerceEvent;
    impressions: any;
    setScreenName(screenName: any): CommerceEvent;
    screenName: any;
    setCurrency(currency: any): CommerceEvent;
    currency: any;
    setCustomAttributes(customAttributes: any): CommerceEvent;
    customAttributes: any;
    setCheckoutOptions(checkoutOptions: any): CommerceEvent;
    checkoutOptions: any;
    setProductActionListName(productActionListName: any): CommerceEvent;
    productActionListName: any;
    setProductActionListSource(productActionListSource: any): CommerceEvent;
    productActionListSource: any;
    setCheckoutStep(checkoutStep: any): CommerceEvent;
    checkoutStep: any;
    setNonInteractive(nonInteractive: any): CommerceEvent;
    nonInteractive: any;
    setShouldUploadEvent(shouldUploadEvent: any): CommerceEvent;
    shouldUploadEvent: any;
}
declare class TransactionAttributes {
    constructor(transactionId: any);
    transactionId: any;
    setAffiliation(affiliation: any): TransactionAttributes;
    affiliation: any;
    setRevenue(revenue: any): TransactionAttributes;
    revenue: any;
    setShipping(shipping: any): TransactionAttributes;
    shipping: any;
    setTax(tax: any): TransactionAttributes;
    tax: any;
    setCouponCode(couponCode: any): TransactionAttributes;
    couponCode: any;
}
declare class IdentityRequest {
    setEmail(email: any): IdentityRequest;
    setCustomerID(customerId: any): IdentityRequest;
    setUserIdentity(userIdentity: any, identityType: any): IdentityRequest;
    setOnUserAlias(onUserAlias: any): void;
}
declare class AliasRequest {
    sourceMpid(mpid: any): AliasRequest;
    destinationMpid(mpid: any): AliasRequest;
    endTime(mpid: any): AliasRequest;
    startTime(mpid: any): AliasRequest;
}
declare class Identity {
    static getCurrentUser(completion: any): void;
    static identify(IdentityRequest: any, completion: any): void;
    static login(IdentityRequest: any, completion: any): void;
    static logout(IdentityRequest: any, completion: any): void;
    static modify(IdentityRequest: any, completion: any): void;
    static aliasUsers(AliasRequest: any, completion: any): void;
}
declare class User {
    constructor(userId: any);
    userId: any;
    getMpid(): any;
    setUserAttribute(key: any, value: any): void;
    setUserAttributeArray(key: any, value: any): void;
    getUserAttributes(completion: any): void;
    setUserTag(value: any): void;
    incrementUserAttribute(key: any, value: any): void;
    removeUserAttribute(key: any): void;
    getUserIdentities(completion: any): void;
    getFirstSeen(completion: any): void;
    getLastSeen(completion: any): void;
}
declare class Event {
    setCategory(category: any): Event;
    category: any;
    setDuration(duration: any): Event;
    duration: any;
    setEndTime(endTime: any): Event;
    endTime: any;
    setInfo(info: any): Event;
    info: any;
    setName(name: any): Event;
    name: any;
    setStartTime(startTime: any): Event;
    startTime: any;
    setType(type: any): Event;
    type: any;
    setShouldUploadEvent(shouldUploadEvent: any): Event;
    shouldUploadEvent: any;
    setCustomFlags(customFlags: any): Event;
    customFlags: any;
}
declare class MParticleError {
    constructor(errorResponse: any);
    httpCode: any;
    responseCode: any;
    message: any;
    mpid: any;
    errors: any;
}
declare class GDPRConsent {
    constructor(consented: any, doc: any, timestamp: any, location: any, hardwareId: any);
    consented: any;
    document: any;
    timestamp: any;
    location: any;
    hardwareId: any;
    setConsented(consented: any): GDPRConsent;
    setDocument(doc: any): GDPRConsent;
    setTimestamp(timestamp: any): GDPRConsent;
    setLocation(location: any): GDPRConsent;
    setHardwareId(hardwareId: any): GDPRConsent;
}
declare class CCPAConsent {
    constructor(consented: any, doc: any, timestamp: any, location: any, hardwareId: any);
    consented: any;
    document: any;
    timestamp: any;
    location: any;
    hardwareId: any;
    setConsented(consented: any): CCPAConsent;
    setDocument(doc: any): CCPAConsent;
    setTimestamp(timestamp: any): CCPAConsent;
    setLocation(location: any): CCPAConsent;
    setHardwareId(hardwareId: any): CCPAConsent;
}
declare function upload(): void;
declare function setUploadInterval(uploadInterval: any): void;
declare function logEvent(eventName: any, type?: number, attributes?: any): void;
declare function logMPEvent(event: any): void;
declare function logCommerceEvent(commerceEvent: any): void;
declare function logScreenEvent(screenName: any, attributes?: any, shouldUploadEvent?: boolean): void;
declare function setATTStatus(status: any): void;
declare function setATTStatusWithCustomTimestamp(status: any, timestamp: any): void;
declare function setOptOut(optOut: any): void;
declare function getOptOut(completion: any): void;
declare function addGDPRConsentState(newConsentState: any, purpose: any): void;
declare function removeGDPRConsentStateWithPurpose(purpose: any): void;
declare function setCCPAConsentState(newConsentState: any): void;
declare function removeCCPAConsentState(): void;
declare function isKitActive(kitId: any, completion: any): void;
declare function getAttributions(completion: any): void;
declare function logPushRegistration(registrationField1: any, registrationField2: any): void;
declare function getSession(completion: any): void;
