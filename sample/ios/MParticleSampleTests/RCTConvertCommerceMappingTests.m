#import <XCTest/XCTest.h>
#import <React/RCTConvert.h>

// Match RNMParticle.mm / pod umbrella so tests compile against the same SDK the library uses.
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK_ObjC/mParticle.h>)
#import <mParticle_Apple_SDK_ObjC/mParticle.h>
#elif defined(__has_include) && __has_include(<mParticle_Apple_SDK/mParticle.h>)
#import <mParticle_Apple_SDK/mParticle.h>
#else
#import <mParticle_Apple_SDK_ObjC/mParticle.h>
#endif

// Implemented on `RCTConvert` in `RNMParticle.mm` (react-native-mparticle pod).
@interface RCTConvert (MPCommerceEvent)
+ (MPCommerceEvent *)MPCommerceEvent:(id)json;
+ (MPCommerceEventAction)MPCommerceEventAction:(id)json;
+ (MPPromotionAction)MPPromotionAction:(id)json;
@end

/**
 * Guards JS → native commerce enum mapping used by the bridge (including New Architecture).
 * Constants must stay aligned with `ProductActionType` / `PromotionActionType` in js/index.tsx.
 *
 * Direct `MPCommerceEventAction` / `MPPromotionAction` tests above validate the table only.
 * JSON → `MPCommerceEvent` tests below exercise the same `+[RCTConvert MPCommerceEvent:]` pipeline
 * used to assemble an `MPCommerceEvent` before `-[MParticle logCommerceEvent:]` (legacy bridge path),
 * including `MPPromotionContainer:` wiring. That catches regressions such as casting JS ints in
 * those helpers instead of calling the mappers. The New Architecture TurboModule `logCommerceEvent`
 * codegen struct path is still not invoked here (would require generated C++ types in this target).
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

- (void)testMPCommerceEventFromJSON_productActionFlowsThroughRCTConvertCommerceEvent
{
    NSDictionary *json = @{
        @"productActionType" : @(7), // Purchase in js/index.tsx
        @"products" : @[ [self minimalProductJSON] ],
        @"impressions" : @[],
    };

    MPCommerceEvent *event = [RCTConvert MPCommerceEvent:json];
    XCTAssertEqual(event.action, MPCommerceEventActionPurchase);
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

@end
