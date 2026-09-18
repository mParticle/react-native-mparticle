#import <XCTest/XCTest.h>
#import <React/RCTConvert.h>
#import "../../../ios/RNMParticle/RNMParticle.h"

// Match RNMParticle.mm / pod umbrella so tests compile against the same SDK the library uses.
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK_ObjC/mParticle.h>)
#import <mParticle_Apple_SDK_ObjC/mParticle.h>
#elif defined(__has_include) && __has_include(<mParticle_Apple_SDK/mParticle.h>)
#import <mParticle_Apple_SDK/mParticle.h>
#else
#import <mParticle_Apple_SDK_ObjC/mParticle.h>
#endif

// Implemented on `RCTConvert` in `RNMParticle.mm` (react-native-mparticle pod).
// Parameter types mirror the implementations there.
@interface RCTConvert (RNMParticle)
+ (MPCommerceEvent *)MPCommerceEvent:(id)json;
+ (MPCommerceEventAction)MPCommerceEventAction:(NSNumber *)json;
+ (MPPromotionAction)MPPromotionAction:(NSNumber *)json;
+ (MPProduct *)MPProduct:(id)json;
+ (MPEvent *)MPEvent:(NSDictionary *)dict;
+ (MPAliasRequest *)MPAliasRequest:(NSDictionary *)dict;
+ (MPGDPRConsent *)MPGDPRConsent:(id)json;
+ (MPCCPAConsent *)MPCCPAConsent:(id)json;
@end

@interface RNMParticle (ProductMappingTests)
- (MPProduct *)createMPProductFromDict:(NSDictionary *)productDict;
- (void)applyCommerceEventMetadata:(MPCommerceEvent *)event fromDictionary:(NSDictionary *)dict;
- (void)addPromotionsFromDicts:(NSArray *)promotionDicts toCommerceEvent:(MPCommerceEvent *)event;
@end

/**
 * Guards JS → native commerce enum mapping used by the bridge (including New Architecture).
 * Constants must stay aligned with `ProductActionType` / `PromotionActionType` in js/index.tsx.
 *
 * Direct `MPCommerceEventAction` / `MPPromotionAction` tests above validate the table only.
 * JSON → `MPCommerceEvent` tests below exercise the same `+[RCTConvert MPCommerceEvent:]` pipeline
 * used to assemble an `MPCommerceEvent` before `-[MParticle logCommerceEvent:]` (legacy bridge path),
 * including `MPPromotionContainer:` wiring. That catches regressions such as casting JS ints in
 * those helpers instead of calling the mappers. Product and commerce-metadata tests invoke the
 * helpers used by the New Architecture codegen struct path without requiring generated C++ values
 * in this target.
 */
@interface RCTConvertCommerceMappingTests : XCTestCase
@end

@implementation RCTConvertCommerceMappingTests

- (void)testMPCommerceEventAction_mapsReactNativeProductActionTypeConstants
{
    XCTAssertEqual([RCTConvert MPCommerceEventAction:@(1)], MPCommerceEventActionAddToCart);
    XCTAssertEqual([RCTConvert MPCommerceEventAction:@(2)], MPCommerceEventActionRemoveFromCart);
    XCTAssertEqual([RCTConvert MPCommerceEventAction:@(3)], MPCommerceEventActionCheckout);
    XCTAssertEqual([RCTConvert MPCommerceEventAction:@(4)], MPCommerceEventActionCheckoutOptions);
    XCTAssertEqual([RCTConvert MPCommerceEventAction:@(5)], MPCommerceEventActionClick);
    XCTAssertEqual([RCTConvert MPCommerceEventAction:@(6)], MPCommerceEventActionViewDetail);
    XCTAssertEqual([RCTConvert MPCommerceEventAction:@(7)], MPCommerceEventActionPurchase);
    XCTAssertEqual([RCTConvert MPCommerceEventAction:@(8)], MPCommerceEventActionRefund);
    XCTAssertEqual([RCTConvert MPCommerceEventAction:@(9)], MPCommerceEventActionAddToWishList);
    XCTAssertEqual([RCTConvert MPCommerceEventAction:@(10)], MPCommerceEventActionRemoveFromWishlist);
}

