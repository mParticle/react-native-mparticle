#import "RNMPRokt.h"
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK/mParticle.h>)
    #import <mParticle_Apple_SDK/mParticle.h>
#elif defined(__has_include) && __has_include(<mParticle_Apple_SDK_NoLocation/mParticle.h>)
    #import <mParticle_Apple_SDK_NoLocation/mParticle.h>
#else
    #import "mParticle.h"
#endif
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK/mParticle_Apple_SDK-Swift.h>)
    #import <mParticle_Apple_SDK/mParticle_Apple_SDK-Swift.h>
#elif defined(__has_include) && __has_include(<mParticle_Apple_SDK_NoLocation/mParticle_Apple_SDK-Swift.h>)
    #import <mParticle_Apple_SDK_NoLocation/mParticle_Apple_SDK-Swift.h>
#else
    #import "mParticle_Apple_SDK-Swift.h"
#endif
#import <React/RCTConvert.h>

@implementation RNMPRokt

RCT_EXTERN void RCTRegisterModule(Class);

+ (NSString *)moduleName {
    return @"MPRokt";
}

+ (void)load {
    RCTRegisterModule(self);
}

RCT_EXPORT_METHOD(selectPlacements:(NSString *) identifer attributes:(NSDictionary *)attributes placeholders:(NSDictionary * _Nullable)placeholders roktConfig:(NSDictionary * _Nullable)roktConfig fontFilesMap:(NSDictionary * _Nullable)fontFilesMap)
{
    NSMutableDictionary *finalAttributes = [self convertToMutableDictionaryOfStrings:attributes];
    MPRoktConfig *config = [self buildRoktConfigFromDict:roktConfig];
    // TODO: Add placeholders and fontFilesMap
    [[[MParticle sharedInstance] rokt] selectPlacements:identifer attributes:finalAttributes];
}

- (NSMutableDictionary*)convertToMutableDictionaryOfStrings:(NSDictionary*)attributes
{
    NSMutableDictionary *finalAttributes = [attributes mutableCopy];
    NSArray *keysForNullValues = [finalAttributes allKeysForObject:[NSNull null]];
    [finalAttributes removeObjectsForKeys:keysForNullValues];
    
    NSSet *keys = [finalAttributes keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
        return ![obj isKindOfClass:[NSString class]];
    }];
    
    [finalAttributes removeObjectsForKeys:[keys allObjects]];
    return finalAttributes;
    
}

- (MPColorMode)stringToColorMode:(NSString*)colorString
{
    if ([colorString isEqualToString:@"light"]) {
        return MPColorModeLight;
    }
    else if ([colorString isEqualToString:@"dark"]) {
        return MPColorModeDark;
    }
    else {
        return MPColorModeSystem;
    }
}

- (MPRoktConfig *)buildRoktConfigFromDict:(NSDictionary<NSString *, id> *)configMap {
    MPRoktConfig *config = [[MPRoktConfig alloc] init];
    BOOL isConfigEmpty = YES;

    NSString *colorModeString = configMap[@"colorMode"];
    if (colorModeString && [colorModeString isKindOfClass:[NSString class]]) {
        if (@available(iOS 12.0, *)) {
            isConfigEmpty = NO;
            if ([colorModeString isEqualToString:@"dark"]) {
                if (@available(iOS 13.0, *)) {
                    config.colorMode = MPColorModeDark;
                }
            } else if ([colorModeString isEqualToString:@"light"]) {
                config.colorMode = MPColorModeLight;
            } else {
                // default: "system"
                config.colorMode = MPColorModeSystem;
            }
        }
    }

    NSDictionary *cacheConfigMap = configMap[@"cacheConfig"];
    if (cacheConfigMap && [cacheConfigMap isKindOfClass:[NSDictionary class]]) {
        isConfigEmpty = NO;
        NSNumber *cacheDuration = cacheConfigMap[@"cacheDurationInSeconds"];
        if (!cacheDuration) {
            cacheDuration = @0;
        }
        NSDictionary<NSString *, NSString *> *cacheAttributes = cacheConfigMap[@"cacheAttributes"];
        config.cacheAttributes = cacheAttributes;
        config.cacheDuration = cacheDuration;
    }

    return isConfigEmpty ? nil : config;
}

@end
