#import "RNMParticle.h"
#import "mParticle.h"
#import <React/RCTConvert.h>

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

RCT_EXPORT_METHOD(logCommerceEvent:(MPCommerceEvent *)commerceEvent)
{
    [[MParticle sharedInstance] logCommerceEvent:commerceEvent];
}

RCT_EXPORT_METHOD(logScreenEvent:(NSString *)screenName attributes:(NSDictionary *)attributes)
{
    [[MParticle sharedInstance] logScreen:screenName eventInfo:attributes];
}

RCT_EXPORT_METHOD(setUserAttribute:(NSString *)key value:(NSString *)value)
{
    [[MParticle sharedInstance] setUserAttribute:key value:value];
}

RCT_EXPORT_METHOD(setUserAttributeArray:(NSString *)key values:(NSArray *)values)
{
    [[MParticle sharedInstance] setUserAttribute:key values:values];
}

RCT_EXPORT_METHOD(setUserTag:(NSString *)tag)
{
    [[MParticle sharedInstance] setUserTag:tag];
}

RCT_EXPORT_METHOD(removeUserAttribute:(NSString *)key)
{
    [[MParticle sharedInstance] removeUserAttribute:key];
}

RCT_EXPORT_METHOD(setUserIdentity:(NSString *)identity type:(NSInteger)type)
{
    [[MParticle sharedInstance] setUserIdentity:identity identityType:type];
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
    MPTransactionAttributes *transactionAttributes;
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

@end
