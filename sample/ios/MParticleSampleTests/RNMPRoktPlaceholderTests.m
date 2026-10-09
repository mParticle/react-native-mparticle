#import <XCTest/XCTest.h>
#import <React/RCTInvalidating.h>
#import <React/RCTLog.h>
#import "../../../ios/RNMParticle/RNMPSDKImports.h"
#import "../../../ios/RNMParticle/RNMPRokt.h"
#import "../../../ios/RNMParticle/RoktPlaceholderRegistry.h"

// Implemented in RNMPRokt.mm.
@interface RNMPRokt (PlaceholderTests)
- (NSMutableDictionary *)resolvePlaceholders:(NSArray *)placeholders;
+ (NSArray<NSString *> *)unmountedPlaceholderNames:(NSArray *)placeholders;
@end

/**
 * Guards how `-[RNMPRokt resolvePlaceholders:]` turns placeholder names into the embedded
 * views handed to `MPRokt selectPlacements`, looking each name up in RoktPlaceholderRegistry.
 *
 * Scope limit, deliberate: this test target statically links the react-native-mparticle
 * pod a second time on top of the app it hosts, so `RoktNativeLayoutComponentView` and
 * `RNMPRokt` each exist in two binaries and `isKindOfClass:` cannot match across them
 * ("Class ... is implemented in both", i.e. the runtime's spurious-casting-failure
 * warning). Asserting a mounted placeholder resolves all the way to its `RoktEmbeddedView`
 * would therefore be testing the linkage, not the code. That step is verified by running
 * an embedded placement in the sample app instead. What is covered below is
 * binary-independent: every branch that refuses to resolve a placeholder.
 */
@interface RNMPRoktPlaceholderTests : XCTestCase
@end

@implementation RNMPRoktPlaceholderTests {
    RNMPRokt *_rokt;
    NSInteger _loggedErrorCount;
    NSMutableArray<NSString *> *_loggedErrors;
    RCTLogFunction _originalLogFunction;
}

- (void)setUp
{
    [super setUp];
    _rokt = [RNMPRokt new];

    // Unresolvable placeholders are reported via RCTLogError. Capture instead of letting
    // it surface as test noise, so the diagnostic itself can be asserted.
    _loggedErrorCount = 0;
    _loggedErrors = [NSMutableArray new];
    _originalLogFunction = RCTGetLogFunction();
    __weak __typeof__(self) weakSelf = self;
    RCTSetLogFunction(^(RCTLogLevel level,
                        __unused RCTLogSource source,
                        __unused NSString *fileName,
                        __unused NSNumber *lineNumber,
                        NSString *message) {
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        if (strongSelf && level >= RCTLogLevelError) {
            strongSelf->_loggedErrorCount++;
            [strongSelf->_loggedErrors addObject:message ?: @""];
        }
    });
}

- (void)tearDown
{
    [RoktPlaceholderRegistry cancelAllWaits];
    RCTSetLogFunction(_originalLogFunction);
    _rokt = nil;
    [super tearDown];
}

- (void)testSkipsNameWithNoMountedView
{
    NSDictionary *resolved = [_rokt resolvePlaceholders:@[ @"Location1" ]];

    XCTAssertEqual(resolved.count, 0u);
    XCTAssertEqual(_loggedErrorCount, 1, @"errors: %@", _loggedErrors);
    XCTAssertTrue([_loggedErrors.firstObject hasPrefix:@"Cannot resolve placeholder"],
                  @"errors: %@", _loggedErrors);
}

- (void)testSkipsNameRegisteredToUnexpectedViewClass
{
    UIView *view = [UIView new];
    [RoktPlaceholderRegistry registerView:view name:@"Location1"];

    NSDictionary *resolved = [_rokt resolvePlaceholders:@[ @"Location1" ]];

    XCTAssertEqual(resolved.count, 0u);
    XCTAssertEqual(_loggedErrorCount, 1, @"errors: %@", _loggedErrors);
    [RoktPlaceholderRegistry unregisterView:view];
}