- (void)testMPPromotionAction_mapsReactNativePromotionActionTypeConstants
{
    // JS: View = 0, Click = 1. Native: Click = 0, View = 1 (MPPromotion.h).
    XCTAssertEqual([RCTConvert MPPromotionAction:@(0)], MPPromotionActionView);
    XCTAssertEqual([RCTConvert MPPromotionAction:@(1)], MPPromotionActionClick);
    XCTAssertEqual([RCTConvert MPPromotionAction:@(99)], MPPromotionActionClick);
}

#pragma mark - JSON → MPCommerceEvent (integration-style)

- (NSDictionary *)minimalProductJSON
{
    return @{
        @"name" : @"Test Product",
        @"sku" : @"SKU-1",
        @"price" : @19.99,
        @"quantity" : @1,
        @"customAttributes" : @{},
    };
}

- (NSDictionary *)productJSONWithCustomAttributes
{
    return @{
        @"name" : @"Test Product",
        @"sku" : @"SKU-1",
        @"price" : @19.99,
        @"quantity" : @1,
        @"customAttributes" : @{
            @"string" : @"value",
            @"integer" : @42,
            @"decimal" : @3.5,
            @"true" : @YES,
            @"false" : @NO,
            @"null" : [NSNull null],
        },
    };
}

- (void)assertCustomAttributesForProduct:(MPProduct *)product
{
    XCTAssertEqualObjects([product objectForKeyedSubscript:@"string"], @"value");
    XCTAssertEqualObjects([product objectForKeyedSubscript:@"integer"], @"42");
    XCTAssertEqualObjects([product objectForKeyedSubscript:@"decimal"], @"3.5");
    XCTAssertEqualObjects([product objectForKeyedSubscript:@"true"], @"true");
    XCTAssertEqualObjects([product objectForKeyedSubscript:@"false"], @"false");
    XCTAssertEqualObjects([product objectForKeyedSubscript:@"null"], @"");
}

- (void)testCreateMPProductFromDict_normalizesCustomAttributesForNewArchitecture
{
    RNMParticle *module = [[RNMParticle alloc] init];
    MPProduct *product = [module createMPProductFromDict:[self productJSONWithCustomAttributes]];

    [self assertCustomAttributesForProduct:product];
}

- (void)testMPProductFromJSON_normalizesCustomAttributesForLegacyArchitecture
{
    MPProduct *product = [RCTConvert MPProduct:[self productJSONWithCustomAttributes]];

    [self assertCustomAttributesForProduct:product];
}

- (void)testLegacyEventConvertersNormalizeNullCustomAttributes
{
    MPEvent *event = [RCTConvert MPEvent:@{
        @"name" : @"Test Event",
        @"type" : @(8),
        @"info" : @{ @"coupon_code" : [NSNull null], @"count" : @42 },
    }];
    MPCommerceEvent *commerceEvent = [RCTConvert MPCommerceEvent:@{
        @"productActionType" : @(7),
        @"products" : @[ [self minimalProductJSON] ],
        @"impressions" : @[],
        @"customAttributes" : @{ @"coupon_code" : [NSNull null] },
    }];

    XCTAssertEqualObjects(event.customAttributes[@"coupon_code"], @"");
    XCTAssertEqualObjects(commerceEvent.customAttributes[@"coupon_code"], @"");
    // Event-level values keep their type on iOS; only explicit null becomes "".
    XCTAssertEqualObjects(event.customAttributes[@"count"], @42);
}

