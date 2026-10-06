#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import "../../../ios/RNMParticle/RNMPSDKImports.h"
#import "../../../ios/RNMParticle/RoktEventManager.h"

/**
 * Pins what RoktEventManager sends to JavaScript for every Rokt event: the `RoktEvents` payload
 * and the `RoktCallback` / `LayoutHeightChanges` events some of them also trigger, in order.
 * Written against the original Objective-C mapping, which RNMPRoktEventMapper replaced unchanged.
 */
static NSMutableArray<NSArray *> *RNMPSentEvents;

// Records instead of sending. Adds no ivars, so an existing manager can be switched to it.
@interface RNMPRecordingEventManager : RoktEventManager
@end

@implementation RNMPRecordingEventManager
- (void)sendEventWithName:(NSString *)name body:(id)body
{
    [RNMPSentEvents addObject:@[ name, body ]];
}
@end

@interface RNMPRoktEventMapperTests : XCTestCase
@end

@implementation RNMPRoktEventMapperTests {
    RoktEventManager *_manager;
    Class _originalClass;
}

- (void)setUp
{
    [super setUp];
    RNMPSentEvents = [NSMutableArray array];
    _manager = [RoktEventManager allocWithZone:nil];
    _originalClass = object_getClass(_manager);
    object_setClass(_manager, [RNMPRecordingEventManager class]);
    [_manager startObserving];
}

- (void)tearDown
{
    [_manager stopObserving];
    object_setClass(_manager, _originalClass);
    [super tearDown];
}

- (NSArray<NSArray *> *)send:(RoktEvent *)event
{
    [RNMPSentEvents removeAllObjects];
    [_manager onRoktEvents:event viewName:@"checkout"];
    return [RNMPSentEvents copy];
}

- (NSArray *)roktEvents:(NSDictionary *)fields
{
    NSMutableDictionary *payload = [fields mutableCopy];
    payload[@"viewName"] = @"checkout";
    return @[ @"RoktEvents", payload ];
}

- (NSArray *)callback:(NSString *)value
{
    return @[ @"RoktCallback", @{@"callbackValue" : value} ];
}

- (void)testLoadingIndicatorsAlsoSendCallbacks
{
    XCTAssertEqualObjects([self send:[[RoktShowLoadingIndicator alloc] init]],
                          (@[ [self callback:@"onShouldShowLoadingIndicator"], [self roktEvents:@{@"event" : @"ShowLoadingIndicator"}] ]));
    XCTAssertEqualObjects([self send:[[RoktHideLoadingIndicator alloc] init]],
                          (@[ [self callback:@"onShouldHideLoadingIndicator"], [self roktEvents:@{@"event" : @"HideLoadingIndicator"}] ]));
}

- (void)testPlacementLifecycleEvents
{
    XCTAssertEqualObjects([self send:[[RoktPlacementReady alloc] initWithIdentifier:@"p1"]],
                          (@[ [self callback:@"onLoad"], [self roktEvents:@{@"event" : @"PlacementReady", @"placementId" : @"p1"}] ]));
    XCTAssertEqualObjects([self send:[[RoktPlacementClosed alloc] initWithIdentifier:@"p1"]],
                          (@[ [self callback:@"onUnLoad"], [self roktEvents:@{@"event" : @"PlacementClosed", @"placementId" : @"p1"}] ]));

    NSDictionary<NSString *, RoktEvent *> *plain = @{
        @"PlacementInteractive" : [[RoktPlacementInteractive alloc] initWithIdentifier:@"p1"],
        @"OfferEngagement" : [[RoktOfferEngagement alloc] initWithIdentifier:@"p1"],
        @"PositiveEngagement" : [[RoktPositiveEngagement alloc] initWithIdentifier:@"p1"],
        @"PlacementCompleted" : [[RoktPlacementCompleted alloc] initWithIdentifier:@"p1"],
        @"PlacementFailure" : [[RoktPlacementFailure alloc] initWithIdentifier:@"p1"],
        @"FirstPositiveEngagement" : [[RoktFirstPositiveEngagement alloc] initWithIdentifier:@"p1" setFulfillmentAttributes:nil],
        @"InstantPurchaseDismissal" : [[RoktInstantPurchaseDismissal alloc] initWithIdentifier:@"p1"],
    };
    [plain enumerateKeysAndObjectsUsingBlock:^(NSString *name, RoktEvent *event, BOOL *stop) {
        XCTAssertEqualObjects([self send:event], (@[ [self roktEvents:@{@"event" : name, @"placementId" : @"p1"}] ]), @"%@", name);
    }];
}

- (void)testMissingIdentifierIsOmitted
{
    XCTAssertEqualObjects([self send:[[RoktPlacementFailure alloc] initWithIdentifier:nil]],
                          (@[ [self roktEvents:@{@"event" : @"PlacementFailure"}] ]));
}

- (void)testInitCompleteAndOpenUrl
{
    XCTAssertEqualObjects([self send:[[RoktInitComplete alloc] initWithSuccess:YES]],
                          (@[ [self roktEvents:@{@"event" : @"InitComplete", @"status" : @"true"}] ]));
    XCTAssertEqualObjects([self send:[[RoktInitComplete alloc] initWithSuccess:NO]],
                          (@[ [self roktEvents:@{@"event" : @"InitComplete", @"status" : @"false"}] ]));
    XCTAssertEqualObjects([self send:[[RoktOpenUrl alloc] initWithIdentifier:@"p1" url:@"https://example.com"]],
                          (@[ [self roktEvents:@{@"event" : @"OpenUrl", @"placementId" : @"p1", @"url" : @"https://example.com"}] ]));
}