- (void)testSkipsNonStringEntriesWithoutThrowing
{
    // Defensive coverage for malformed direct native calls, such as a legacy react tag:
    // only placeholderName strings are looked up.
    NSDictionary *resolved = [_rokt resolvePlaceholders:@[ [NSNull null], @101 ]];

    XCTAssertEqual(resolved.count, 0u);
    XCTAssertEqual(_loggedErrorCount, 2, @"errors: %@", _loggedErrors);
    XCTAssertTrue([_loggedErrors.firstObject hasPrefix:@"Cannot resolve placeholder"],
                  @"errors: %@", _loggedErrors);
}

- (void)testUnmountedPlaceholderNamesListsOnlyUnregisteredStrings
{
    UIView *view = [UIView new];
    [RoktPlaceholderRegistry registerView:view name:@"Location1"];

    NSArray *pending = [RNMPRokt unmountedPlaceholderNames:@[ @"Location1", @"Location2", @101 ]];

    XCTAssertEqualObjects(pending, (@[ @"Location2" ]));
    [RoktPlaceholderRegistry unregisterView:view];
}

// Name-based resolution goes through RoktPlaceholderRegistry. Its semantics are
// binary-independent, so they are asserted directly with plain views; the final
// isKindOfClass: step hits the same linkage limit described above.

- (void)testRegistryResolvesRegisteredViewByName
{
    UIView *view = [UIView new];
    [RoktPlaceholderRegistry registerView:view name:@"Location1"];

    XCTAssertEqualObjects([RoktPlaceholderRegistry viewForName:@"Location1"], view);
    XCTAssertNil([RoktPlaceholderRegistry viewForName:@"Location2"]);
    [RoktPlaceholderRegistry unregisterView:view];
}

- (void)testRegistryRenameMovesView
{
    UIView *view = [UIView new];
    [RoktPlaceholderRegistry registerView:view name:@"Location1"];
    [RoktPlaceholderRegistry registerView:view name:@"Location2"];

    XCTAssertNil([RoktPlaceholderRegistry viewForName:@"Location1"]);
    XCTAssertEqualObjects([RoktPlaceholderRegistry viewForName:@"Location2"], view);
    [RoktPlaceholderRegistry unregisterView:view];
}

- (void)testRegistryKeepsOlderViewWhenNewerSharedNameIsDropped
{
    // Stacked screens can each mount the same placeholder name.
    UIView *lower = [UIView new];
    UIView *upper = [UIView new];
    [RoktPlaceholderRegistry registerView:lower name:@"Location1"];
    [RoktPlaceholderRegistry registerView:upper name:@"Location1"];
    XCTAssertEqualObjects([RoktPlaceholderRegistry viewForName:@"Location1"], upper);

    [RoktPlaceholderRegistry unregisterView:upper];

    XCTAssertEqualObjects([RoktPlaceholderRegistry viewForName:@"Location1"], lower);
    [RoktPlaceholderRegistry unregisterView:lower];
}

- (void)testRegistryPrefersViewInWindow
{
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    UIView *inWindow = [UIView new];
    [window addSubview:inWindow];
    UIView *offscreen = [UIView new];
    [RoktPlaceholderRegistry registerView:inWindow name:@"Location1"];
    [RoktPlaceholderRegistry registerView:offscreen name:@"Location1"];

    XCTAssertEqualObjects([RoktPlaceholderRegistry viewForName:@"Location1"], inWindow);
    [RoktPlaceholderRegistry unregisterView:inWindow];
    [RoktPlaceholderRegistry unregisterView:offscreen];
}

- (void)testLegacyEmbeddedViewUnregistersWhenInvalidated
{
    // RCTUIManager invalidates each view it removes; a view still retained elsewhere must not stay
    // resolvable by name, or selectPlacements would skip the mount wait and embed into it.
    // The category is compiled only into legacy-architecture builds of the library.
    XCTSkipUnless([RoktEmbeddedView conformsToProtocol:@protocol(RCTInvalidating)],
                  @"library built for the New Architecture");
    RoktEmbeddedView *view = [RoktEmbeddedView new];
    [RoktPlaceholderRegistry registerView:view name:@"Location1"];

    [(id<RCTInvalidating>)view invalidate];

    XCTAssertNil([RoktPlaceholderRegistry viewForName:@"Location1"]);
}

