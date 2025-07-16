#import "RNMParticle.h"
#import <React/RCTConvert.h>
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK/mParticle.h>)
    #import <mParticle_Apple_SDK/mParticle.h>
#elif defined(__has_include) && __has_include(<mParticle_Apple_SDK_NoLocation/mParticle.h>)
    #import <mParticle_Apple_SDK_NoLocation/mParticle.h>
#else
    #import <mParticle_Apple_SDK/Include/mParticle.h>
#endif
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK/mParticle_Apple_SDK-Swift.h>)
    #import <mParticle_Apple_SDK/mParticle_Apple_SDK-Swift.h>
#elif defined(__has_include) && __has_include(<mParticle_Apple_SDK_NoLocation/mParticle_Apple_SDK-Swift.h>)
    #import <mParticle_Apple_SDK_NoLocation/mParticle_Apple_SDK-Swift.h>
#else
    #import "mParticle_Apple_SDK-Swift.h"
#endif
#import <React/RCTConvert.h>

#ifdef RCT_NEW_ARCH_ENABLED
#import <RNMParticle/RNMParticle.h>
#endif

@interface MParticleUser ()

- (void)setUserId:(NSNumber *)userId;
@end

@implementation RNMParticle

RCT_EXTERN void RCTRegisterModule(Class);

+ (NSString *)moduleName {
    return @"RNMParticle";
}

+ (void)load {
    RCTRegisterModule(self);
}

RCT_EXPORT_METHOD(upload)
{
    [[MParticle sharedInstance] upload];
}

RCT_EXPORT_METHOD(setLocation:(double)latitude longitude:(double)longitude)
{
    CLLocation *newLocation = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
    [MParticle sharedInstance].location = newLocation;
}

RCT_EXPORT_METHOD(setUploadInterval:(double)uploadInterval)
{
    [[MParticle sharedInstance] setUploadInterval:uploadInterval];
}

RCT_EXPORT_METHOD(logEvent:(NSString *)eventName eventType:(double)eventType attributes:(NSDictionary *)attributes)
{
    [[MParticle sharedInstance] logEvent:eventName eventType:(MPEventType)eventType eventInfo:attributes];
}

RCT_EXPORT_METHOD(logScreenEvent:(NSString *)screenName attributes:(NSDictionary *)attributes shouldUploadEvent:(BOOL)shouldUploadEvent)
{
    [[MParticle sharedInstance] logScreen:screenName eventInfo:attributes shouldUploadEvent:shouldUploadEvent];
}

RCT_EXPORT_METHOD(setATTStatus:(double)status withATTStatusTimestampMillis:(nonnull NSNumber *)timestamp)
{
    [[MParticle sharedInstance] setATTStatus:(MPATTAuthorizationStatus)status withATTStatusTimestampMillis:timestamp];
}

RCT_EXPORT_METHOD(setATTStatus:(double)status)
{
    [[MParticle sharedInstance] setATTStatus:(MPATTAuthorizationStatus)status withATTStatusTimestampMillis:nil];
}

RCT_EXPORT_METHOD(setOptOut:(BOOL)optOut)
{
    [[MParticle sharedInstance] setOptOut:optOut];
}

RCT_EXPORT_METHOD(getOptOut:(RCTResponseSenderBlock)completion)
{
    BOOL optedOut = [[MParticle sharedInstance] optOut];
    completion(@[[NSNumber numberWithBool:optedOut]]);
}

RCT_EXPORT_METHOD(removeGDPRConsentStateWithPurpose:(NSString *)purpose)
{
    MParticleUser *user = [MParticle sharedInstance].identity.currentUser;

    MPConsentState *consentState = user.consentState ? user.consentState : [[MPConsentState alloc] init];
    [consentState removeGDPRConsentStateWithPurpose:purpose];
    user.consentState = consentState;
}

RCT_EXPORT_METHOD(removeCCPAConsentState)
{
    MParticleUser *user = [MParticle sharedInstance].identity.currentUser;

    MPConsentState *consentState = user.consentState ? user.consentState : [[MPConsentState alloc] init];
    [consentState removeCCPAConsentState];
    user.consentState = consentState;
}

#if TARGET_OS_IOS == 1
RCT_EXPORT_METHOD(logPushRegistration:(NSString *)token senderId:(NSString *)senderId)
{
    if (token != nil) {
        NSData* pushTokenData = [token dataUsingEncoding:NSUTF8StringEncoding];
        MParticle* instance = [MParticle sharedInstance];
        instance.pushNotificationToken = pushTokenData;
    }
}
#endif

RCT_EXPORT_METHOD(isKitActive:(double)kitId callback:(RCTResponseSenderBlock)callback)
{
    BOOL active = [[MParticle sharedInstance] isKitActive:@(kitId)];
    callback(@[[NSNumber numberWithBool:active]]);
}

RCT_EXPORT_METHOD(getAttributions:(RCTResponseSenderBlock)callback)
{
    NSDictionary<NSNumber *, MPAttributionResult *> *attributions = [[MParticle sharedInstance]attributionInfo];
    NSMutableDictionary*dictionary = [[NSMutableDictionary alloc]init];
    for (NSNumber *kitId in attributions) {
        MPAttributionResult *attributionResult = attributions[kitId];
        NSMutableDictionary *attributionDict = [[NSMutableDictionary alloc]initWithCapacity:2];
        if (attributionResult.linkInfo != nil) {
            attributionDict[@"linkParameters"] = attributionResult.linkInfo;
        }
        if (attributionResult.kitCode != nil) {
            attributionDict[@"kitId"] = attributionResult.kitCode;
        }
        dictionary[[kitId stringValue]] = attributionDict;
    }
    callback(@[dictionary]);
}

RCT_EXPORT_METHOD(setUserAttribute:(NSString *)mpid key:(NSString *)key value:(NSString *)value)
{
    MParticleUser *selectedUser = [[MParticleUser alloc] init];
    selectedUser.userId = [NSNumber numberWithLong:mpid.longLongValue];
    [selectedUser setUserAttribute:key
                             value:value];
}

RCT_EXPORT_METHOD(setUserAttributeArray:(NSString *)mpid key:(NSString *)key value:(NSArray *)value)
{
    MParticleUser *selectedUser = [[MParticleUser alloc] init];
    selectedUser.userId = [NSNumber numberWithLong:mpid.longLongValue];
    [selectedUser setUserAttributeList:key
                                values:value];
}

