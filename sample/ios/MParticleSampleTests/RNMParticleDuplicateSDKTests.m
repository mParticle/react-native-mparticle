#import <XCTest/XCTest.h>
#import "../../../ios/RNMParticle/RNMParticle.h"

// Implemented in RNMParticle.mm, Debug builds only.
@interface RNMParticle (DuplicateSDKTests)
+ (NSDictionary<NSString *, NSNumber *> *)imageCountsForClassNames:(NSArray<NSString *> *)classNames;
@end

/**
 * Guards the Debug-only check that warns when two copies of the mParticle SDK are loaded.
 *
 * Only `MParticle` is asserted: it lives in the SDK framework, which this test bundle shares
 * with the app it hosts. The wrapper's own classes are linked into this bundle a second time
 * (see RNMPRoktPlaceholderTests.m), so counting them would test the test linkage.
 */
@interface RNMParticleDuplicateSDKTests : XCTestCase
@end

@implementation RNMParticleDuplicateSDKTests

- (void)testCountsOneCopyOfTheSDK
{
    NSDictionary<NSString *, NSNumber *> *counts = [RNMParticle imageCountsForClassNames:@[ @"MParticle" ]];

    XCTAssertEqualObjects(counts[@"MParticle"], @1);
}

- (void)testCountsZeroForAClassNoImageDefines
{
    NSDictionary<NSString *, NSNumber *> *counts = [RNMParticle imageCountsForClassNames:@[ @"RNMPNoSuchClass" ]];

    XCTAssertEqualObjects(counts[@"RNMPNoSuchClass"], @0);
}

@end
