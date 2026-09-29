#import <XCTest/XCTest.h>
#import "../../../ios/RNMParticle/RNMPSDKImports.h"
#import "../../../ios/RNMParticle/RNMPRoktSwift.h"

/**
 * Pins how the `roktConfig` object from JavaScript becomes a RoktConfig, including which inputs
 * mean "no config" (nil). Written against the original Objective-C (`-[RNMPRokt
 * buildRoktConfigFromDict:]`), which RNMPRoktConfigFactory replaced unchanged.
 */
@interface RNMPRoktConfigFactoryTests : XCTestCase
@end

@implementation RNMPRoktConfigFactoryTests

- (RoktConfig *)configFrom:(NSDictionary *)dict
{
    return [RNMPRoktConfigFactory configFromDictionary:dict];
}

- (void)testNoUsableKeysMeansNoConfig
{
    XCTAssertNil([self configFrom:nil]);
    XCTAssertNil([self configFrom:@{}]);
    XCTAssertNil([self configFrom:@{@"unknown" : @"x"}]);
    XCTAssertNil([self configFrom:@{@"colorMode" : @1}]);
    XCTAssertNil([self configFrom:@{@"cacheConfig" : @"not a dictionary"}]);
}

- (void)testColorMode
{
    XCTAssertEqual([self configFrom:@{@"colorMode" : @"dark"}].colorMode, RoktColorModeDark);
    XCTAssertEqual([self configFrom:@{@"colorMode" : @"light"}].colorMode, RoktColorModeLight);
    XCTAssertEqual([self configFrom:@{@"colorMode" : @"system"}].colorMode, RoktColorModeSystem);
    XCTAssertEqual([self configFrom:@{@"colorMode" : @"sepia"}].colorMode, RoktColorModeSystem);
}

- (void)testCacheConfig
{
    RoktConfig *config = [self configFrom:@{@"cacheConfig" : @{@"cacheDurationInSeconds" : @120, @"cacheAttributes" : @{@"email" : @"a@b.c"}}}];
    XCTAssertEqual(config.cacheConfig.cacheDuration, 120);
    XCTAssertEqualObjects(config.cacheConfig.cacheAttributes, (@{@"email" : @"a@b.c"}));
}

- (void)testCacheConfigDefaultsAndTruncation
{
    RoktConfig *empty = [self configFrom:@{@"cacheConfig" : @{}}];
    XCTAssertNotNil(empty);
    // A missing duration is sent as 0, which the SDK raises to its maximum.
    XCTAssertEqual(empty.cacheConfig.cacheDuration, RoktCacheConfig.maxCacheDuration);
    XCTAssertEqualObjects(empty.cacheConfig.cacheAttributes, @{});

    // Whole seconds only: the duration was always read with longLongValue.
    XCTAssertEqual([self configFrom:@{@"cacheConfig" : @{@"cacheDurationInSeconds" : @90.7}}].cacheConfig.cacheDuration, 90);
}

- (void)testColorModeAndCacheTogether
{
    RoktConfig *config = [self configFrom:@{@"colorMode" : @"dark", @"cacheConfig" : @{@"cacheDurationInSeconds" : @60}}];
    XCTAssertEqual(config.colorMode, RoktColorModeDark);
    XCTAssertEqual(config.cacheConfig.cacheDuration, 60);
}

@end