RCT_EXPORT_METHOD(getUserAttributes:(NSString *)mpid callback:(RCTResponseSenderBlock)callback)
{
    MParticleUser *selectedUser = [[MParticleUser alloc] init];
    selectedUser.userId = [NSNumber numberWithLong:mpid.longLongValue];
    callback(@[[NSNull null], [selectedUser userAttributes]]);
}

RCT_EXPORT_METHOD(setUserTag:(NSString *)mpid tag:(NSString *)tag)
{
    MParticleUser *selectedUser = [[MParticleUser alloc] init];
    selectedUser.userId = [NSNumber numberWithLong:mpid.longLongValue];
    [selectedUser setUserTag:tag];
}

RCT_EXPORT_METHOD(removeUserAttribute:(NSString *)mpid key:(NSString *)key)
{
    MParticleUser *selectedUser = [[MParticleUser alloc] init];
    selectedUser.userId = [NSNumber numberWithLong:mpid.longLongValue];
    [selectedUser removeUserAttribute:key];
}

RCT_EXPORT_METHOD(incrementUserAttribute:(NSString *)mpid key:(NSString *)key value:(double)value)
{
    MParticleUser *selectedUser = [[MParticleUser alloc] init];
    selectedUser.userId = [NSNumber numberWithLong:mpid.longLongValue];
    [selectedUser incrementUserAttribute:key
                            byValue:@(value)];
}

RCT_EXPORT_METHOD(identify:(MPIdentityApiRequest *)identityRequest completion:(RCTResponseSenderBlock)completion)
{
    [[[MParticle sharedInstance] identity] identify:identityRequest completion:^(MPIdentityApiResult * _Nullable apiResult, NSError * _Nullable error) {
        NSMutableDictionary *reactError;
        if (error) {
            reactError = [[NSMutableDictionary alloc] initWithCapacity:4];
            MPIdentityHTTPErrorResponse *response = error.userInfo[mParticleIdentityErrorKey];

            if ([response isKindOfClass:[NSString class]]) {
                [reactError setObject:response forKey:@"message"];
            } else {
                if ([NSNumber numberWithLong:response.httpCode] != nil) {
                    [reactError setObject:[NSNumber numberWithLong:response.httpCode] forKey:@"httpCode"];
                }

                if ([NSNumber numberWithInt:response.code] != nil) {
                    [reactError setObject:[NSNumber numberWithInt:response.code] forKey:@"responseCode"];
                }

                if (response.message != nil) {
                    [reactError setObject:response.message forKey:@"message"];
                }
            }
            if (apiResult != nil) {
                completion(@[reactError, apiResult.user.userId.stringValue, apiResult.previousUser.userId.stringValue]);
            } else {
                completion(@[reactError, @0]);
            }
        } else {
            completion(@[[NSNull null], apiResult.user.userId.stringValue, apiResult.previousUser.userId.stringValue]);
        }
    }];
}

RCT_EXPORT_METHOD(login:(MPIdentityApiRequest *)identityRequest completion:(RCTResponseSenderBlock)completion)
{
    [[[MParticle sharedInstance] identity] login:identityRequest completion:^(MPIdentityApiResult * _Nullable apiResult, NSError * _Nullable error) {
        NSMutableDictionary *reactError;
        if (error) {
            reactError = [[NSMutableDictionary alloc] initWithCapacity:4];
            MPIdentityHTTPErrorResponse *response = error.userInfo[mParticleIdentityErrorKey];

            if ([response isKindOfClass:[NSString class]]) {
                [reactError setObject:response forKey:@"message"];
            } else {
                if ([NSNumber numberWithLong:response.httpCode] != nil) {
                    [reactError setObject:[NSNumber numberWithLong:response.httpCode] forKey:@"httpCode"];
                }

                if ([NSNumber numberWithInt:response.code] != nil) {
                    [reactError setObject:[NSNumber numberWithInt:response.code] forKey:@"responseCode"];
                }

                if (response.message != nil) {
                    [reactError setObject:response.message forKey:@"message"];
                }
            }
            if (apiResult != nil) {
                completion(@[reactError, apiResult.user.userId.stringValue, apiResult.previousUser.userId.stringValue]);
            } else {
                completion(@[reactError, @0]);
            }
        } else {
            completion(@[[NSNull null], apiResult.user.userId.stringValue, apiResult.previousUser.userId.stringValue]);
        }
    }];
}

RCT_EXPORT_METHOD(logout:(MPIdentityApiRequest *)identityRequest completion:(RCTResponseSenderBlock)completion)
{
    [[[MParticle sharedInstance] identity] logout:identityRequest completion:^(MPIdentityApiResult * _Nullable apiResult, NSError * _Nullable error) {
        NSMutableDictionary *reactError;
        if (error) {
            reactError = [[NSMutableDictionary alloc] initWithCapacity:4];
            MPIdentityHTTPErrorResponse *response = error.userInfo[mParticleIdentityErrorKey];

            if ([response isKindOfClass:[NSString class]]) {
                [reactError setObject:response forKey:@"message"];
            } else {
                if ([NSNumber numberWithLong:response.httpCode] != nil) {
                    [reactError setObject:[NSNumber numberWithLong:response.httpCode] forKey:@"httpCode"];
                }

                if ([NSNumber numberWithInt:response.code] != nil) {
                    [reactError setObject:[NSNumber numberWithInt:response.code] forKey:@"responseCode"];
                }

                if (response.message != nil) {
                    [reactError setObject:response.message forKey:@"message"];
                }
            }
            if (apiResult != nil) {
                completion(@[reactError, apiResult.user.userId.stringValue, apiResult.previousUser.userId.stringValue]);
            } else {
                completion(@[reactError, @0]);
            }
        } else {
            completion(@[[NSNull null], apiResult.user.userId.stringValue, apiResult.previousUser.userId.stringValue]);
        }
    }];
}