- (void)testRegistryDropsDeallocatedViews
{
    @autoreleasepool {
        [RoktPlaceholderRegistry registerView:[UIView new] name:@"Location1"];
    }

    XCTAssertNil([RoktPlaceholderRegistry viewForName:@"Location1"]);
}

- (void)testEmptyPlaceholdersResolveToEmptyDictionary
{
    // Overlay / bottom-sheet placements pass no placeholders at all, so this path must not
    // depend on the view hierarchy in any way.
    NSDictionary *resolved = [_rokt resolvePlaceholders:@[]];

    XCTAssertEqual(resolved.count, 0u);
    XCTAssertEqual(_loggedErrorCount, 0, @"errors: %@", _loggedErrors);
}

// selectPlacements may arrive before its placeholders mount (e.g. from the useEffect that
// rendered them), so it waits on the registry. Completion is dispatched to the main queue so it
// never runs inside the mount transaction that registered the view.

- (void)testWaitCompletesAfterPlaceholderRegisters
{
    XCTestExpectation *done = [self expectationWithDescription:@"wait completed"];
    UIView *view = [UIView new];
    [RoktPlaceholderRegistry waitForNames:@[ @"Location1" ] key:@"page" timeout:10 completion:^{
        [done fulfill];
    } discarded:^{}];

    [RoktPlaceholderRegistry registerView:view name:@"Location1"];

    [self waitForExpectations:@[ done ] timeout:1];
    [RoktPlaceholderRegistry unregisterView:view];
}

- (void)testWaitCompletesOnTimeoutWhenPlaceholderNeverMounts
{
    XCTestExpectation *done = [self expectationWithDescription:@"wait timed out"];
    [RoktPlaceholderRegistry waitForNames:@[ @"Location1" ] key:@"page" timeout:0.1 completion:^{
        [done fulfill];
    } discarded:^{}];

    [self waitForExpectations:@[ done ] timeout:1];
}

- (void)testNewerWaitWithSameKeyReplacesOlder
{
    XCTestExpectation *older = [self expectationWithDescription:@"older wait"];
    older.inverted = YES;
    XCTestExpectation *olderDiscarded = [self expectationWithDescription:@"older wait discarded"];
    XCTestExpectation *newer = [self expectationWithDescription:@"newer wait"];
    UIView *view = [UIView new];
    [RoktPlaceholderRegistry waitForNames:@[ @"Location1" ] key:@"page" timeout:0.1 completion:^{
        [older fulfill];
    } discarded:^{
        [olderDiscarded fulfill];
    }];
    [RoktPlaceholderRegistry waitForNames:@[ @"Location1" ] key:@"page" timeout:10 completion:^{
        [newer fulfill];
    } discarded:^{
        XCTFail(@"the newer wait must not be discarded");
    }];

    [RoktPlaceholderRegistry registerView:view name:@"Location1"];

    [self waitForExpectations:@[ older, olderDiscarded, newer ] timeout:0.5];
    [RoktPlaceholderRegistry unregisterView:view];
}

- (void)testCancelledWaitIsDiscardedAndNeverCompletes
{
    XCTestExpectation *done = [self expectationWithDescription:@"cancelled wait"];
    done.inverted = YES;
    XCTestExpectation *discarded = [self expectationWithDescription:@"cancelled wait discarded"];
    [RoktPlaceholderRegistry waitForNames:@[ @"Location1" ] key:@"page" timeout:0.1 completion:^{
        [done fulfill];
    } discarded:^{
        [discarded fulfill];
    }];

    [RoktPlaceholderRegistry cancelAllWaits];

    [self waitForExpectations:@[ done, discarded ] timeout:0.5];
}

@end
