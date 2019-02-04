#import "RNMParticle.h"
#import "mParticle.h"
#import <React/RCTConvert.h>

@interface MParticleUser ()

- (void)setUserId:(NSNumber *)userId;
@end

@implementation RNMParticle

RCT_EXTERN void RCTRegisterModule(Class);

+ (NSString *)moduleName {
    return @"MParticle";
}

+ (void)load {
    RCTRegisterModule(self);
}

RCT_EXPORT_METHOD(logEvent:(NSString *)eventName type:(NSInteger)type attributes:(NSDictionary *)attributes)
{
    [[MParticle sharedInstance] logEvent:eventName eventType:type eventInfo:attributes];
}

RCT_EXPORT_METHOD(logMPEvent:(MPEvent *)event)
{
    [[MParticle sharedInstance] logEvent:event];
}

RCT_EXPORT_METHOD(logCommerceEvent:(MPCommerceEvent *)commerceEvent)
{
    [[MParticle sharedInstance] logCommerceEvent:commerceEvent];
}

RCT_EXPORT_METHOD(logScreenEvent:(NSString *)screenName attributes:(NSDictionary *)attributes)
{
    [[MParticle sharedInstance] logScreen:screenName eventInfo:attributes];
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

RCT_EXPORT_METHOD(logPushRegistration:(NSString *)iosToken androidField:(NSString *)androidField)
{
    if (iosToken != nil) {
        NSData* pushTokenData = [iosToken dataUsingEncoding:NSUTF8StringEncoding];
        MParticle* instance = [MParticle sharedInstance];
        instance.pushNotificationToken = pushTokenData;
    }
}

RCT_EXPORT_METHOD(isKitActive:(nonnull NSNumber*)kitId completion:(RCTResponseSenderBlock)completion)
{
    BOOL active = [[MParticle sharedInstance] isKitActive:kitId];
    completion(@[[NSNumber numberWithBool:active]]);
}

RCT_EXPORT_METHOD(getAttributions:(RCTResponseSenderBlock)completion)
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
    completion(@[dictionary]);
}

RCT_EXPORT_METHOD(setUserAttribute:(NSString *)userId key:(NSString *)key value:(NSString *)value)
{
    MParticleUser *selectedUser = [[MParticleUser alloc] init];
    selectedUser.userId = [NSNumber numberWithLong:userId.longLongValue];
    [selectedUser setUserAttribute:key
                             value:value];
}

RCT_EXPORT_METHOD(setUserAttributeArray:(NSString *)userId key:(NSString *)key values:(NSArray *)values)
{
    MParticleUser *selectedUser = [[MParticleUser alloc] init];
    selectedUser.userId = [NSNumber numberWithLong:userId.longLongValue];
    [selectedUser setUserAttribute:key
                             value:values];
}

RCT_EXPORT_METHOD(setUserTag:(NSString *)userId tag:(NSString *)tag)
{
    MParticleUser *selectedUser = [[MParticleUser alloc] init];
    selectedUser.userId = [NSNumber numberWithLong:userId.longLongValue];
    [selectedUser setUserTag:tag];
}

RCT_EXPORT_METHOD(removeUserAttribute:(NSString *)userId key:(NSString *)key)
{
    MParticleUser *selectedUser = [[MParticleUser alloc] init];
    selectedUser.userId = [NSNumber numberWithLong:userId.longLongValue];
    [selectedUser removeUserAttribute:key];
}

RCT_EXPORT_METHOD(incrementUserAttribute:(NSString *)userId key:(NSString *)key value:(NSNumber * _Nonnull)value)
{
    MParticleUser *selectedUser = [[MParticleUser alloc] init];
    selectedUser.userId = [NSNumber numberWithLong:userId.longLongValue];
    [selectedUser incrementUserAttribute:key
                            byValue:value];
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
                completion(@[reactError, apiResult.user.userId.stringValue]);
            } else {
                completion(@[reactError, @0]);
            }
        } else {
            completion(@[[NSNull null], apiResult.user.userId.stringValue]);
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
                completion(@[reactError, apiResult.user.userId.stringValue]);
            } else {
                completion(@[reactError, @0]);
            }        
        } else {
            completion(@[[NSNull null], apiResult.user.userId.stringValue]);
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
                completion(@[reactError, apiResult.user.userId.stringValue]);
            } else {
                completion(@[reactError, @0]);
            }
        } else {
            completion(@[[NSNull null], apiResult.user.userId.stringValue]);
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
                completion(@[reactError, apiResult.user.userId.stringValue]);
            } else {
                completion(@[reactError, @0]);
            }
        } else {
            completion(@[[NSNull null], apiResult.user.userId.stringValue]);
        }
    }];
}

RCT_EXPORT_METHOD(getCurrentUserWithCompletion:(RCTResponseSenderBlock)completion)
{
    completion(@[[NSNull null], [[[MParticle sharedInstance] identity] currentUser].userId.stringValue]);
}

RCT_EXPORT_METHOD(getUserIdentities:(NSString *)userId completion:(RCTResponseSenderBlock)completion)
{
    MParticleUser *selectedUser = [[MParticleUser alloc] init];
    selectedUser.userId = [NSNumber numberWithLong:userId.longLongValue];
    completion(@[[NSNull null], [selectedUser userIdentities]]);
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
+ (MParticleUser *)MParticleUser:(id)json;
+ (MPEvent *)MPEvent:(id)json;

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
    commerceEvent.action = [RCTConvert MPCommerceEventAction:json[@"productActionType"]];
    commerceEvent.checkoutStep = [json[@"checkoutStep"] intValue];
    commerceEvent.nonInteractive = [json[@"nonInteractive"] boolValue];
    
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
    MPPromotionAction promotionAction = [json[@"promotionActionType"] intValue];
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
    product.quantity = json[@"quantity"];
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
    MPIdentityApiRequest *request = [MPIdentityApiRequest requestWithEmptyUser];
    for (NSString *key in json) {
        if ([key isEqualToString:@"email"]) {
            request.email = json[@"email"];
        } else if ([key isEqualToString:@"customerId"]) {
            request.customerId = json[@"customerId"];
        } else {
            NSString *value = json[key];
            [request.userIdentities setObject:value forKeyedSubscript:key];
        }
    }
    return request;
}

+ (MPIdentityApiResult *)MPIdentityApiResult:(id)json {
    MPIdentityApiResult *result = [[MPIdentityApiResult alloc] init];
    id obj = json[@"user"];
    result.user = [RCTConvert MParticleUser:obj];
    
    return result;
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
    event.type = [json[@"type"] intValue];
    
    NSDictionary *jsonFlags = json[@"customFlags"];
    for (NSString *key in jsonFlags) {
        NSString *value = jsonFlags[key];
        [event addCustomFlag:value withKey:key];
    }
    
    return event;
}

@end