RCT_EXPORT_METHOD(modify:(MPIdentityApiRequest *)identityRequest completion:(RCTResponseSenderBlock)completion)
{
    [[[MParticle sharedInstance] identity] modify:identityRequest completion:^(MPIdentityApiResult * _Nullable apiResult, NSError * _Nullable error) {
        NSMutableDictionary *reactError;
        if (error) {
            reactError = [[NSMutableDictionary alloc] initWithCapacity:4];
            MPIdentityHTTPErrorResponse *response = error.userInfo[mParticleIdentityErrorKey];

            if ([response isKindOfClass:[NSString class]]) {
                [reactError setObject:response forKey:@"message"];
            } else {
                if ([NSNumber numberWithLong:response.httpCode] != nil) {
                    [reactError setObject:[NSNumber numberWithLong:response.httpCode] forKey:@"httpCode"];
                }

                if ([NSNumber numberWithInt:response.code] != nil) {
                    [reactError setObject:[NSNumber numberWithInt:response.code] forKey:@"responseCode"];
                }

                if (response.message != nil) {
                    [reactError setObject:response.message forKey:@"message"];
                }
            }
            if (apiResult != nil) {
                completion(@[reactError, apiResult.user.userId.stringValue, [NSNull null]]);
            } else {
                completion(@[reactError, @0]);
            }
        } else {
            completion(@[[NSNull null], apiResult.user.userId.stringValue, [NSNull null]]);
        }
    }];
}

RCT_EXPORT_METHOD(aliasUsers:(MPAliasRequest *) aliasRequest completion:(RCTResponseSenderBlock)completion)
{
    BOOL success = [[[MParticle sharedInstance] identity] aliasUsers:aliasRequest];
    completion(@[[NSNull null], success ? @"true" : @"false"]);
}

RCT_EXPORT_METHOD(getCurrentUserWithCompletion:(RCTResponseSenderBlock)callback)
{
    callback(@[[NSNull null], [[[MParticle sharedInstance] identity] currentUser].userId.stringValue]);
}

RCT_EXPORT_METHOD(getUserIdentities:(NSString *)mpid callback:(RCTResponseSenderBlock)callback)
{
    MParticleUser *selectedUser = [[MParticleUser alloc] init];
    selectedUser.userId = [NSNumber numberWithLong:mpid.longLongValue];
    callback(@[[NSNull null], [selectedUser identities]]);
}

RCT_EXPORT_METHOD(getFirstSeen:(NSString *)mpid callback:(RCTResponseSenderBlock)callback)
{
    MParticleUser *selectedUser = [[MParticleUser alloc] init];
    selectedUser.userId = [NSNumber numberWithLong:mpid.longLongValue];
    callback(@[[NSNull null], [selectedUser firstSeen]]);
}

RCT_EXPORT_METHOD(getLastSeen:(NSString *)mpid callback:(RCTResponseSenderBlock)callback)
{
    MParticleUser *selectedUser = [[MParticleUser alloc] init];
    selectedUser.userId = [NSNumber numberWithLong:mpid.longLongValue];
    callback(@[[NSNull null], [selectedUser lastSeen]]);
}

RCT_EXPORT_METHOD(getSession:(RCTResponseSenderBlock)completion)
{
    MParticleSession *session = [MParticle sharedInstance].currentSession;
    if (session && session.UUID) {
        completion(@[session.UUID]);
    } else {
        completion(@[[NSNull null]]);
    }
}

// New Architecture Protocol Methods - Incompatible types only
#ifdef RCT_NEW_ARCH_ENABLED

- (void)aliasUsers:(JS::NativeMParticle::AliasRequest &)aliasRequest callback:(RCTResponseSenderBlock)callback {
    // Create MPAliasRequest directly from JS struct
    NSString *destinationMpidString = aliasRequest.destinationMpid();
    NSString *sourceMpidString = aliasRequest.sourceMpid();
    NSNumber *destinationMpid = [NSNumber numberWithLong:destinationMpidString.longLongValue];
    NSNumber *sourceMpid = [NSNumber numberWithLong:sourceMpidString.longLongValue];
    
    MPAliasRequest *request;
    if (aliasRequest.startTime().has_value() && aliasRequest.endTime().has_value()) {
        NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:aliasRequest.startTime().value() / 1000.0];
        NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:aliasRequest.endTime().value() / 1000.0];
        request = [MPAliasRequest requestWithSourceMPID:sourceMpid destinationMPID:destinationMpid startTime:startDate endTime:endDate];
    } else {
        MParticleUser *destinationUser = [[MParticleUser alloc] init];
        MParticleUser *sourceUser = [[MParticleUser alloc] init];
        destinationUser.userId = destinationMpid;
        sourceUser.userId = sourceMpid;
        request = [MPAliasRequest requestWithSourceUser:sourceUser destinationUser:destinationUser];
    }
    
    BOOL success = [[[MParticle sharedInstance] identity] aliasUsers:request];
    callback(@[[NSNull null], success ? @"true" : @"false"]);
}

- (void)identify:(NSDictionary *)identityRequest callback:(RCTResponseSenderBlock)callback {
    [self performIdentityRequest:identityRequest callback:callback requestType:@"identify"];
}

- (void)login:(NSDictionary *)identityRequest callback:(RCTResponseSenderBlock)callback {
    [self performIdentityRequest:identityRequest callback:callback requestType:@"login"];
}

- (void)logout:(NSDictionary *)identityRequest callback:(RCTResponseSenderBlock)callback {
    [self performIdentityRequest:identityRequest callback:callback requestType:@"logout"];
}

- (void)modify:(NSDictionary *)identityRequest callback:(RCTResponseSenderBlock)callback {
    [self performIdentityRequest:identityRequest callback:callback requestType:@"modify"];
}

- (void)setATTStatusWithCustomTimestamp:(double)status timestamp:(double)timestamp {
    [[MParticle sharedInstance] setATTStatus:(MPATTAuthorizationStatus)status withATTStatusTimestampMillis:@(timestamp)];
}

- (void)logMPEvent:(JS::NativeMParticle::Event &)event {
    // Create MPEvent directly from JS struct
    NSString *eventName = event.name() ?: @"";
    MPEventType eventType = event.type().has_value() ? (MPEventType)event.type().value() : MPEventTypeOther;
    
    MPEvent *mpEvent = [[MPEvent alloc] initWithName:eventName type:eventType];
    
    if (event.info()) {
        mpEvent.customAttributes = (NSDictionary *)event.info();
    }
    
    if (event.duration().has_value()) {
        mpEvent.duration = @(event.duration().value());
    }
    
    if (event.startTime().has_value()) {
        mpEvent.startTime = [NSDate dateWithTimeIntervalSince1970:event.startTime().value() / 1000.0];
    }
    
    if (event.endTime().has_value()) {
        mpEvent.endTime = [NSDate dateWithTimeIntervalSince1970:event.endTime().value() / 1000.0];
    }
    
    if (event.category()) {
        mpEvent.category = event.category();
    }
    
    if (event.customFlags()) {
        NSDictionary *dictFlags = (NSDictionary *)event.customFlags();
        for (NSString *key in dictFlags) {
            NSString *value = dictFlags[key];
            [mpEvent addCustomFlag:value withKey:key];
        }
    }
    
    [[MParticle sharedInstance] logEvent:mpEvent];
}

