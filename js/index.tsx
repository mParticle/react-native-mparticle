import { NativeModules } from 'react-native';
import {
    Rokt,
    RoktConfigBuilder,
    CacheConfig,
    RoktEventManager,
} from './rokt/rokt';
import RoktLayoutView from './rokt/rokt-layout-view';
import type { Spec } from './specs/NativeMParticle';

const MParticleModule: Spec = NativeModules.MParticle;

// ******** Types ********
export interface UserAttributes {
    [key: string]: string | string[] | number | boolean | null;
}

export interface UserIdentities {
    [key: number]: string;
}

export interface CustomAttributes {
    [key: string]: string | number | boolean;
}

export interface MParticleErrorResponse {
    httpCode: number;
    responseCode: number;
    message: string;
    mpid: string;
    errors: any[];
}

export interface AttributionResult {
    [key: string]: any;
}

export interface SessionInfo {
    sessionId: string;
    sessionUuid: string;
    sessionStartTime: number;
}

export type CompletionCallback<T> = (result: T) => void;
export type IdentityCallback = (
    error: MParticleError | null,
    userId: string | null,
    previousUserId: string | null,
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

const upload = (): void => {
    MParticleModule.upload();
};

const setUploadInterval = (uploadInterval: number): void => {
    MParticleModule.setUploadInterval(uploadInterval);
};

const logEvent = (
    eventName: string,
    type: number = EventType.Other,
    attributes: CustomAttributes | null = null,
): void => {
    MParticleModule.logEvent(eventName, type, attributes);
};

const logMPEvent = (event: Event): void => {
    MParticleModule.logMPEvent(event);
};

const logCommerceEvent = (commerceEvent: CommerceEvent): void => {
    MParticleModule.logCommerceEvent(commerceEvent);
};

const logScreenEvent = (
    screenName: string,
    attributes: CustomAttributes | null = null,
    shouldUploadEvent = true,
): void => {
    MParticleModule.logScreenEvent(screenName, attributes, shouldUploadEvent);
};

// Use ATTAuthStatus constants for status
const setATTStatus = (status: number): void => {
    MParticleModule.setATTStatus(status);
};

const setATTStatusWithCustomTimestamp = (
    status: number,
    timestamp: number,
): void => {
    MParticleModule.setATTStatusWithCustomTimestamp(status, timestamp);
};

const setOptOut = (optOut: boolean): void => {
    MParticleModule.setOptOut(optOut);
};

const getOptOut = (completion: CompletionCallback<boolean>): void => {
    MParticleModule.getOptOut(completion);
};

const addGDPRConsentState = (
    newConsentState: GDPRConsent,
    purpose: string,
): void => {
    MParticleModule.addGDPRConsentState(newConsentState, purpose);
};

const removeGDPRConsentStateWithPurpose = (purpose: string): void => {
    MParticleModule.removeGDPRConsentStateWithPurpose(purpose);
};

const setCCPAConsentState = (newConsentState: CCPAConsent): void => {
    MParticleModule.setCCPAConsentState(newConsentState);
};

const removeCCPAConsentState = (): void => {
    MParticleModule.removeCCPAConsentState();
};

const isKitActive = (
    kitId: number,
    completion: CompletionCallback<boolean>,
): void => {
    MParticleModule.isKitActive(kitId, completion);
};

const getAttributions = (
    completion: CompletionCallback<AttributionResult>,
): void => {
    MParticleModule.getAttributions(completion);
};

const logPushRegistration = (
    registrationField1: string,
    registrationField2: string,
): void => {
    MParticleModule.logPushRegistration(registrationField1, registrationField2);
};

const getSession = (completion: CompletionCallback<SessionInfo | null>): void => {
    MParticleModule.getSession(completion);
};

const setLocation = (latitude: number, longitude: number): void => {
    MParticleModule.setLocation(latitude, longitude);
};

// ******** Identity ********
class User {
    userId: string;
    constructor(userId: string) {
        this.userId = userId;
    }

    getMpid(): string {
        return this.userId;
    }

    setUserAttribute(key: string, value: string | number | boolean | string[]) {
        if (Array.isArray(value)) {
            MParticleModule.setUserAttributeArray(this.userId, key, value);
        } else {
            MParticleModule.setUserAttribute(this.userId, key, value);
        }
    }

    setUserAttributeArray(key: string, value: string[]) {
        MParticleModule.setUserAttributeArray(this.userId, key, value);
    }

    getUserAttributes(
        completion: CompletionCallback<UserAttributes | null>,
    ): void {
        MParticleModule.getUserAttributes(this.userId, (error, userAttributes) => {
            if (error) {
                console.log(error);
            }
            completion(userAttributes);
        });
    }

    setUserTag(value: string) {
        MParticleModule.setUserTag(this.userId, value);
    }

    incrementUserAttribute(key: string, value: number) {
        MParticleModule.incrementUserAttribute(this.userId, key, value);
    }

    removeUserAttribute(key: string) {
        MParticleModule.removeUserAttribute(this.userId, key);
    }

    getUserIdentities(
        completion: CompletionCallback<UserIdentities | null>,
    ): void {
        MParticleModule.getUserIdentities(
            this.userId,
            (error, userIdentities) => {
                if (error) {
                    console.log(error);
                }
                completion(userIdentities);
            },
        );
    }

    getFirstSeen(completion: CompletionCallback<number>): void {
        MParticleModule.getFirstSeen(this.userId, completion);
    }

    getLastSeen(completion: CompletionCallback<number>): void {
        MParticleModule.getLastSeen(this.userId, completion);
    }
}

class IdentityRequest {
    [key: number]: string;
    setEmail(email: string) {
        this[UserIdentityType.Email] = email;
        return this;
    }

    setCustomerID(customerId: string) {
        this[UserIdentityType.CustomerId] = customerId;
        return this;
    }

    setUserIdentity(userIdentity: string, identityType: number) {
        this[identityType] = userIdentity;
        return this;
    }

    setOnUserAlias() {
        console.log(
            "Warning: deprecated method 'setUserAlias(onUserAlias)', will be removed in future releases",
        );
    }
}

class Identity {
    static getCurrentUser(completion: CompletionCallback<User | null>): void {
        MParticleModule.getCurrentUserWithCompletion((error, userId) => {
            if (error) {
                console.log(error);
            }
            const currentUser = userId ? new User(userId) : null;
            completion(currentUser);
        });
    }

    static identify(
        identityRequest: IdentityRequest,
        completion: IdentityCallback,
    ): void {
        MParticleModule.identify(
            identityRequest,
            (error, userId, previousUserId) => {
                if (error == null || error === undefined) {
                    completion(null, userId, previousUserId);
                } else {
                    const parsedError = new MParticleError({
                        httpCode: 0,
                        responseCode: error.code || 0,
                        message: error.message || 'Unknown error',
                        mpid: '',
                        errors: []
                    });
                    completion(parsedError, userId, previousUserId);
                }
            },
        );
    }

    static login(
        identityRequest: IdentityRequest,
        completion: IdentityCallback,
    ): void {
        MParticleModule.login(identityRequest, (error, userId, previousUserId) => {
            if (error == null || error === undefined) {
                completion(null, userId, previousUserId);
            } else {
                const parsedError = new MParticleError({
                    httpCode: 0,
                    responseCode: error.code || 0,
                    message: error.message || 'Unknown error',
                    mpid: '',
                    errors: []
                });
                completion(parsedError, userId, previousUserId);
            }
        });
    }

    static logout(
        identityRequest: IdentityRequest,
        completion: IdentityCallback,
    ): void {
        MParticleModule.logout(identityRequest, (error, userId, previousUserId) => {
            if (error == null || error === undefined) {
                completion(null, userId, previousUserId);
            } else {
                const parsedError = new MParticleError({
                    httpCode: 0,
                    responseCode: error.code || 0,
                    message: error.message || 'Unknown error',
                    mpid: '',
                    errors: []
                });
                completion(parsedError, userId, previousUserId);
            }
        });
    }

    static modify(
        identityRequest: IdentityRequest,
        completion: IdentityCallback,
    ): void {
        MParticleModule.modify(identityRequest, (error, userId, previousUserId) => {
            if (error == null || error === undefined) {
                completion(null, userId, previousUserId);
            } else {
                const parsedError = new MParticleError({
                    httpCode: 0,
                    responseCode: error.code || 0,
                    message: error.message || 'Unknown error',
                    mpid: '',
                    errors: []
                });
                completion(parsedError, userId, previousUserId);
            }
        });
    }

    static aliasUsers(
        aliasRequest: AliasRequest,
        completion: CompletionCallback<void>,
    ): void {
        MParticleModule.aliasUsers(aliasRequest as any, completion);
    }
}

// ******** Commerce ********

class Impression {
    impressionListName: string;
    products: Product[];
    constructor(impressionListName: string, products: Product[]) {
        this.impressionListName = impressionListName;
        this.products = products;
    }
}

class Promotion {
    id: string;
    name: string;
    creative: string;
    position: string;
    constructor(id: string, name: string, creative: string, position: string) {
        this.id = id;
        this.name = name;
        this.creative = creative;
        this.position = position;
    }
}

class AliasRequest {
    // Builder methods that match the expected API
    sourceMpid(mpid: string): AliasRequest {
        (this as any).sourceMpid = mpid;
        return this;
    }

    destinationMpid(mpid: string): AliasRequest {
        (this as any).destinationMpid = mpid;
        return this;
    }

    startTime(time: number): AliasRequest {
        (this as any).startTime = time;
        return this;
    }

    endTime(time: number): AliasRequest {
        (this as any).endTime = time;
        return this;
    }
}

class TransactionAttributes {
    transactionId: string;
    affiliation?: string;
    revenue?: number;
    shipping?: number;
    tax?: number;
    couponCode?: string;

    constructor(transactionId: string) {
        this.transactionId = transactionId;
    }

    setAffiliation(affiliation: string) {
        this.affiliation = affiliation;
        return this;
    }

    setRevenue(revenue: string | number) {
        this.revenue = typeof revenue === 'string' ? parseFloat(revenue) : revenue;
        return this;
    }

    setShipping(shipping: string | number) {
        this.shipping =
            typeof shipping === 'string' ? parseFloat(shipping) : shipping;
        return this;
    }

    setTax(tax: string | number) {
        this.tax = typeof tax === 'string' ? parseFloat(tax) : tax;
        return this;
    }

    setCouponCode(couponCode: string) {
        this.couponCode = couponCode;
        return this;
    }
}

class Product {
    name: string;
    sku: string;
    price: number;
    quantity: number;
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

    setBrand(brand: string) {
        this.brand = brand;
        return this;
    }

    setCouponCode(couponCode: string) {
        this.couponCode = couponCode;
        return this;
    }

    setPosition(position: number) {
        this.position = position;
        return this;
    }

    setCategory(category: string) {
        this.category = category;
        return this;
    }

    setVariant(variant: string) {
        this.variant = variant;
        return this;
    }

    setCustomAttributes(customAttributes: CustomAttributes) {
        this.customAttributes = customAttributes;
        return this;
    }
}

class GDPRConsent {
    consented: boolean;
    document?: string | null;
    timestamp: number;
    location?: string | null;
    hardwareId?: string | null;

    constructor(
        consented: boolean,
        doc?: string | null,
        timestamp?: number,
        location?: string | null,
        hardwareId?: string | null,
    ) {
        this.consented = consented;
        this.document = doc;
        this.timestamp = timestamp ?? Date.now();
        this.location = location;
        this.hardwareId = hardwareId;
    }

    setConsented(consented: boolean) {
        this.consented = consented;
        return this;
    }

    setDocument(doc: string) {
        this.document = doc;
        return this;
    }

    setTimestamp(timestamp: number) {
        this.timestamp = timestamp;
        return this;
    }

    setLocation(location: string) {
        this.location = location;
        return this;
    }

    setHardwareId(hardwareId: string) {
        this.hardwareId = hardwareId;
        return this;
    }
}

class CCPAConsent {
    consented: boolean;
    document?: string | null;
    timestamp: number;
    location?: string | null;
    hardwareId?: string | null;

    constructor(
        consented: boolean,
        doc?: string | null,
        timestamp?: number,
        location?: string | null,
        hardwareId?: string | null,
    ) {
        this.consented = consented;
        this.document = doc;
        this.timestamp = timestamp ?? Date.now();
        this.location = location;
        this.hardwareId = hardwareId;
    }

    setConsented(consented: boolean) {
        this.consented = consented;
        return this;
    }

    setDocument(doc: string) {
        this.document = doc;
        return this;
    }

    setTimestamp(timestamp: number) {
        this.timestamp = timestamp;
        return this;
    }

    setLocation(location: string) {
        this.location = location;
        return this;
    }

    setHardwareId(hardwareId: string) {
        this.hardwareId = hardwareId;
        return this;
    }
}

class CommerceEvent {
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
        transactionAttributes: TransactionAttributes = {} as TransactionAttributes,
    ) {
        return new CommerceEvent()
            .setProductActionType(productActionType)
            .setProducts(products)
            .setTransactionAttributes(transactionAttributes);
    }

    static createPromotionEvent(
        promotionActionType: number,
        promotions: Promotion[],
    ) {
        return new CommerceEvent()
            .setPromotionActionType(promotionActionType)
            .setPromotions(promotions);
    }

    static createImpressionEvent(impressions: Impression[]) {
        return new CommerceEvent().setImpressions(impressions);
    }

    setTransactionAttributes(transactionAttributes: TransactionAttributes) {
        this.transactionAttributes = transactionAttributes;
        return this;
    }

    setProductActionType(productActionType: number) {
        this.productActionType = productActionType;
        return this;
    }

    setPromotionActionType(promotionActionType: number) {
        this.promotionActionType = promotionActionType;
        return this;
    }

    setProducts(products: Product[]) {
        this.products = products;
        return this;
    }

    setPromotions(promotions: Promotion[]) {
        this.promotions = promotions;
        return this;
    }

    setImpressions(impressions: Impression[]) {
        this.impressions = impressions;
        return this;
    }

    setScreenName(screenName: string) {
        this.screenName = screenName;
        return this;
    }

    setCurrency(currency: string) {
        this.currency = currency;
        return this;
    }

    setCustomAttributes(customAttributes: CustomAttributes) {
        this.customAttributes = customAttributes;
        return this;
    }

    setCheckoutOptions(checkoutOptions: string) {
        this.checkoutOptions = checkoutOptions;
        return this;
    }

    setProductActionListName(productActionListName: string) {
        this.productActionListName = productActionListName;
        return this;
    }

    setProductActionListSource(productActionListSource: string) {
        this.productActionListSource = productActionListSource;
        return this;
    }

    setCheckoutStep(checkoutStep: number) {
        this.checkoutStep = checkoutStep;
        return this;
    }

    setNonInteractive(nonInteractive: boolean) {
        this.nonInteractive = nonInteractive;
        return this;
    }

    setShouldUploadEvent(shouldUploadEvent: boolean) {
        this.shouldUploadEvent = shouldUploadEvent;
        return this;
    }
}

