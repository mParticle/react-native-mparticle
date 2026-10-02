#import <XCTest/XCTest.h>
#import "../../../ios/RNMParticle/RNMPSDKImports.h"
#import "../../../ios/RNMParticle/RNMPRoktSwift.h"

/**
 * RNMPRoktSwift.h declares the Swift classes by hand, so nothing checks it against the Swift code
 * at compile time. A mismatch only fails at runtime with "unrecognized selector", so check every
 * declared selector here.
 */
@interface RNMPRoktSwiftTests : XCTestCase
@end

@implementation RNMPRoktSwiftTests

- (void)testDeclaredSelectorsExist
{
    XCTAssertTrue([RNMPRoktEventMapper respondsToSelector:@selector(mapEvent:viewName:)]);
    XCTAssertTrue([RNMPRoktEventMapper respondsToSelector:@selector(placementFailure)]);
    XCTAssertTrue([RNMPRoktConfigFactory respondsToSelector:@selector(configFromDictionary:)]);
    XCTAssertTrue([RNMPRoktViews respondsToSelector:@selector(makeEmbeddedViewWithFrame:)]);
    XCTAssertTrue([RNMPRoktViews respondsToSelector:@selector(isEmbeddedView:)]);
}

- (void)testDeclaredTypes
{
    XCTAssertTrue([[RNMPRoktEventMapper placementFailure] isKindOfClass:[RoktPlacementFailure class]]);
    XCTAssertNil([(RoktPlacementFailure *)[RNMPRoktEventMapper placementFailure] identifier]);

    UIView *view = [RNMPRoktViews makeEmbeddedViewWithFrame:CGRectMake(0, 0, 10, 20)];
    XCTAssertTrue([view isKindOfClass:[RoktEmbeddedView class]]);
    XCTAssertTrue(CGRectEqualToRect(view.frame, CGRectMake(0, 0, 10, 20)));
    XCTAssertTrue([RNMPRoktViews isEmbeddedView:view]);
    XCTAssertFalse([RNMPRoktViews isEmbeddedView:[[UIView alloc] init]]);
    XCTAssertFalse([RNMPRoktViews isEmbeddedView:nil]);
}

@end