- (void)logCommerceEvent:(JS::NativeMParticle::CommerceEvent &)commerceEvent {
    // Create MPCommerceEvent directly from JS struct
    MPCommerceEvent *mpCommerceEvent = [[MPCommerceEvent alloc] init];
    
    if (commerceEvent.productActionType().has_value()) {
        mpCommerceEvent.action = (MPCommerceEventAction)commerceEvent.productActionType().value();
    }
    
    if (commerceEvent.promotionActionType().has_value()) {
        mpCommerceEvent.promotionContainer = [[MPPromotionContainer alloc] initWithAction:(MPPromotionAction)commerceEvent.promotionActionType().value() promotion:nil];
    }
    
    if (commerceEvent.products().has_value()) {
        // Convert products array from LazyVector
        auto productsVector = commerceEvent.products().value();
        NSMutableArray *productsArray = [[NSMutableArray alloc] init];
        for (size_t i = 0; i < productsVector.size(); i++) {
            auto productStruct = productsVector[i];
            // Convert JS Product struct to dictionary
            NSMutableDictionary *productDict = [[NSMutableDictionary alloc] init];
            if (productStruct.name()) productDict[@"name"] = productStruct.name();
            if (productStruct.sku()) productDict[@"sku"] = productStruct.sku();
            productDict[@"price"] = @(productStruct.price());
            if (productStruct.quantity().has_value()) productDict[@"quantity"] = @(productStruct.quantity().value());
            if (productStruct.brand()) productDict[@"brand"] = productStruct.brand();
            if (productStruct.couponCode()) productDict[@"couponCode"] = productStruct.couponCode();
            if (productStruct.position().has_value()) productDict[@"position"] = @(productStruct.position().value());
            if (productStruct.category()) productDict[@"category"] = productStruct.category();
            if (productStruct.variant()) productDict[@"variant"] = productStruct.variant();
            if (productStruct.customAttributes()) productDict[@"customAttributes"] = productStruct.customAttributes();
            
            MPProduct *product = [self createMPProductFromDict:productDict];
            if (product) {
                [productsArray addObject:product];
            }
        }
        [mpCommerceEvent addProducts:productsArray];
    }
    
    if (commerceEvent.transactionAttributes().has_value()) {
        // Create transaction attributes from the struct
        auto transactionAttrs = commerceEvent.transactionAttributes().value();
        MPTransactionAttributes *transaction = [[MPTransactionAttributes alloc] init];
        
        if (transactionAttrs.transactionId()) {
            transaction.transactionId = transactionAttrs.transactionId();
        }
        if (transactionAttrs.affiliation()) {
            transaction.affiliation = transactionAttrs.affiliation();
        }
        if (transactionAttrs.revenue().has_value()) {
            transaction.revenue = @(transactionAttrs.revenue().value());
        }
        if (transactionAttrs.shipping().has_value()) {
            transaction.shipping = @(transactionAttrs.shipping().value());
        }
        if (transactionAttrs.tax().has_value()) {
            transaction.tax = @(transactionAttrs.tax().value());
        }
        if (transactionAttrs.couponCode()) {
            transaction.couponCode = transactionAttrs.couponCode();
        }
        
        mpCommerceEvent.transactionAttributes = transaction;
    }
    
    if (commerceEvent.customAttributes()) {
        mpCommerceEvent.customAttributes = (NSDictionary *)commerceEvent.customAttributes();
    }
    
    [[MParticle sharedInstance] logEvent:mpCommerceEvent];
}

- (void)addGDPRConsentState:(JS::NativeMParticle::GDPRConsent &)consent purpose:(NSString *)purpose {
    // Create MPGDPRConsent directly from JS struct
    MPGDPRConsent *gdprConsent = [[MPGDPRConsent alloc] init];
    
    if (consent.consented().has_value()) {
        gdprConsent.consented = consent.consented().value();
    }
    
    if (consent.document()) {
        gdprConsent.document = consent.document();
    }
    
    if (consent.timestamp().has_value()) {
        gdprConsent.timestamp = [NSDate dateWithTimeIntervalSince1970:consent.timestamp().value() / 1000.0];
    }
    
    if (consent.location()) {
        gdprConsent.location = consent.location();
    }
    
    if (consent.hardwareId()) {
        gdprConsent.hardwareId = consent.hardwareId();
    }
    
    MParticleUser *user = [MParticle sharedInstance].identity.currentUser;
    MPConsentState *consentState = user.consentState ? user.consentState : [[MPConsentState alloc] init];
    [consentState addGDPRConsentState:gdprConsent purpose:purpose];
    user.consentState = consentState;
}

- (void)setCCPAConsentState:(JS::NativeMParticle::CCPAConsent &)consent {
    // Create MPCCPAConsent directly from JS struct
    MPCCPAConsent *ccpaConsent = [[MPCCPAConsent alloc] init];
    
    if (consent.consented().has_value()) {
        ccpaConsent.consented = consent.consented().value();
    }
    
    if (consent.document()) {
        ccpaConsent.document = consent.document();
    }
    
    if (consent.timestamp().has_value()) {
        ccpaConsent.timestamp = [NSDate dateWithTimeIntervalSince1970:consent.timestamp().value() / 1000.0];
    }
    
    if (consent.location()) {
        ccpaConsent.location = consent.location();
    }
    
    if (consent.hardwareId()) {
        ccpaConsent.hardwareId = consent.hardwareId();
    }
    
    MParticleUser *user = [MParticle sharedInstance].identity.currentUser;
    MPConsentState *consentState = user.consentState ? user.consentState : [[MPConsentState alloc] init];
    [consentState setCCPAConsentState:ccpaConsent];
    user.consentState = consentState;
}
#else

