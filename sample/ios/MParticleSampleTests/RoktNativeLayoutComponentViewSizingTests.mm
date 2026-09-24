#import <XCTest/XCTest.h>
#import "../../../ios/RNMParticle/RoktNativeLayoutComponentView.h"

// Deliberately not wrapped in #ifdef RCT_NEW_ARCH_ENABLED: the header is, so a build
// without New Architecture fails here instead of silently compiling zero tests.

/**
 * Guards how the Fabric wrapper sizes the `RoktEmbeddedView` it hosts.
 *
 * The Rokt SDK owns the embedded view's height: `RoktEmbeddedView.updateEmbeddedSize(_:)`
 * writes `frame.height` itself, and only afterwards emits the size event that makes JS
 * resize this component view. If the wrapper also let the embedded view autoresize its
 * height, UIKit would re-apply the SDK's height delta once React Native caught up, leaving
 * the embedded view `2 * height - previousParentHeight` tall. SwiftUI then centres the
 * layout in that taller host (blank space above it) and the parent clips its bottom half,
 * CTA and pager included.
 *
 * `simulateSDKResize:` mirrors that SDK write rather than calling it: the SDK method is a
 * no-op until a layout has been loaded, which needs a live placement.
 */
@interface RoktNativeLayoutComponentViewSizingTests : XCTestCase
@end

@implementation RoktNativeLayoutComponentViewSizingTests {
    RoktNativeLayoutComponentView *_componentView;
}

- (void)setUp
{
    [super setUp];
    // Fabric mounts the component before the placement loads, at zero height.
    _componentView = [[RoktNativeLayoutComponentView alloc] initWithFrame:CGRectMake(0, 0, 330, 0)];
}

- (void)simulateSDKResize:(CGFloat)height
{
    UIView *embedded = _componentView.roktEmbeddedView;
    embedded.frame = CGRectMake(embedded.frame.origin.x, embedded.frame.origin.y, embedded.frame.size.width, height);
}

- (void)simulateReactNativeResize:(CGFloat)height
{
    _componentView.frame = CGRectMake(0, 0, _componentView.frame.size.width, height);
    [_componentView layoutIfNeeded];
}

- (void)testEmbeddedHeightMatchesReportedHeightAfterReactNativeCatchesUp
{
    [self simulateSDKResize:415];
    [self simulateReactNativeResize:415];

    XCTAssertEqualWithAccuracy(_componentView.roktEmbeddedView.frame.size.height, 415, 0.5);
}

- (void)testEmbeddedHeightDoesNotAccumulateAcrossSuccessiveResizes
{
    [self simulateSDKResize:365];
    [self simulateReactNativeResize:365];
    [self simulateSDKResize:533];
    [self simulateReactNativeResize:533];

    XCTAssertEqualWithAccuracy(_componentView.roktEmbeddedView.frame.size.height, 533, 0.5);
}

- (void)testEmbeddedWidthFollowsComponentWidth
{
    [self simulateSDKResize:415];
    _componentView.frame = CGRectMake(0, 0, 390, 415);
    [_componentView layoutIfNeeded];

    XCTAssertEqualWithAccuracy(_componentView.roktEmbeddedView.frame.size.width, 390, 0.5);
}

@end