- (void)testEmbeddedSizeChangedAlsoSendsTheHeight
{
    XCTAssertEqualObjects([self send:[[RoktEmbeddedSizeChanged alloc] initWithIdentifier:@"p1" updatedHeight:412.5]],
                          (@[ @[ @"LayoutHeightChanges", @{@"height" : @412.5, @"selectedPlacement" : @"p1"} ],
                              [self roktEvents:@{@"event" : @"EmbeddedSizeChanged", @"placementId" : @"p1"}] ]));
}

- (void)testInstantPurchaseEvents
{
    RoktEvent *purchase = [[RoktCartItemInstantPurchase alloc] initWithIdentifier:@"p1"
                                                                             name:@"ignored"
                                                                       cartItemId:@"cart"
                                                                    catalogItemId:@"catalog"
                                                                         currency:@"USD"
                                                                      description:@"A thing"
                                                                  linkedProductId:@"linked"
                                                                     providerData:@"data"
                                                                         quantity:[NSDecimalNumber decimalNumberWithString:@"2"]
                                                                       totalPrice:[NSDecimalNumber decimalNumberWithString:@"19.98"]
                                                                        unitPrice:[NSDecimalNumber decimalNumberWithString:@"9.99"]];
    XCTAssertEqualObjects([self send:purchase], (@[ [self roktEvents:@{
                              @"event" : @"CartItemInstantPurchase",
                              @"placementId" : @"p1",
                              @"cartItemId" : @"cart",
                              @"catalogItemId" : @"catalog",
                              @"currency" : @"USD",
                              @"description" : @"A thing",
                              @"linkedProductId" : @"linked",
                              @"providerData" : @"data",
                              @"quantity" : [NSDecimalNumber decimalNumberWithString:@"2"],
                              @"totalPrice" : [NSDecimalNumber decimalNumberWithString:@"19.98"],
                              @"unitPrice" : [NSDecimalNumber decimalNumberWithString:@"9.99"],
                          }] ]));

    RoktEvent *sparse = [[RoktCartItemInstantPurchase alloc] initWithIdentifier:@"p1" name:nil cartItemId:@"cart" catalogItemId:@"catalog" currency:@"USD" description:@"A thing" linkedProductId:nil providerData:@"data" quantity:nil totalPrice:nil unitPrice:nil];
    XCTAssertEqualObjects([self send:sparse], (@[ [self roktEvents:@{
                              @"event" : @"CartItemInstantPurchase",
                              @"placementId" : @"p1",
                              @"cartItemId" : @"cart",
                              @"catalogItemId" : @"catalog",
                              @"currency" : @"USD",
                              @"description" : @"A thing",
                              @"providerData" : @"data",
                          }] ]));

    XCTAssertEqualObjects([self send:[[RoktCartItemInstantPurchaseInitiated alloc] initWithIdentifier:@"p1" catalogItemId:@"catalog" cartItemId:@"cart"]],
                          (@[ [self roktEvents:@{@"event" : @"CartItemInstantPurchaseInitiated", @"placementId" : @"p1", @"catalogItemId" : @"catalog", @"cartItemId" : @"cart"}] ]));
    XCTAssertEqualObjects([self send:[[RoktCartItemInstantPurchaseFailure alloc] initWithIdentifier:@"p1" catalogItemId:@"catalog" cartItemId:@"cart" error:@"declined"]],
                          (@[ [self roktEvents:@{@"event" : @"CartItemInstantPurchaseFailure", @"placementId" : @"p1", @"catalogItemId" : @"catalog", @"cartItemId" : @"cart", @"error" : @"declined"}] ]));
    XCTAssertEqualObjects([self send:[[RoktCartItemDevicePay alloc] initWithIdentifier:@"p1" catalogItemId:@"catalog" cartItemId:@"cart" paymentProvider:@"applePay"]],
                          (@[ [self roktEvents:@{@"event" : @"CartItemDevicePay", @"placementId" : @"p1", @"catalogItemId" : @"catalog", @"cartItemId" : @"cart", @"paymentProvider" : @"applePay"}] ]));
}

- (void)testUnknownEventSendsAnEmptyName
{
    XCTAssertEqualObjects([self send:[[RoktEvent alloc] init]], (@[ [self roktEvents:@{@"event" : @""}] ]));
}

- (void)testNilViewNameIsOmitted
{
    [RNMPSentEvents removeAllObjects];
    [_manager onRoktEvents:[[RoktPlacementReady alloc] initWithIdentifier:@"p1"] viewName:nil];
    XCTAssertEqualObjects(RNMPSentEvents.lastObject, (@[ @"RoktEvents", @{@"event" : @"PlacementReady", @"placementId" : @"p1"} ]));
}

- (void)testNothingIsSentWithoutListeners
{
    [_manager stopObserving];
    XCTAssertEqualObjects([self send:[[RoktPlacementReady alloc] initWithIdentifier:@"p1"]], @[]);
}

@end