RCT_EXPORT_METHOD(logMPEvent:(MPEvent *)event)
{
    [[MParticle sharedInstance] logEvent:event];
}

RCT_EXPORT_METHOD(logCommerceEvent:(MPCommerceEvent *)commerceEvent)
{
    [[MParticle sharedInstance] logCommerceEvent:commerceEvent];
}

RCT_EXPORT_METHOD(addGDPRConsentState:(MPGDPRConsent *)gdprConsentState purpose:(NSString *)purpose)
{
    MParticleUser *user = [MParticle sharedInstance].identity.currentUser;

    MPConsentState *consentState = user.consentState ? user.consentState : [[MPConsentState alloc] init];
    [consentState addGDPRConsentState:gdprConsentState purpose:purpose];
    user.consentState = consentState;
}

RCT_EXPORT_METHOD(setCCPAConsentState:(MPCCPAConsent *)consent)
{
    MParticleUser *user = [MParticle sharedInstance].identity.currentUser;

    MPConsentState *consentState = user.consentState ? user.consentState : [[MPConsentState alloc] init];
    [consentState setCCPAConsentState:consent];
    user.consentState = consentState;
}

#endif

// Helper method to create MPProduct from dictionary
- (MPProduct *)createMPProductFromDict:(NSDictionary *)productDict {
    NSString *name = productDict[@"name"];
    NSString *sku = productDict[@"sku"];
    NSNumber *price = productDict[@"price"];
    
    if (!name || !sku || !price) {
        return nil;
    }
    
    MPProduct *product = [[MPProduct alloc] initWithName:name sku:sku quantity:@1 price:price];
    
    if (productDict[@"quantity"]) {
        product.quantity = productDict[@"quantity"];
    }
    if (productDict[@"brand"]) {
        product.brand = productDict[@"brand"];
    }
    if (productDict[@"couponCode"]) {
        product.couponCode = productDict[@"couponCode"];
    }
    if (productDict[@"position"]) {
        product.position = [productDict[@"position"] integerValue];
    }
    if (productDict[@"category"]) {
        product.category = productDict[@"category"];
    }
    if (productDict[@"variant"]) {
        product.variant = productDict[@"variant"];
    }

    return product;
}

- (MPIdentityApiRequest *)MPIdentityApiRequestFromDict:(NSDictionary *)dict {
    if ([dict isKindOfClass:MPIdentityApiRequest.class]) {
        return (MPIdentityApiRequest*)dict;
    }
    MPIdentityApiRequest *request = [MPIdentityApiRequest requestWithEmptyUser];
    
    if (dict[@"userIdentities"] && dict[@"userIdentities"] != [NSNull null]) {
        NSDictionary *identities = dict[@"userIdentities"];
        for (NSString *key in identities) {
            MPIdentity identityType = (MPIdentity)[key integerValue];
            NSString *value = identities[key];
            [request setIdentity:value identityType:identityType];
        }
    }
    
    if (dict[@"customerId"] && dict[@"customerId"] != [NSNull null]) {
        request.customerId = dict[@"customerId"];
    }
    
    if (dict[@"email"] && dict[@"email"] != [NSNull null]) {
        request.email = dict[@"email"];
    }
    
    return request;
}

// Private helper method for identity requests
- (void)performIdentityRequest:(NSDictionary *)identityRequest callback:(RCTResponseSenderBlock)callback requestType:(NSString *)requestType {
    MPIdentityApiRequest *request = [self MPIdentityApiRequestFromDict:identityRequest];
    
    void (^completion)(MPIdentityApiResult * _Nullable, NSError * _Nullable) = ^(MPIdentityApiResult * _Nullable apiResult, NSError * _Nullable error) {
        if (error) {
            NSMutableDictionary *reactError = [[NSMutableDictionary alloc] initWithCapacity:4];
            MPIdentityHTTPErrorResponse *response = error.userInfo[mParticleIdentityErrorKey];
            if ([response isKindOfClass:[NSString class]]) {
                [reactError setObject:response forKey:@"message"];
            } else {
                if ([NSNumber numberWithLong:response.httpCode] != nil) {
                    [reactError setObject:[NSNumber numberWithLong:response.httpCode] forKey:@"httpCode"];
                }
                if ([NSNumber numberWithInt:response.code] != nil) {
                    [reactError setObject:[NSNumber numberWithInt:response.code] forKey:@"responseCode"];
                }
                if (response.message != nil) {
                    [reactError setObject:response.message forKey:@"message"];
                }
            }
            if (apiResult != nil) {
                if ([requestType isEqualToString:@"modify"]) {
                    callback(@[reactError, apiResult.user.userId.stringValue, [NSNull null]]);
                } else {
                    callback(@[reactError, apiResult.user.userId.stringValue, apiResult.previousUser.userId.stringValue]);
                }
            } else {
                callback(@[reactError, @0]);
            }
        } else {
            if ([requestType isEqualToString:@"modify"]) {
                callback(@[[NSNull null], apiResult.user.userId.stringValue, [NSNull null]]);
            } else {
                callback(@[[NSNull null], apiResult.user.userId.stringValue, apiResult.previousUser.userId.stringValue]);
            }
        }
    };
    
    if ([requestType isEqualToString:@"identify"]) {
        [[[MParticle sharedInstance] identity] identify:request completion:completion];
    } else if ([requestType isEqualToString:@"login"]) {
        [[[MParticle sharedInstance] identity] login:request completion:completion];
    } else if ([requestType isEqualToString:@"logout"]) {
        [[[MParticle sharedInstance] identity] logout:request completion:completion];
    } else if ([requestType isEqualToString:@"modify"]) {
        [[[MParticle sharedInstance] identity] modify:request completion:completion];
    }
}

#ifdef RCT_NEW_ARCH_ENABLED
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const facebook::react::ObjCTurboModule::InitParams &)params {
    return std::make_shared<facebook::react::NativeMParticleSpecJSI>(params);
}
#endif

@end

// RCTConvert category methods for mParticle types
@implementation RCTConvert (MParticle)