class Event {
    category?: string;
    duration?: number;
    endTime?: number;
    info?: CustomAttributes;
    name?: string;
    startTime?: number;
    type?: number;
    shouldUploadEvent?: boolean;
    customFlags?: { [key: string]: string };

    setCategory(category: string) {
        this.category = category;
        return this;
    }

    setDuration(duration: number) {
        this.duration = duration;
        return this;
    }

    setEndTime(endTime: number) {
        this.endTime = endTime;
        return this;
    }

    setInfo(info: CustomAttributes) {
        this.info = info;
        return this;
    }

    setName(name: string) {
        this.name = name;
        return this;
    }

    setStartTime(startTime: number) {
        this.startTime = startTime;
        return this;
    }

    setType(type: number) {
        this.type = type;
        return this;
    }

    setShouldUploadEvent(shouldUploadEvent: boolean) {
        this.shouldUploadEvent = shouldUploadEvent;
        return this;
    }

    setCustomFlags(customFlags: { [key: string]: string }) {
        this.customFlags = customFlags;
        return this;
    }
}

class MParticleError {
    httpCode: number;
    responseCode: number;
    message: string;
    mpid: string;
    errors: any[];
    constructor(errorResponse: MParticleErrorResponse) {
        this.httpCode = errorResponse.httpCode;
        this.responseCode = errorResponse.responseCode;
        this.message = errorResponse.message;
        this.mpid = errorResponse.mpid;
        this.errors = errorResponse.errors;
    }
}

// ******** Exports ********

const MParticle = {
    // Constants
    EventType,
    UserIdentityType,
    UserAttributeType,
    ProductActionType,
    PromotionActionType,
    ATTAuthStatus,

    // Classes
    Product,
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
    RoktConfigBuilder,
    CacheConfig,
    RoktEventManager,
    RoktLayoutView,

    // Methods
    upload,
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

// Expose RoktEventManager utilities as named exports for convenience
export { RoktEventManager };