- (void)testMPCommerceEventFromJSON_productActionFlowsThroughRCTConvertCommerceEvent
{
    NSDictionary *json = @{
        @"productActionType" : @(7), // Purchase in js/index.tsx
        @"products" : @[ [self productJSONWithCustomAttributes] ],
        @"impressions" : @[],
    };

    MPCommerceEvent *event = [RCTConvert MPCommerceEvent:json];
    XCTAssertEqual(event.action, MPCommerceEventActionPurchase);
    [self assertCustomAttributesForProduct:event.products.firstObject];
}

- (void)testMPCommerceEventFromJSON_promotionActionFlowsThroughMPPromotionContainer
{
    NSDictionary *promotion = @{
        @"id" : @"promo-1",
        @"name" : @"Sale",
        @"creative" : @"banner",
        @"position" : @"home-top",
    };

    NSDictionary *jsonView = @{
        @"promotionActionType" : @(0), // JS PromotionActionType.View
        @"promotions" : @[ promotion ],
        @"products" : @[],
        @"impressions" : @[],
    };
    MPCommerceEvent *viewEvent = [RCTConvert MPCommerceEvent:jsonView];
    XCTAssertNotNil(viewEvent.promotionContainer);
    XCTAssertEqual(viewEvent.promotionContainer.action, MPPromotionActionView);

    NSDictionary *jsonClick = @{
        @"promotionActionType" : @(1), // JS PromotionActionType.Click
        @"promotions" : @[ promotion ],
        @"products" : @[],
        @"impressions" : @[],
    };
    MPCommerceEvent *clickEvent = [RCTConvert MPCommerceEvent:jsonClick];
    XCTAssertNotNil(clickEvent.promotionContainer);
    XCTAssertEqual(clickEvent.promotionContainer.action, MPPromotionActionClick);
}

- (void)testMPCommerceEventFromJSON_mapsCurrencyCheckoutStepAndCheckoutOptions
{
    NSDictionary *json = @{
        @"productActionType" : @(3), // Checkout in js/index.tsx
        @"products" : @[ [self minimalProductJSON] ],
        @"impressions" : @[],
        @"currency" : @"USD",
        @"checkoutStep" : @1,
        @"checkoutOptions" : @"Visa",
        @"productActionListName" : @"checkout-list",
        @"productActionListSource" : @"app",
        @"screenName" : @"Checkout",
        @"nonInteractive" : @YES,
        @"shouldUploadEvent" : @NO,
    };

    MPCommerceEvent *event = [RCTConvert MPCommerceEvent:json];
    XCTAssertEqualObjects(event.currency, @"USD");
    XCTAssertEqual(event.checkoutStep, 1);
    XCTAssertEqualObjects(event.checkoutOptions, @"Visa");
    XCTAssertEqualObjects(event.productListName, @"checkout-list");
    XCTAssertEqualObjects(event.productListSource, @"app");
    XCTAssertEqualObjects(event.screenName, @"Checkout");
    XCTAssertTrue(event.nonInteractive);
    XCTAssertFalse(event.shouldUploadEvent);
}

- (void)testApplyCommerceEventMetadata_copiesNativeCommerceFieldsForNewArchitecture
{
    RNMParticle *module = [[RNMParticle alloc] init];
    MPCommerceEvent *event = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionCheckout];

    [module applyCommerceEventMetadata:event
                        fromDictionary:@{
                            @"currency" : @"USD",
                            @"checkoutStep" : @1,
                            @"checkoutOptions" : @"Visa",
                            @"productActionListName" : @"checkout-list",
                            @"productActionListSource" : @"app",
                            @"screenName" : @"Checkout",
                            @"nonInteractive" : @YES,
                            @"shouldUploadEvent" : @NO,
                        }];

    XCTAssertEqualObjects(event.currency, @"USD");
    XCTAssertEqual(event.checkoutStep, 1);
    XCTAssertEqualObjects(event.checkoutOptions, @"Visa");
    XCTAssertEqualObjects(event.productListName, @"checkout-list");
    XCTAssertEqualObjects(event.productListSource, @"app");
    XCTAssertEqualObjects(event.screenName, @"Checkout");
    XCTAssertTrue(event.nonInteractive);
    XCTAssertFalse(event.shouldUploadEvent);
}

