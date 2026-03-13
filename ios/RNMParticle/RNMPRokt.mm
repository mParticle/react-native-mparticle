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
    RCTLogWarn(@"[mParticle-Rokt] RNMPRokt module load");
    RCTRegisterModule(self);
}

- (dispatch_queue_t)methodQueue
{
    BOOL bridgeNil = (self.bridge == nil);
    BOOL uiManagerNil = (self.bridge.uiManager == nil);
    RCTLogWarn(@"[mParticle-Rokt] methodQueue called, bridge %@, uiManager %@", bridgeNil ? @"nil" : @"non-nil", uiManagerNil ? @"nil" : @"non-nil");
    return self.bridge.uiManager.methodQueue;
}

- (void)setMethodQueue:(dispatch_queue_t)methodQueue
{
    // No-op setter to satisfy TurboModule requirements
    // We always return the UI manager's method queue
}

#ifdef RCT_NEW_ARCH_ENABLED
// Extracts roktConfig fields into an NSDictionary, returning nil when the
// TurboModule bridge passes a null C++ reference for an omitted optional param.
// __attribute__((optnone)) is required: &ref != nullptr is UB in C++ and the
// compiler removes the check at -O2, causing a SIGSEGV in Release builds.
static NSDictionary * __attribute__((optnone)) safeExtractRoktConfigDict(
    JS::NativeMPRokt::RoktConfigType &roktConfig) {
    if (&roktConfig == nullptr) {
        RCTLogWarn(@"[mParticle-Rokt] safeExtractRoktConfigDict: roktConfig ref is nullptr, returning nil");
        return nil;
    }
    RCTLogWarn(@"[mParticle-Rokt] safeExtractRoktConfigDict: extracting config");
    NSMutableDictionary *roktConfigDict = [[NSMutableDictionary alloc] init];
    if (roktConfig.cacheConfig().has_value()) {
        NSMutableDictionary *cacheConfigDict = [[NSMutableDictionary alloc] init];
        auto cacheConfig = roktConfig.cacheConfig().value();
        if (cacheConfig.cacheDurationInSeconds().has_value()) {
            cacheConfigDict[@"cacheDurationInSeconds"] = @(cacheConfig.cacheDurationInSeconds().value());
        }
        if (cacheConfig.cacheAttributes()) {
            cacheConfigDict[@"cacheAttributes"] = cacheConfig.cacheAttributes();
        }
        roktConfigDict[@"cacheConfig"] = cacheConfigDict;
        RCTLogWarn(@"[mParticle-Rokt] safeExtractRoktConfigDict: cacheConfig present, keys: %lu", (unsigned long)roktConfigDict.count);
    } else {
        RCTLogWarn(@"[mParticle-Rokt] safeExtractRoktConfigDict: cacheConfig has no value");
    }
    RCTLogWarn(@"[mParticle-Rokt] safeExtractRoktConfigDict: returning dict with %lu keys", (unsigned long)roktConfigDict.count);
    return roktConfigDict;
}

