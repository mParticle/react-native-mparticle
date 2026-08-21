#import "RNMPRokt.h"
// SDK 9.0: ObjC headers moved to mParticle_Apple_SDK_ObjC module
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK_ObjC/mParticle.h>)
    #import <mParticle_Apple_SDK_ObjC/mParticle.h>
    #import <mParticle_Apple_SDK_ObjC/MPRokt.h>
#elif defined(__has_include) && __has_include(<mParticle_Apple_SDK/mParticle.h>)
    #import <mParticle_Apple_SDK/mParticle.h>
    #import <mParticle_Apple_SDK/MPRokt.h>
#else
    #import <mParticle_Apple_SDK_ObjC/mParticle.h>
    #import <mParticle_Apple_SDK_ObjC/MPRokt.h>
#endif
#if __has_include(<RoktContracts/RoktContracts-Swift.h>)
    #import <RoktContracts/RoktContracts-Swift.h>
#elif __has_include(<RoktContracts/RoktContracts.h>)
    #import <RoktContracts/RoktContracts.h>
#endif
#import <React/RCTConvert.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <React/RCTViewManager.h>
#import <React/RCTLog.h>
#import <React/RCTUtils.h>
#import <os/log.h>
#import "RoktEventManager.h"

#ifdef RCT_NEW_ARCH_ENABLED
#import "RoktNativeLayoutComponentView.h"
#import <RNMParticle/RNMParticle.h>
#endif // RCT_NEW_ARCH_ENABLED

// os_log for [mParticle-Rokt] diagnostics: visible in production (Console.app, device logs)
// and does not trigger RCT LogBox/warning UI in debug.
static os_log_t _rokt_os_log(void) {
  static os_log_t log;
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    log = os_log_create("com.mparticle.react-native", "rokt");
  });
  return log;
}

static void _rokt_log(NSString *format, ...) {
  va_list args;
  va_start(args, format);
  NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];
  va_end(args);
  os_log_with_type(_rokt_os_log(), OS_LOG_TYPE_INFO, "%{public}s", [msg UTF8String]);
}

@interface RNMPRokt ()

@property (nonatomic, nullable) RoktEventManager *eventManager;

@end

@implementation RNMPRokt

// Maps React tags to UIViews in both bridge and bridgeless modes, unlike bridge.uiManager.
@synthesize viewRegistry_DEPRECATED = _viewRegistry_DEPRECATED;

RCT_EXTERN void RCTRegisterModule(Class);

+ (NSString *)moduleName {
    return @"RNMPRokt";
}

+ (void)load {
    _rokt_log(@"[mParticle-Rokt] RNMPRokt module load");
    RCTRegisterModule(self);
}

- (dispatch_queue_t)methodQueue
{
    // selectPlacements mutates the placeholder view hierarchy, so SDK calls must run on
    // the main thread. Matches Android's UiThreadUtil.runOnUiThread (MPRoktModule.kt).
    return dispatch_get_main_queue();
}

- (void)setMethodQueue:(dispatch_queue_t)methodQueue
{
    // No-op setter to satisfy TurboModule requirements
    // We always return the UI manager's method queue
}

- (void)ensureEventManager {
    if (self.eventManager == nil) {
        self.eventManager = [RoktEventManager allocWithZone: nil];
    }
}

#ifdef RCT_NEW_ARCH_ENABLED
// Extracts roktConfig fields into an NSDictionary, returning nil when the
// TurboModule bridge passes a null C++ reference for an omitted optional param.
// __attribute__((optnone)) is required: &ref != nullptr is UB in C++ and the
// compiler removes the check at -O2, causing a SIGSEGV in Release builds.
static NSDictionary * __attribute__((optnone)) safeExtractRoktConfigDict(
    JS::NativeMPRokt::RoktConfigType &roktConfig) {
    if (&roktConfig == nullptr) {
        _rokt_log(@"[mParticle-Rokt] safeExtractRoktConfigDict: roktConfig ref is nullptr, returning nil");
        return nil;
    }
    _rokt_log(@"[mParticle-Rokt] safeExtractRoktConfigDict: extracting config");
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
        _rokt_log(@"[mParticle-Rokt] safeExtractRoktConfigDict: cacheConfig present, keys: %lu", (unsigned long)roktConfigDict.count);
    } else {
        _rokt_log(@"[mParticle-Rokt] safeExtractRoktConfigDict: cacheConfig has no value");
    }
    _rokt_log(@"[mParticle-Rokt] safeExtractRoktConfigDict: returning dict with %lu keys", (unsigned long)roktConfigDict.count);
    return roktConfigDict;
}