+ (MPEvent *)MPEvent:(NSDictionary *)dict {
    MPEvent *event = [[MPEvent alloc] initWithName:dict[@"name"] type:(MPEventType)[dict[@"type"] integerValue]];
    
    if (dict[@"info"] && dict[@"info"] != [NSNull null]) {
        event.customAttributes = dict[@"info"];
    }
    
    if (dict[@"duration"] && dict[@"duration"] != [NSNull null]) {
        event.duration = @([dict[@"duration"] doubleValue]);
    }
    
    if (dict[@"startTime"] && dict[@"startTime"] != [NSNull null]) {
        event.startTime = [NSDate dateWithTimeIntervalSince1970:[dict[@"startTime"] doubleValue] / 1000.0];
    }
    
    if (dict[@"endTime"] && dict[@"endTime"] != [NSNull null]) {
        event.endTime = [NSDate dateWithTimeIntervalSince1970:[dict[@"endTime"] doubleValue] / 1000.0];
    }
    
    if (dict[@"category"] && dict[@"category"] != [NSNull null]) {
        event.category = dict[@"category"];
    }
    
    if (dict[@"shouldUploadEvent"] && dict[@"shouldUploadEvent"] != [NSNull null]) {
        event.shouldUploadEvent = [dict[@"shouldUploadEvent"] boolValue];
    }
    
    if (dict[@"customFlags"] && dict[@"customFlags"] != [NSNull null]) {
        NSDictionary *dictFlags = (NSDictionary *)dict[@"customFlags"];
        for (NSString *key in dictFlags) {
            NSString *value = dictFlags[key];
            [event addCustomFlag:value withKey:key];
        }
    }
    
    return event;
}

+ (MPCommerceEvent *)MPCommerceEvent:(NSDictionary *)dict {
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] init];
    
    if (dict[@"productActionType"] && dict[@"productActionType"] != [NSNull null]) {
        commerceEvent.action = (MPCommerceEventAction)[dict[@"productActionType"] integerValue];
    }
    
    if (dict[@"products"] && dict[@"products"] != [NSNull null]) {
        NSArray *productDicts = dict[@"products"];
        NSMutableArray *products = [[NSMutableArray alloc] init];
        for (NSDictionary *productDict in productDicts) {
            MPProduct *product = [[MPProduct alloc] initWithName:productDict[@"name"]
                                                             sku:productDict[@"sku"]
                                                        quantity:productDict[@"quantity"]
                                                           price:productDict[@"price"]];
            [products addObject:product];
        }
        [commerceEvent addProducts:products];
    }
    
    if (dict[@"transactionAttributes"] && dict[@"transactionAttributes"] != [NSNull null]) {
        NSDictionary *transactionDict = dict[@"transactionAttributes"];
        MPTransactionAttributes *transactionAttributes = [[MPTransactionAttributes alloc] init];
        if (transactionDict[@"transactionId"]) {
            transactionAttributes.transactionId = transactionDict[@"transactionId"];
        }
        if (transactionDict[@"revenue"]) {
            transactionAttributes.revenue = transactionDict[@"revenue"];
        }
        if (transactionDict[@"tax"]) {
            transactionAttributes.tax = transactionDict[@"tax"];
        }
        if (transactionDict[@"shipping"]) {
            transactionAttributes.shipping = transactionDict[@"shipping"];
        }
        if (transactionDict[@"couponCode"]) {
            transactionAttributes.couponCode = transactionDict[@"couponCode"];
        }
        if (transactionDict[@"affiliation"]) {
            transactionAttributes.affiliation = transactionDict[@"affiliation"];
        }
        commerceEvent.transactionAttributes = transactionAttributes;
    }
    
    if (dict[@"customAttributes"] && dict[@"customAttributes"] != [NSNull null]) {
        commerceEvent.customAttributes = dict[@"customAttributes"];
    }
    
    if (dict[@"shouldUploadEvent"] && dict[@"shouldUploadEvent"] != [NSNull null]) {
        commerceEvent.shouldUploadEvent = [dict[@"shouldUploadEvent"] boolValue];
    }
    
    return commerceEvent;
}

+ (MPGDPRConsent *)MPGDPRConsent:(NSDictionary *)dict {
    BOOL consented = [dict[@"consented"] boolValue];
    MPGDPRConsent *consent = [[MPGDPRConsent alloc] init];
    consent.consented = consented;
    
    if (dict[@"document"] && dict[@"document"] != [NSNull null]) {
        consent.document = dict[@"document"];
    }
    
    if (dict[@"timestamp"] && dict[@"timestamp"] != [NSNull null]) {
        consent.timestamp = [NSDate dateWithTimeIntervalSince1970:[dict[@"timestamp"] doubleValue] / 1000.0];
    }
    
    if (dict[@"location"] && dict[@"location"] != [NSNull null]) {
        consent.location = dict[@"location"];
    }
    
    if (dict[@"hardwareId"] && dict[@"hardwareId"] != [NSNull null]) {
        consent.hardwareId = dict[@"hardwareId"];
    }
    
    return consent;
}

+ (MPCCPAConsent *)MPCCPAConsent:(NSDictionary *)dict {
    BOOL consented = [dict[@"consented"] boolValue];
    MPCCPAConsent *consent = [[MPCCPAConsent alloc] init];
    consent.consented = consented;
    
    if (dict[@"document"] && dict[@"document"] != [NSNull null]) {
        consent.document = dict[@"document"];
    }
    
    if (dict[@"timestamp"] && dict[@"timestamp"] != [NSNull null]) {
        consent.timestamp = [NSDate dateWithTimeIntervalSince1970:[dict[@"timestamp"] doubleValue] / 1000.0];
    }
    
    if (dict[@"location"] && dict[@"location"] != [NSNull null]) {
        consent.location = dict[@"location"];
    }
    
    if (dict[@"hardwareId"] && dict[@"hardwareId"] != [NSNull null]) {
        consent.hardwareId = dict[@"hardwareId"];
    }
    
    return consent;
}

+ (MPAliasRequest *)MPAliasRequest:(NSDictionary *)dict {
    NSString *sourceMpidString = dict[@"sourceMpid"];
    NSString *destinationMpidString = dict[@"destinationMpid"];
    NSNumber *sourceMpid = [NSNumber numberWithLong:sourceMpidString.longLongValue];
    NSNumber *destinationMpid = [NSNumber numberWithLong:destinationMpidString.longLongValue];
    
    NSDate *startTime = nil;
    NSDate *endTime = nil;
    
    if (dict[@"startTime"] && dict[@"startTime"] != [NSNull null]) {
        startTime = [NSDate dateWithTimeIntervalSince1970:[dict[@"startTime"] doubleValue] / 1000.0];
    }
    
    if (dict[@"endTime"] && dict[@"endTime"] != [NSNull null]) {
        endTime = [NSDate dateWithTimeIntervalSince1970:[dict[@"endTime"] doubleValue] / 1000.0];
    }
    
    return [MPAliasRequest requestWithSourceMPID:sourceMpid destinationMPID:destinationMpid startTime:startTime endTime:endTime];
}