// New Architecture Implementation
- (void)selectPlacements:(NSString *)identifer
              attributes:(NSDictionary *)attributes
            placeholders:(NSDictionary *)placeholders
               roktConfig:(JS::NativeMPRokt::RoktConfigType &)roktConfig
            fontFilesMap:(NSDictionary *)fontFilesMap
{
    RCTLogWarn(@"[mParticle-Rokt] New Architecture Implementation");
    NSMutableDictionary *finalAttributes = [self convertToMutableDictionaryOfStrings:attributes];

    NSDictionary *roktConfigDict = safeExtractRoktConfigDict(roktConfig);
    MPRoktConfig *config = [self buildRoktConfigFromDict:roktConfigDict];
#else
// Old Architecture Implementation
RCT_EXPORT_METHOD(selectPlacements:(NSString *) identifer attributes:(NSDictionary *)attributes placeholders:(NSDictionary * _Nullable)placeholders roktConfig:(NSDictionary * _Nullable)roktConfig fontFilesMap:(NSDictionary * _Nullable)fontFilesMap)
{
    RCTLogWarn(@"[mParticle-Rokt] Old Architecture Implementation");
    NSMutableDictionary *finalAttributes = [self convertToMutableDictionaryOfStrings:attributes];
    MPRoktConfig *config = [self buildRoktConfigFromDict:roktConfig];
#endif

    RCTLogWarn(@"[mParticle-Rokt] selectPlacements called with identifier: %@, attributes count: %lu", identifer, (unsigned long)finalAttributes.count);

    [MParticle _setWrapperSdk_internal:MPWrapperSdkReactNative version:@""];
    // Create callback implementation
    MPRoktEventCallback *callbacks = [[MPRoktEventCallback alloc] init];
    __weak __typeof__(self) weakSelf = self;

    callbacks.onLoad = ^{
        RCTLogWarn(@"[mParticle-Rokt] onLoad");
        [weakSelf.eventManager onRoktCallbackReceived:@"onLoad"];
    };

    callbacks.onUnLoad = ^{
        RCTLogWarn(@"[mParticle-Rokt] onUnLoad");
        [weakSelf.eventManager onRoktCallbackReceived:@"onUnLoad"];
    };

    callbacks.onShouldShowLoadingIndicator = ^{
        RCTLogWarn(@"[mParticle-Rokt] onShouldShowLoadingIndicator");
        [weakSelf.eventManager onRoktCallbackReceived:@"onShouldShowLoadingIndicator"];
    };

    callbacks.onShouldHideLoadingIndicator = ^{
        RCTLogWarn(@"[mParticle-Rokt] onShouldHideLoadingIndicator");
        [weakSelf.eventManager onRoktCallbackReceived:@"onShouldHideLoadingIndicator"];
    };

    callbacks.onEmbeddedSizeChange = ^(NSString *placementId, CGFloat height) {
        RCTLogWarn(@"[mParticle-Rokt] onEmbeddedSizeChange");
        [weakSelf.eventManager onWidgetHeightChanges:height placement:placementId];
    };

    BOOL bridgeNil = (self.bridge == nil);
    BOOL uiManagerNil = (self.bridge.uiManager == nil);
    RCTLogWarn(@"[mParticle-Rokt] bridge %@, uiManager %@", bridgeNil ? @"nil" : @"non-nil", uiManagerNil ? @"nil" : @"non-nil");

    if (bridgeNil || uiManagerNil) {
        RCTLogWarn(@"[mParticle-Rokt] addUIBlock skipped: self.bridge%@ is nil. selectPlacements will not be called. This can occur in New Architecture bridgeless production builds.", bridgeNil ? @"" : @".uiManager");
    } else {
        RCTLogWarn(@"[mParticle-Rokt] queuing addUIBlock for identifier: %@", identifer);
    }
    [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,UIView *> *viewRegistry) {
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        RCTLogWarn(@"[mParticle-Rokt] addUIBlock executing for identifier: %@, viewRegistry count: %lu", identifer, (unsigned long)viewRegistry.count);

        NSMutableDictionary *nativePlaceholders = strongSelf ? [strongSelf getNativePlaceholders:placeholders viewRegistry:viewRegistry] : [NSMutableDictionary dictionary];

        if (strongSelf) {
            [strongSelf subscribeViewEvents:identifer];
        }

        RCTLogWarn(@"[mParticle-Rokt] calling mParticle Core selectPlacements for: %@", identifer);
        [[[MParticle sharedInstance] rokt] selectPlacements:identifer
                                                 attributes:finalAttributes
                                              embeddedViews:nativePlaceholders
                                                     config:config
                                                  callbacks:callbacks];
    }];
    RCTLogWarn(@"[mParticle-Rokt] addUIBlock enqueued for identifier: %@", identifer);
}

RCT_EXPORT_METHOD(purchaseFinalized : (NSString *)placementId catalogItemId : (
    NSString *)catalogItemId success : (BOOL)success) {
    [[[MParticle sharedInstance] rokt] purchaseFinalized:placementId
                                           catalogItemId:catalogItemId
                                                 success:success];
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
    RCTLogWarn(@"[mParticle-Rokt] buildRoktConfigFromDict: configMap %@", configMap == nil ? @"nil" : [NSString stringWithFormat:@"non-nil (%lu keys)", (unsigned long)configMap.count]);
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

    RCTLogWarn(@"[mParticle-Rokt] buildRoktConfigFromDict: returning %@", isConfigEmpty ? @"nil" : @"config");
    return isConfigEmpty ? nil : config;
}

- (void)subscribeViewEvents:(NSString* _Nonnull) viewName
{
    RCTLogWarn(@"[mParticle-Rokt] subscribeViewEvents for viewName: %@", viewName);
    if (self.eventManager == nil) {
        self.eventManager = [RoktEventManager allocWithZone: nil];
    }
    [[[MParticle sharedInstance] rokt] events:viewName onEvent:^(MPRoktEvent * _Nonnull roktEvent) {
            [self.eventManager onRoktEvents:roktEvent viewName:viewName];
        }];
}

- (NSMutableDictionary *)getNativePlaceholders:(NSDictionary *)placeholders viewRegistry:(NSDictionary<NSNumber *, UIView *> *)viewRegistry
{
    RCTLogWarn(@"[mParticle-Rokt] getNativePlaceholders: placeholders %lu, viewRegistry %lu", (unsigned long)placeholders.count, (unsigned long)viewRegistry.count);
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

    RCTLogWarn(@"[mParticle-Rokt] getNativePlaceholders: resolved %lu native placeholder(s)", (unsigned long)nativePlaceholders.count);
    return nativePlaceholders;
}

#ifdef RCT_NEW_ARCH_ENABLED
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const facebook::react::ObjCTurboModule::InitParams &)params {
    self.bridge = params.instance.bridge;
    RCTLogWarn(@"[mParticle-Rokt] getTurboModule: bridge set to %@", self.bridge == nil ? @"nil" : @"non-nil");
    return std::make_shared<facebook::react::NativeMPRoktSpecJSI>(params);
}
#endif // RCT_NEW_ARCH_ENABLED

@end