- (void)testAddPromotionsFromDicts_fillsPromotionContainerForNewArchitecture
{
    RNMParticle *module = [[RNMParticle alloc] init];
    MPCommerceEvent *event = [[MPCommerceEvent alloc] init];
    event.promotionContainer = [[MPPromotionContainer alloc] initWithAction:MPPromotionActionView promotion:nil];

    [module addPromotionsFromDicts:@[
        @{
            @"id" : @"promo-1",
            @"name" : @"Sale",
            @"creative" : @"banner",
            @"position" : @"home-top",
        }
    ]
                  toCommerceEvent:event];

    XCTAssertEqual(event.promotionContainer.promotions.count, 1);
    MPPromotion *promotion = event.promotionContainer.promotions.firstObject;
    XCTAssertEqualObjects(promotion.promotionId, @"promo-1");
    XCTAssertEqualObjects(promotion.name, @"Sale");
    XCTAssertEqualObjects(promotion.creative, @"banner");
    XCTAssertEqualObjects(promotion.position, @"home-top");
}

#pragma mark - Timestamps and explicit nulls

/**
 * `RNMParticle.mm` used to carry two `RCTConvert` categories implementing these
 * same selectors, and which one the runtime picked was undefined. The copy that
 * won assigned raw JS numbers into `NSDate *` properties and read alias times as
 * seconds rather than milliseconds. These tests pin the surviving semantics so a
 * reintroduced duplicate fails here instead of silently in production.
 *
 * The JS contract is epoch milliseconds throughout (`js/codegenSpecs/NativeMParticle.ts`,
 * and the Android bridge passes the same values through unscaled), so every
 * conversion into an Apple `NSDate` divides by 1000.
 */

- (void)testMPEventFromJSON_convertsMillisecondTimesToDates
{
    MPEvent *event = [RCTConvert MPEvent:@{
        @"name" : @"Timed Event",
        @"type" : @(8),
        @"startTime" : @1700000000000,
        @"endTime" : @1700000005000,
        @"duration" : @5000,
        @"category" : @"checkout",
    }];

    XCTAssertTrue([event.startTime isKindOfClass:[NSDate class]]);
    XCTAssertTrue([event.endTime isKindOfClass:[NSDate class]]);
    XCTAssertEqualWithAccuracy(event.startTime.timeIntervalSince1970, 1700000000.0, 0.001);
    XCTAssertEqualWithAccuracy(event.endTime.timeIntervalSince1970, 1700000005.0, 0.001);
    // MPEvent.duration is milliseconds on both platforms - pass through, no scaling.
    XCTAssertEqualObjects(event.duration, @5000);
    XCTAssertEqualObjects(event.category, @"checkout");
}

- (void)testMPEventFromJSON_treatsExplicitNullAsAbsent
{
    MPEvent *event = [RCTConvert MPEvent:@{
        @"name" : @"Untimed Event",
        @"type" : @(8),
        @"startTime" : [NSNull null],
        @"endTime" : [NSNull null],
        @"duration" : [NSNull null],
        @"category" : [NSNull null],
    }];

    XCTAssertNil(event.startTime);
    XCTAssertNil(event.endTime);
    XCTAssertNil(event.category);
    // MPEvent's initializer seeds duration to @0, so the converter leaving it
    // alone is correct; what matters is that NSNull never reaches the property.
    XCTAssertEqualObjects(event.duration, @0);
}