@end

typedef NS_ENUM(NSUInteger, MPReactCommerceEventAction) {
    MPReactCommerceEventActionAddToCart = 1,
    MPReactCommerceEventActionRemoveFromCart,
    MPReactCommerceEventActionCheckout,
    MPReactCommerceEventActionCheckoutOptions,
    MPReactCommerceEventActionClick,
    MPReactCommerceEventActionViewDetail,
    MPReactCommerceEventActionPurchase,
    MPReactCommerceEventActionRefund,
    MPReactCommerceEventActionAddToWishList,
    MPReactCommerceEventActionRemoveFromWishlist
};

@interface RCTConvert (MPCommerceEvent)

+ (MPCommerceEvent *)MPCommerceEvent:(id)json;
+ (MPPromotionContainer *)MPPromotionContainer:(id)json;
+ (MPPromotion *)MPPromotion:(id)json;
+ (MPTransactionAttributes *)MPTransactionAttributes:(id)json;
+ (MPProduct *)MPProduct:(id)json;
+ (MPCommerceEventAction)MPCommerceEventAction:(id)json;
+ (MPIdentityApiRequest *)MPIdentityApiRequest:(id)json;
+ (MPIdentityApiResult *)MPIdentityApiResult:(id)json;
+ (MPAliasRequest *)MPAliasRequest:(id)json;
+ (MParticleUser *)MParticleUser:(id)json;
+ (MPEvent *)MPEvent:(id)json;
+ (MPGDPRConsent *)MPGDPRConsent:(id)json;
+ (MPCCPAConsent *)MPCCPAConsent:(id)json;

@end

@implementation RCTConvert (MPCommerceEvent)

+ (MPCommerceEvent *)MPCommerceEvent:(id)json {
    BOOL isProductAction = json[@"productActionType"] != nil;
    BOOL isPromotion = json[@"promotionActionType"] != nil;
    BOOL isImpression = json[@"impressions"] != nil;

    NSAssert(isProductAction || isPromotion || isImpression, @"Invalid commerce event");

    MPCommerceEvent *commerceEvent = nil;
    if (isProductAction) {
        MPCommerceEventAction action = [RCTConvert MPCommerceEventAction:json[@"productActionType"]];
        commerceEvent = [[MPCommerceEvent alloc] initWithAction:action];
    }
    else if (isPromotion) {
        MPPromotionContainer *promotionContainer = [RCTConvert MPPromotionContainer:json];
        commerceEvent = [[MPCommerceEvent alloc] initWithPromotionContainer:promotionContainer];
    }
    else {
        commerceEvent = [[MPCommerceEvent alloc] initWithImpressionName:nil product:nil];
    }

    commerceEvent.checkoutOptions = json[@"checkoutOptions"];
    commerceEvent.currency = json[@"currency"];
    commerceEvent.productListName = json[@"productActionListName"];
    commerceEvent.productListSource = json[@"productActionListSource"];
    commerceEvent.screenName = json[@"screenName"];
    commerceEvent.transactionAttributes = [RCTConvert MPTransactionAttributes:json[@"transactionAttributes"]];
    commerceEvent.checkoutStep = [json[@"checkoutStep"] intValue];
    commerceEvent.nonInteractive = [json[@"nonInteractive"] boolValue];
    if (json[@"shouldUploadEvent"] != nil) {
        commerceEvent.shouldUploadEvent = [json[@"shouldUploadEvent"] boolValue];
    }
    if (json[@"customAttributes"] != nil) {
        commerceEvent.customAttributes = json[@"customAttributes"];
    }

    NSMutableArray *products = [NSMutableArray array];
    NSArray *jsonProducts = json[@"products"];
    [jsonProducts enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        MPProduct *product = [RCTConvert MPProduct:obj];
        [products addObject:product];
    }];
    [commerceEvent addProducts:products];

    NSArray *jsonImpressions = json[@"impressions"];
    [jsonImpressions enumerateObjectsUsingBlock:^(NSDictionary *jsonImpression, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *listName = jsonImpression[@"impressionListName"];
        NSArray *jsonProducts = jsonImpression[@"products"];
        [jsonProducts enumerateObjectsUsingBlock:^(id  _Nonnull jsonProduct, NSUInteger idx, BOOL * _Nonnull stop) {
            MPProduct *product = [RCTConvert MPProduct:jsonProduct];
            [commerceEvent addImpression:product listName:listName];
        }];
    }];

    return commerceEvent;
}

+ (MPPromotionContainer *)MPPromotionContainer:(id)json {
    MPPromotionAction promotionAction = (MPPromotionAction)[json[@"promotionActionType"] intValue];
    MPPromotionContainer *promotionContainer = [[MPPromotionContainer alloc] initWithAction:promotionAction promotion:nil];
    NSArray *jsonPromotions = json[@"promotions"];
    [jsonPromotions enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        MPPromotion *promotion = [RCTConvert MPPromotion:obj];
        [promotionContainer addPromotion:promotion];
    }];

    return promotionContainer;
}

+ (MPPromotion *)MPPromotion:(id)json {
    MPPromotion *promotion = [[MPPromotion alloc] init];
    promotion.creative = json[@"creative"];
    promotion.name = json[@"name"];
    promotion.position = json[@"position"];
    promotion.promotionId = json[@"id"];
    return promotion;
}

+ (MPTransactionAttributes *)MPTransactionAttributes:(id)json {
    MPTransactionAttributes *transactionAttributes = [[MPTransactionAttributes alloc] init];
    transactionAttributes.affiliation = json[@"affiliation"];
    transactionAttributes.couponCode = json[@"couponCode"];
    transactionAttributes.shipping = json[@"shipping"];
    transactionAttributes.tax = json[@"tax"];
    transactionAttributes.revenue = json[@"revenue"];
    transactionAttributes.transactionId = json[@"transactionId"];
    return transactionAttributes;
}

