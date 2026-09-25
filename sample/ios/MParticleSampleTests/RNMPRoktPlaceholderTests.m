#import <XCTest/XCTest.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTLog.h>
#import "../../../ios/RNMParticle/RNMPRokt.h"
#import "../../../ios/RNMParticle/RoktPlaceholderRegistry.h"

// Implemented in RNMPRokt.mm.
@interface RNMPRokt (PlaceholderTests)
- (NSMutableDictionary *)resolvePlaceholders:(NSDictionary *)placeholders;
@end

/**
 * Guards how `-[RNMPRokt resolvePlaceholders:]` turns placeholder react tags into the
 * embedded views handed to `MPRokt selectPlacements`.
 *
 * Resolution goes through `RCTViewRegistry` rather than the legacy
 * `self.bridge.uiManager addUIBlock:` view registry, because the latter is a no-op method
 * body when RCT_REMOVE_LEGACY_ARCH is defined (React Native 0.84's default) and a no-op
 * when `self.bridge` is nil — either way selectPlacements was discarded with no event
 * emitted. The registry is exercised for real here: the tests install a bridgeless
 * component-view provider, the same hook RCTInstance wires to the surface presenter in
 * production.
 *
 * Scope limit, deliberate: this test target statically links the react-native-mparticle
 * pod a second time on top of the app it hosts, so `RoktNativeLayoutComponentView` and
 * `RNMPRokt` each exist in two binaries and `isKindOfClass:` cannot match across them
 * ("Class ... is implemented in both", i.e. the runtime's spurious-casting-failure
 * warning). Asserting a mounted placeholder resolves all the way to its `RoktEmbeddedView`
 * would therefore be testing the linkage, not the code. That step is verified by running
 * an embedded placement in the sample app instead. What is covered below is
 * binary-independent: that the module is wired to a working registry, and every branch
 * that refuses to resolve a tag.
 */
@interface RNMPRoktPlaceholderTests : XCTestCase
@end

@implementation RNMPRoktPlaceholderTests {
    RNMPRokt *_rokt;
    // viewRegistry_DEPRECATED is a weak property (React Native retains the registry via
    // RCTBridgeModuleDecorator for the instance's lifetime), so the test has to own it.
    RCTViewRegistry *_viewRegistry;
    NSMutableDictionary<NSNumber *, UIView *> *_views;
    NSInteger _loggedErrorCount;
    NSMutableArray<NSString *> *_loggedErrors;
    RCTLogFunction _originalLogFunction;
}

- (void)setUp
{
    [super setUp];
    _rokt = [RNMPRokt new];
    _views = [NSMutableDictionary new];

    _viewRegistry = [RCTViewRegistry new];
    __weak __typeof__(self) weakSelf = self;
    [_viewRegistry setBridgelessComponentViewProvider:^UIView *(NSNumber *reactTag) {
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        return strongSelf ? strongSelf->_views[reactTag] : nil;
    }];
    _rokt.viewRegistry_DEPRECATED = _viewRegistry;

    // Unresolvable placeholders are reported via RCTLogError. Capture instead of letting
    // it surface as test noise, so the diagnostic itself can be asserted.
    _loggedErrorCount = 0;
    _loggedErrors = [NSMutableArray new];
    _originalLogFunction = RCTGetLogFunction();
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
    RCTSetLogFunction(_originalLogFunction);
    _rokt = nil;
    _viewRegistry = nil;
    _views = nil;
    [super tearDown];
}

// Regression guard for the change itself: without `@synthesize viewRegistry_DEPRECATED`
// in RNMPRokt.mm the module has no way to reach a view, and every embedded placement
// silently resolves to nothing.
- (void)testModuleIsWiredToAViewRegistryThatResolvesMountedViews
{
    UIView *mountedView = [[UIView alloc] init];
    _views[@101] = mountedView;

    XCTAssertNotNil(_rokt.viewRegistry_DEPRECATED);
    XCTAssertEqualObjects([_rokt.viewRegistry_DEPRECATED viewForReactTag:@101], mountedView);
    XCTAssertNil([_rokt.viewRegistry_DEPRECATED viewForReactTag:@999]);
}

- (void)testSkipsTagThatIsNotMounted
{
    NSDictionary *resolved = [_rokt resolvePlaceholders:@{@"Location1" : @999}];

    XCTAssertEqual(resolved.count, 0u);
    XCTAssertEqual(_loggedErrorCount, 1, @"errors: %@", _loggedErrors);
}

- (void)testSkipsTagResolvingToUnexpectedViewClass
{
    _views[@101] = [[UIView alloc] init];

    NSDictionary *resolved = [_rokt resolvePlaceholders:@{@"Location1" : @101}];

    XCTAssertEqual(resolved.count, 0u);
    XCTAssertEqual(_loggedErrorCount, 1, @"errors: %@", _loggedErrors);
}

- (void)testSkipsNonNumericValueWithNoRegisteredNameWithoutThrowing
{
    // Defensive coverage for malformed direct native calls: viewForReactTag: would throw on
    // NSNull, so non-numeric values must never reach it. They are resolved by placeholder name
    // instead, and nothing is registered under these names.
    NSDictionary *resolved =
        [_rokt resolvePlaceholders:@{@"Location1" : [NSNull null], @"Location2" : @"101"}];

    XCTAssertEqual(resolved.count, 0u);
    XCTAssertEqual(_loggedErrorCount, 2, @"errors: %@", _loggedErrors);
    XCTAssertTrue([_loggedErrors.firstObject hasPrefix:@"Cannot resolve placeholder"],
                  @"errors: %@", _loggedErrors);
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
    NSDictionary *resolved = [_rokt resolvePlaceholders:@{}];

    XCTAssertEqual(resolved.count, 0u);
    XCTAssertEqual(_loggedErrorCount, 0, @"errors: %@", _loggedErrors);
}

@end