- (void)testMPAliasRequestFromJSON_convertsMillisecondTimesToDates
{
    MPAliasRequest *request = [RCTConvert MPAliasRequest:@{
        @"sourceMpid" : @"123",
        @"destinationMpid" : @"456",
        @"startTime" : @1700000000000,
        @"endTime" : @1700000005000,
    }];

    XCTAssertEqualObjects(request.sourceMPID, @123);
    XCTAssertEqualObjects(request.destinationMPID, @456);
    // Regression: the shadowed converter treated these milliseconds as seconds,
    // producing dates ~1000x in the future.
    XCTAssertEqualWithAccuracy(request.startTime.timeIntervalSince1970, 1700000000.0, 0.001);
    XCTAssertEqualWithAccuracy(request.endTime.timeIntervalSince1970, 1700000005.0, 0.001);
}

- (void)testMPAliasRequestFromJSON_treatsExplicitNullAsAbsent
{
    MPAliasRequest *request = [RCTConvert MPAliasRequest:@{
        @"sourceMpid" : @"123",
        @"destinationMpid" : @"456",
        @"startTime" : [NSNull null],
        @"endTime" : [NSNull null],
    }];

    XCTAssertNil(request.startTime);
    XCTAssertNil(request.endTime);
}

- (void)testGDPRConsentFromJSON_convertsMillisecondTimestampAndTreatsNullAsAbsent
{
    MPGDPRConsent *consent = [RCTConvert MPGDPRConsent:@{
        @"consented" : @YES,
        @"timestamp" : @1700000000000,
        @"document" : @"terms-v3",
        @"location" : [NSNull null],
        @"hardwareId" : [NSNull null],
    }];

    XCTAssertTrue(consent.consented);
    XCTAssertEqualWithAccuracy(consent.timestamp.timeIntervalSince1970, 1700000000.0, 0.001);
    XCTAssertEqualObjects(consent.document, @"terms-v3");
    XCTAssertNil(consent.location);
    XCTAssertNil(consent.hardwareId);
}

- (void)testCCPAConsentFromJSON_convertsMillisecondTimestampAndTreatsNullAsAbsent
{
    MPCCPAConsent *consent = [RCTConvert MPCCPAConsent:@{
        @"consented" : @NO,
        @"timestamp" : @1700000000000,
        @"document" : [NSNull null],
        @"location" : @"https://example.com/privacy",
        @"hardwareId" : [NSNull null],
    }];

    XCTAssertFalse(consent.consented);
    XCTAssertEqualWithAccuracy(consent.timestamp.timeIntervalSince1970, 1700000000.0, 0.001);
    XCTAssertNil(consent.document);
    XCTAssertEqualObjects(consent.location, @"https://example.com/privacy");
    XCTAssertNil(consent.hardwareId);
}

- (void)testMPCommerceEventFromJSON_treatsExplicitNullStringsAsAbsent
{
    MPCommerceEvent *event = [RCTConvert MPCommerceEvent:@{
        @"productActionType" : @(7),
        @"products" : @[ [self minimalProductJSON] ],
        @"impressions" : @[],
        @"currency" : [NSNull null],
        @"checkoutOptions" : [NSNull null],
        @"productActionListName" : [NSNull null],
        @"productActionListSource" : [NSNull null],
        @"screenName" : [NSNull null],
    }];

    XCTAssertNil(event.currency);
    XCTAssertNil(event.checkoutOptions);
    XCTAssertNil(event.productListName);
    XCTAssertNil(event.productListSource);
    XCTAssertNil(event.screenName);
}

#pragma mark - Commerce logging API

/**
 * `-[MParticle logCommerceEvent:]` was removed from the public headers in
 * mParticle-Apple-SDK 9.0 while its implementation stayed behind, which broke the
 * legacy-architecture bridge. `logEvent:` is the replacement and accepts any
 * MPBaseEvent subclass. Fails loudly if a future SDK bump moves that too.
 */
- (void)testCommerceEventsAreLoggableThroughLogEvent
{
    XCTAssertTrue([MPCommerceEvent isSubclassOfClass:[MPBaseEvent class]]);
    XCTAssertTrue([[MParticle sharedInstance] respondsToSelector:@selector(logEvent:)]);
}

@end