+ (MPProduct *)MPProduct:(id)json {
    MPProduct *product = [[MPProduct alloc] init];
    product.brand = json[@"brand"];
    product.category = json[@"category"];
    product.couponCode = json[@"couponCode"];
    product.name = json[@"name"];
    product.price = json[@"price"];
    product.sku = json[@"sku"];
    product.variant = json[@"variant"];
    product.position = [json[@"position"] intValue];
    product.quantity = @([json[@"quantity"] intValue]);
    NSDictionary *jsonAttributes = json[@"customAttributes"];
    for (NSString *key in jsonAttributes) {
        NSString *value = jsonAttributes[key];
        [product setObject:value forKeyedSubscript:key];
    }
    return product;
}

+ (MPCommerceEventAction)MPCommerceEventAction:(NSNumber *)json {
    int actionInt = [json intValue];
    MPCommerceEventAction action;
    switch (actionInt) {
        case MPReactCommerceEventActionAddToCart:
            action = MPCommerceEventActionAddToCart;
            break;

        case MPReactCommerceEventActionRemoveFromCart:
            action = MPCommerceEventActionRemoveFromCart;
            break;

        case MPReactCommerceEventActionCheckout:
            action = MPCommerceEventActionCheckout;
            break;

        case MPReactCommerceEventActionCheckoutOptions:
            action = MPCommerceEventActionCheckoutOptions;
            break;

        case MPReactCommerceEventActionClick:
            action = MPCommerceEventActionClick;
            break;

        case MPReactCommerceEventActionViewDetail:
            action = MPCommerceEventActionViewDetail;
            break;

        case MPReactCommerceEventActionPurchase:
            action = MPCommerceEventActionPurchase;
            break;

        case MPReactCommerceEventActionRefund:
            action = MPCommerceEventActionRefund;
            break;

        case MPReactCommerceEventActionAddToWishList:
            action = MPCommerceEventActionAddToWishList;
            break;

        case MPReactCommerceEventActionRemoveFromWishlist:
            action = MPCommerceEventActionRemoveFromWishlist;
            break;

        default:
            action = MPCommerceEventActionAddToCart;
            NSAssert(NO, @"Invalid commerce event action");
            break;
    }
    return action;
}

+ (MPIdentityApiRequest *)MPIdentityApiRequest:(id)json {
    NSDictionary *dict = json;
    MPIdentityApiRequest *request = [MPIdentityApiRequest requestWithEmptyUser];

    if (dict[@"userIdentities"] && dict[@"userIdentities"] != [NSNull null]) {
        NSDictionary *identities = dict[@"userIdentities"];
        for (NSString *key in identities) {
            MPIdentity identityType = (MPIdentity)[key integerValue];
            NSString *value = identities[key];
            [request setIdentity:value identityType:identityType];
        }
    }

    if (dict[@"customerId"] && dict[@"customerId"] != [NSNull null]) {
        request.customerId = dict[@"customerId"];
    }

    if (dict[@"email"] && dict[@"email"] != [NSNull null]) {
        request.email = dict[@"email"];
    }

    return request;
}



+ (MPIdentityApiResult *)MPIdentityApiResult:(id)json {
    MPIdentityApiResult *result = [[MPIdentityApiResult alloc] init];
    id obj = json[@"user"];
    result.user = [RCTConvert MParticleUser:obj];

    return result;
}

+ (MPAliasRequest *)MPAliasRequest:(id)json {
    NSString *destinationMpidString = json[@"destinationMpid"];
    NSString *sourceMpidString = json[@"sourceMpid"];
    NSString *startTime = json[@"startTime"];
    NSString *endTime = json[@"endTime"];
    NSNumber *destinationMpid = [NSNumber numberWithLong:destinationMpidString.longLongValue];
    NSNumber *sourceMpid = [NSNumber numberWithLong:sourceMpidString.longLongValue];
    NSDate *startDate = nil;
    NSDate *endDate = nil;
    
    if (startTime != nil && startTime != [NSNull null]) {
        startDate = [NSDate dateWithTimeIntervalSince1970:startTime.longLongValue];
    }
    
    if (endTime != nil && endTime != [NSNull null]) {
        endDate = [NSDate dateWithTimeIntervalSince1970:endTime.longLongValue];
    }
    
    return [MPAliasRequest requestWithSourceMPID:sourceMpid destinationMPID:destinationMpid startTime:startDate endTime:endDate];
}

+ (MParticleUser *)MParticleUser:(id)json {
    MParticleUser *user = [[MParticleUser alloc] init];
    user.userId = json[@"userId"];

    return user;
}

+ (MPEvent *)MPEvent:(id)json {
    MPEvent *event = [[MPEvent alloc] init];

    event.category = json[@"category"];
    event.duration = json[@"duration"];
    event.endTime = json[@"endTime"];
    event.info = json[@"info"];
    event.name = json[@"name"];
    event.startTime = json[@"startTime"];
    [event setType:(MPEventType)[json[@"type"] intValue]];
    if (json[@"shouldUploadEvent"] != nil) {
        event.shouldUploadEvent = [json[@"shouldUploadEvent"] boolValue];
    }

    NSDictionary *jsonFlags = json[@"customFlags"];
    for (NSString *key in jsonFlags) {
        NSString *value = jsonFlags[key];
        [event addCustomFlag:value withKey:key];
    }

    return event;
}

+ (MPGDPRConsent *)MPGDPRConsent:(id)json {
    MPGDPRConsent *mpConsent = [[MPGDPRConsent alloc] init];

    mpConsent.consented = [RCTConvert BOOL:json[@"consented"]];
    mpConsent.document = json[@"document"];
    mpConsent.timestamp = [RCTConvert NSDate:json[@"timestamp"]];
    mpConsent.location = json[@"location"];
    mpConsent.hardwareId = json[@"hardwareId"];

    return mpConsent;
}

+ (MPCCPAConsent *)MPCCPAConsent:(id)json {
    MPCCPAConsent *mpConsent = [[MPCCPAConsent alloc] init];

    mpConsent.consented = [RCTConvert BOOL:json[@"consented"]];
    mpConsent.document = json[@"document"];
    mpConsent.timestamp = [RCTConvert NSDate:json[@"timestamp"]];
    mpConsent.location = json[@"location"];
    mpConsent.hardwareId = json[@"hardwareId"];

    return mpConsent;
}

@end
