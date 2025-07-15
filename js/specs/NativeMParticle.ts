import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

// Use Object instead of any for Codegen compatibility
export type CustomAttributes = { [key: string]: Object };
export type UserAttributes = { [key: string]: string | string[] | number | boolean | null };
export type UserIdentities = { [key: string]: string };

export interface Product {
    name: string;
    sku: string;
    price: number;
    quantity?: number;
    brand?: string;
    couponCode?: string;
    position?: number;
    category?: string;
    variant?: string;
    customAttributes?: CustomAttributes;
}

export interface TransactionAttributes {
    transactionId: string;
    affiliation?: string;
    revenue?: number;
    shipping?: number;
    tax?: number;
    couponCode?: string;
}

export interface Promotion {
    id: string;
    name: string;
    creative: string;
    position: string;
}

export interface Impression {
    impressionListName: string;
    products: Product[];
}

export interface CommerceEvent {
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
}

export interface Event {
    category?: string;
    duration?: number;
    endTime?: number;
    info?: CustomAttributes;
    name?: string;
    startTime?: number;
    type?: number;
    shouldUploadEvent?: boolean;
    customFlags?: { [key: string]: string };
}

export interface GDPRConsent {
    consented?: boolean;
    document?: string | null;
    timestamp?: number;
    location?: string | null;
    hardwareId?: string | null;
}

export interface CCPAConsent {
    consented?: boolean;
    document?: string | null;
    timestamp?: number;
    location?: string | null;
    hardwareId?: string | null;
}

export interface SessionInfo {
    sessionId: string;
    sessionUuid: string;
    sessionStartTime: number;
}

export type AttributionResult = { [key: string]: Object };

// Error type for callbacks
export interface CallbackError {
    message: string;
    code?: number;
}

// Use string keys for IdentityRequest for Codegen compatibility
export type IdentityRequest = { [key: number]: string };

export interface AliasRequest {
    sourceMpid?: string;
    destinationMpid?: string;
    startTime?: number;
    endTime?: number;
}

export interface IdentityResult {
    userId: string;
    previousUserId: string;
}

export interface Spec extends TurboModule {
    upload(): void;
    setUploadInterval(uploadInterval: number): void;
    logEvent(eventName: string, eventType: number, attributes: CustomAttributes | null): void;
    logMPEvent(event: Event): void;
    logCommerceEvent(commerceEvent: CommerceEvent): void;
    logScreenEvent(screenName: string, attributes: CustomAttributes | null, shouldUploadEvent: boolean): void;
    setATTStatus(status: number): void;
    setATTStatusWithCustomTimestamp(status: number, timestamp: number): void;
    setOptOut(optOut: boolean): void;
    getOptOut(callback: (result: boolean) => void): void;
    addGDPRConsentState(consent: GDPRConsent, purpose: string): void;
    removeGDPRConsentStateWithPurpose(purpose: string): void;
    setCCPAConsentState(consent: CCPAConsent): void;
    removeCCPAConsentState(): void;
    isKitActive(kitId: number, callback: (result: boolean) => void): void;
    getAttributions(callback: (result: AttributionResult) => void): void;
    logPushRegistration(token: string, senderId: string): void;
    getSession(callback: (result: SessionInfo | null) => void): void;
    setLocation(latitude: number, longitude: number): void;

    // User Methods
    setUserAttribute(mpid: string, key: string, value: string): void;
    setUserAttributeArray(mpid: string, key: string, value: Array<string>): void;
    getUserAttributes(mpid: string, callback: (error: CallbackError | null, result: UserAttributes | null) => void): void;
    setUserTag(mpid: string, tag: string): void;
    incrementUserAttribute(mpid: string, key: string, value: number): void;
    removeUserAttribute(mpid: string, key: string): void;
    getUserIdentities(mpid: string, callback: (error: CallbackError | null, result: UserIdentities | null) => void): void;
    getFirstSeen(mpid: string, callback: (result: number) => void): void;
    getLastSeen(mpid: string, callback: (result: number) => void): void;

    // Identity Methods
    getCurrentUserWithCompletion(callback: (error: CallbackError | null, userId: string | null) => void): void;
    identify(identityRequest: IdentityRequest, callback: (error: CallbackError | null, userId: string | null, previousUserId: string | null) => void): void;
    login(identityRequest: IdentityRequest, callback: (error: CallbackError | null, userId: string | null, previousUserId: string | null) => void): void;
    logout(identityRequest: IdentityRequest, callback: (error: CallbackError | null, userId: string | null, previousUserId: string | null) => void): void;
    modify(identityRequest: IdentityRequest, callback: (error: CallbackError | null, userId: string | null, previousUserId: string | null) => void): void;
    aliasUsers(aliasRequest: AliasRequest, callback: () => void): void;
}

export default TurboModuleRegistry.getEnforcing<Spec>('RNMParticle');
