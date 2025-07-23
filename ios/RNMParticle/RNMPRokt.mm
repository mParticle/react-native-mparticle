#import "RNMPRokt.h"
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK/mParticle.h>)
    #import <mParticle_Apple_SDK/mParticle.h>
    #import <mParticle_Apple_SDK/MPRokt.h>
#elif defined(__has_include) && __has_include(<mParticle_Apple_SDK_NoLocation/mParticle.h>)
    #import <mParticle_Apple_SDK_NoLocation/mParticle.h>
#else
    #import <mParticle_Apple_SDK/Include/mParticle.h>
#endif
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK/mParticle_Apple_SDK-Swift.h>)
    #import <mParticle_Apple_SDK/mParticle_Apple_SDK-Swift.h>
#elif defined(__has_include) && __has_include(<mParticle_Apple_SDK_NoLocation/mParticle_Apple_SDK-Swift.h>)
    #import <mParticle_Apple_SDK_NoLocation/mParticle_Apple_SDK-Swift.h>
#else
    #import "mParticle_Apple_SDK-Swift.h"
#endif
#import <React/RCTConvert.h>
#import <React/RCTEventEmitter.h>
#import <React/RCTViewManager.h>
#import <React/RCTUIManager.h>
#import <React/RCTBridge.h>
#import "RoktEventManager.h"

#ifdef RCT_NEW_ARCH_ENABLED
#import "RoktNativeLayoutComponentView.h"
#import <RNMParticle/RNMParticle.h>
#endif // RCT_NEW_ARCH_ENABLED

@interface RNMPRokt ()

@property (nonatomic, nullable) RoktEventManager *eventManager;

@end

@implementation RNMPRokt

@synthesize bridge = _bridge;

RCT_EXTERN void RCTRegisterModule(Class);

+ (NSString *)moduleName {
    return @"RNMPRokt";
}

+ (void)load {
    RCTRegisterModule(self);
}

- (dispatch_queue_t)methodQueue
{
    return self.bridge.uiManager.methodQueue;
}

- (void)setMethodQueue:(dispatch_queue_t)methodQueue
{
    // No-op setter to satisfy TurboModule requirements
    // We always return the UI manager's method queue
}

#ifdef RCT_NEW_ARCH_ENABLED
// New Architecture Implementation
- (void)selectPlacements:(NSString *)identifer
              attributes:(NSDictionary *)attributes
            placeholders:(NSDictionary *)placeholders
               roktConfig:(JS::NativeMPRokt::RoktConfigType &)roktConfig
            fontFilesMap:(NSDictionary *)fontFilesMap
{
    NSMutableDictionary *finalAttributes = [self convertToMutableDictionaryOfStrings:attributes];

    // Convert JS struct to NSDictionary for internal use
    NSMutableDictionary *roktConfigDict = [[NSMutableDictionary alloc] init];
    if (&roktConfig != nullptr && roktConfig.cacheConfig().has_value()) {
        NSMutableDictionary *cacheConfigDict = [[NSMutableDictionary alloc] init];
        auto cacheConfig = roktConfig.cacheConfig().value();
        if (cacheConfig.cacheDurationInSeconds().has_value()) {
            cacheConfigDict[@"cacheDurationInSeconds"] = @(cacheConfig.cacheDurationInSeconds().value());
        }
        if (cacheConfig.cacheAttributes()) {
            cacheConfigDict[@"cacheAttributes"] = cacheConfig.cacheAttributes();
        }
        roktConfigDict[@"cacheConfig"] = cacheConfigDict;
    }

    MPRoktConfig *config = [self buildRoktConfigFromDict:roktConfigDict];
#else
// Old Architecture Implementation
RCT_EXPORT_METHOD(selectPlacements:(NSString *) identifer attributes:(NSDictionary *)attributes placeholders:(NSDictionary * _Nullable)placeholders roktConfig:(NSDictionary * _Nullable)roktConfig fontFilesMap:(NSDictionary * _Nullable)fontFilesMap)
{
    NSMutableDictionary *finalAttributes = [self convertToMutableDictionaryOfStrings:attributes];
    MPRoktConfig *config = [self buildRoktConfigFromDict:roktConfig];
#endif

    // Create callback implementation
    MPRoktEventCallback *callbacks = [[MPRoktEventCallback alloc] init];

    __weak __typeof__(self) weakSelf = self;

    callbacks.onLoad = ^{
        [self.eventManager onRoktCallbackReceived:@"onLoad"];
    };

    callbacks.onUnLoad = ^{
        [self.eventManager onRoktCallbackReceived:@"onUnLoad"];
        RCTLogInfo(@"unloaded");
    };

    callbacks.onShouldShowLoadingIndicator = ^{
        [self.eventManager onRoktCallbackReceived:@"onShouldShowLoadingIndicator"];
    };

    callbacks.onShouldHideLoadingIndicator = ^{
        [self.eventManager onRoktCallbackReceived:@"onShouldHideLoadingIndicator"];
    };

    callbacks.onEmbeddedSizeChange = ^(NSString *placementId, CGFloat height) {
        [self.eventManager onWidgetHeightChanges:height placement:placementId];
    };

    [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,UIView *> *viewRegistry) {
        NSMutableDictionary *nativePlaceholders = [self getNativePlaceholders:placeholders viewRegistry:viewRegistry];

        [self subscribeViewEvents:identifer];

        [[[MParticle sharedInstance] rokt] selectPlacements:identifer
                                                 attributes:finalAttributes
                                              embeddedViews:nativePlaceholders
                                                     config:config
                                                  callbacks:callbacks];
    }];
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

- (void)subscribeViewEvents:(NSString* _Nonnull) viewName
{
    if (self.eventManager == nil) {
        self.eventManager = [RoktEventManager allocWithZone: nil];
    }
    [[[MParticle sharedInstance] rokt] events:viewName onEvent:^(MPRoktEvent * _Nonnull roktEvent) {
            [self.eventManager onRoktEvents:roktEvent viewName:viewName];
        }];
}

- (NSMutableDictionary *)getNativePlaceholders:(NSDictionary *)placeholders viewRegistry:(NSDictionary<NSNumber *, UIView *> *)viewRegistry
{
    NSMutableDictionary *nativePlaceholders = [[NSMutableDictionary alloc]initWithCapacity:placeholders.count];

    for(id key in placeholders){
#ifdef RCT_NEW_ARCH_ENABLED
        RoktNativeLayoutComponentView *wrapperView = (RoktNativeLayoutComponentView *)viewRegistry[[placeholders objectForKey:key]];
        if (!wrapperView || ![wrapperView isKindOfClass:[RoktNativeLayoutComponentView class]]) {
            RCTLogError(@"Cannot find RoktNativeWidgetComponentView with tag #%@", key);
            continue;
        }
        nativePlaceholders[key] = wrapperView.roktEmbeddedView;
#else
        MPRoktEmbeddedView *view = viewRegistry[[placeholders objectForKey:key]];
        if (!view || ![view isKindOfClass:[MPRoktEmbeddedView class]]) {
            RCTLogError(@"Cannot find RoktEmbeddedView with tag #%@", key);
            continue;
        }

        nativePlaceholders[key] = view;
#endif // RCT_NEW_ARCH_ENABLED
    }

    return nativePlaceholders;
}

#ifdef RCT_NEW_ARCH_ENABLED
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const facebook::react::ObjCTurboModule::InitParams &)params {
    self.bridge = params.instance.bridge;
    return std::make_shared<facebook::react::NativeMPRoktSpecJSI>(params);
}
#endif // RCT_NEW_ARCH_ENABLED

@end