// New Architecture Implementation — selectPlacements
- (void)selectPlacements:(NSString *)identifer
              attributes:(NSDictionary *)attributes
            placeholders:(NSDictionary *)placeholders
               roktConfig:(JS::NativeMPRokt::RoktConfigType &)roktConfig
            fontFilesMap:(NSDictionary *)fontFilesMap
{
    _rokt_log(@"[mParticle-Rokt] New Architecture Implementation");
    NSMutableDictionary *finalAttributes = [self convertToMutableDictionaryOfStrings:attributes];

    NSDictionary *roktConfigDict = safeExtractRoktConfigDict(roktConfig);
    RoktConfig *config = [self buildRoktConfigFromDict:roktConfigDict];
#else
// Old Architecture Implementation — selectPlacements
RCT_EXPORT_METHOD(selectPlacements:(NSString *) identifer attributes:(NSDictionary *)attributes placeholders:(NSDictionary * _Nullable)placeholders roktConfig:(NSDictionary * _Nullable)roktConfig fontFilesMap:(NSDictionary * _Nullable)fontFilesMap)
{
    _rokt_log(@"[mParticle-Rokt] Old Architecture Implementation");
    NSMutableDictionary *finalAttributes = [self convertToMutableDictionaryOfStrings:attributes];
    RoktConfig *config = [self buildRoktConfigFromDict:roktConfig];
#endif

    _rokt_log(@"[mParticle-Rokt] selectPlacements called with identifier: %@, attributes count: %lu", identifer, (unsigned long)finalAttributes.count);

    [MParticle _setWrapperSdk_internal:MPWrapperSdkReactNative version:@""];
    [self ensureEventManager];
    __weak __typeof__(self) weakSelf = self;

    // Replaces [self.bridge.uiManager addUIBlock:], which silently drops the call (no
    // event emitted) when RCT_REMOVE_LEGACY_ARCH is set, React Native 0.84's default.
    RCTExecuteOnMainQueue(^{
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        NSMutableDictionary *nativePlaceholders = strongSelf ? [strongSelf resolvePlaceholders:placeholders] : [NSMutableDictionary dictionary];

        id mpInstance = [MParticle sharedInstance];
        id roktKit = mpInstance ? [mpInstance rokt] : nil;
        _rokt_log(@"[mParticle-Rokt] MParticle sharedInstance %@, rokt kit %@", mpInstance ? @"non-nil" : @"nil", roktKit ? @"non-nil" : @"nil");
        _rokt_log(@"[mParticle-Rokt] calling mParticle Core selectPlacements for: %@", identifer);
        [[[MParticle sharedInstance] rokt] selectPlacements:identifer
                                                 attributes:finalAttributes
                                              embeddedViews:nativePlaceholders
                                                     config:config
                                                    onEvent:^(RoktEvent * _Nonnull event) {
            [weakSelf.eventManager onRoktEvents:event viewName:identifer];
        }];
    });
}

#ifdef RCT_NEW_ARCH_ENABLED
// New Architecture Implementation — selectShoppableAds
- (void)selectShoppableAds:(NSString *)identifier
                attributes:(NSDictionary *)attributes
                roktConfig:(JS::NativeMPRokt::RoktConfigType &)roktConfig
{
    _rokt_log(@"[mParticle-Rokt] selectShoppableAds New Architecture");
    NSMutableDictionary *finalAttributes = [self convertToMutableDictionaryOfStrings:attributes];
    NSDictionary *roktConfigDict = safeExtractRoktConfigDict(roktConfig);
    RoktConfig *config = [self buildRoktConfigFromDict:roktConfigDict];
#else
// Old Architecture Implementation — selectShoppableAds
RCT_EXPORT_METHOD(selectShoppableAds:(NSString *)identifier attributes:(NSDictionary *)attributes roktConfig:(NSDictionary * _Nullable)roktConfig)
{
    _rokt_log(@"[mParticle-Rokt] selectShoppableAds Old Architecture");
    NSMutableDictionary *finalAttributes = [self convertToMutableDictionaryOfStrings:attributes];
    RoktConfig *config = [self buildRoktConfigFromDict:roktConfig];
#endif

    _rokt_log(@"[mParticle-Rokt] selectShoppableAds called with identifier: %@, attributes count: %lu", identifier, (unsigned long)finalAttributes.count);

    [MParticle _setWrapperSdk_internal:MPWrapperSdkReactNative version:@""];
    [self ensureEventManager];
    __weak __typeof__(self) weakSelf = self;

    [[[MParticle sharedInstance] rokt] selectShoppableAds:identifier
                                              attributes:finalAttributes
                                                  config:config
                                                 onEvent:^(RoktEvent * _Nonnull event) {
        [weakSelf.eventManager onRoktEvents:event viewName:identifier];
    }];
}

#ifdef RCT_NEW_ARCH_ENABLED
- (void)close:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject
{
    (void)reject;
    [self closeWithResolve:resolve];
}

- (void)setSessionId:(NSString *)sessionId resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject
{
    (void)reject;
    [self setSessionIdWithString:sessionId resolve:resolve];
}

- (void)getSessionId:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject
{
    (void)reject;
    [self getSessionIdWithResolve:resolve];
}
#else
RCT_EXPORT_METHOD(close:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    (void)reject;
    [self closeWithResolve:resolve];
}

RCT_EXPORT_METHOD(setSessionId:(NSString *)sessionId resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    (void)reject;
    [self setSessionIdWithString:sessionId resolve:resolve];
}

RCT_EXPORT_METHOD(getSessionId:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    (void)reject;
    [self getSessionIdWithResolve:resolve];
}
#endif

- (void)closeWithResolve:(RCTPromiseResolveBlock)resolve
{
    [[[MParticle sharedInstance] rokt] close];
    resolve(nil);
}

- (void)setSessionIdWithString:(NSString *)sessionId
                       resolve:(RCTPromiseResolveBlock)resolve
{
    [[[MParticle sharedInstance] rokt] setSessionId:sessionId ?: @""];
    resolve(nil);
}

- (void)getSessionIdWithResolve:(RCTPromiseResolveBlock)resolve
{
    NSString *sessionId = [[[MParticle sharedInstance] rokt] getSessionId];
    resolve(sessionId ?: [NSNull null]);
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

- (RoktConfig *)buildRoktConfigFromDict:(NSDictionary<NSString *, id> *)configMap {
    _rokt_log(@"[mParticle-Rokt] buildRoktConfigFromDict: configMap %@", configMap == nil ? @"nil" : [NSString stringWithFormat:@"non-nil (%lu keys)", (unsigned long)configMap.count]);
    if (configMap == nil || configMap.count == 0) {
        _rokt_log(@"[mParticle-Rokt] buildRoktConfigFromDict: returning nil");
        return nil;
    }

    RoktConfigBuilder *builder = [[RoktConfigBuilder alloc] init];
    BOOL isConfigEmpty = YES;

    NSString *colorModeString = configMap[@"colorMode"];
    if (colorModeString && [colorModeString isKindOfClass:[NSString class]]) {
        isConfigEmpty = NO;
        if ([colorModeString isEqualToString:@"dark"]) {
            [builder colorMode:RoktColorModeDark];
        } else if ([colorModeString isEqualToString:@"light"]) {
            [builder colorMode:RoktColorModeLight];
        } else {
            [builder colorMode:RoktColorModeSystem];
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
        RoktCacheConfig *cacheConfig = [[RoktCacheConfig alloc] initWithCacheDuration:[cacheDuration longLongValue]
                                                                      cacheAttributes:cacheAttributes ?: @{}];
        [builder cacheConfig:cacheConfig];
    }

    _rokt_log(@"[mParticle-Rokt] buildRoktConfigFromDict: returning %@", isConfigEmpty ? @"nil" : @"config");
    return isConfigEmpty ? nil : [builder build];
}

// Main thread only — RCTViewRegistry reads the mounted view hierarchy.
- (NSMutableDictionary *)resolvePlaceholders:(NSDictionary *)placeholders
{
    _rokt_log(@"[mParticle-Rokt] resolvePlaceholders: %lu placeholder(s)", (unsigned long)placeholders.count);
    NSMutableDictionary *nativePlaceholders = [[NSMutableDictionary alloc]initWithCapacity:placeholders.count];

    for(id key in placeholders){
        // The spec allows `number | null`; viewForReactTag: would throw on NSNull.
        NSNumber *reactTag = [placeholders objectForKey:key];
        if (![reactTag isKindOfClass:[NSNumber class]]) {
            RCTLogError(@"Invalid react tag for placeholder %@", key);
            continue;
        }

        // nil fails isKindOfClass:, covering both "not mounted" and "wrong class".
        UIView *view = [_viewRegistry_DEPRECATED viewForReactTag:reactTag];
#ifdef RCT_NEW_ARCH_ENABLED
        if (![view isKindOfClass:[RoktNativeLayoutComponentView class]]) {
            RCTLogError(@"Cannot find RoktNativeLayoutComponentView for placeholder %@ (reactTag %@)", key, reactTag);
            continue;
        }
        nativePlaceholders[key] = ((RoktNativeLayoutComponentView *)view).roktEmbeddedView;
#else
        if (![view isKindOfClass:[RoktEmbeddedView class]]) {
            RCTLogError(@"Cannot find RoktEmbeddedView with tag #%@", key);
            continue;
        }

        nativePlaceholders[key] = view;
#endif // RCT_NEW_ARCH_ENABLED
    }

    _rokt_log(@"[mParticle-Rokt] resolvePlaceholders: resolved %lu native placeholder(s)", (unsigned long)nativePlaceholders.count);
    return nativePlaceholders;
}

#ifdef RCT_NEW_ARCH_ENABLED
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const facebook::react::ObjCTurboModule::InitParams &)params {
    return std::make_shared<facebook::react::NativeMPRoktSpecJSI>(params);
}
#endif // RCT_NEW_ARCH_ENABLED

@end
