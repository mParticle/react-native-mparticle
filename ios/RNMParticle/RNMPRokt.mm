#import "RNMPRokt.h"
#import "RNMPSDKImports.h"
#import "RNMPRoktSwift.h"
#import <React/RCTConvert.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <React/RCTViewManager.h>
#import <React/RCTLog.h>
#import <React/RCTUtils.h>
#import <os/log.h>
#import "RoktEventManager.h"
#import "RoktPlaceholderRegistry.h"

#ifdef RCT_NEW_ARCH_ENABLED
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

// How long selectPlacements waits for a named placeholder to mount before proceeding without it.
static const NSTimeInterval kRoktPlaceholderMountTimeout = 2.0;

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
// Extracts roktConfig fields into an NSDictionary. An omitted optional object param arrives
// as a null C++ reference, which can't be checked here (the check is UB and is compiled out),
// so the JS wrapper always sends a config, `{}` when omitted (toNativeRoktConfig in rokt.ts).
static NSDictionary *safeExtractRoktConfigDict(
    JS::NativeMPRokt::RoktConfigType &roktConfig) {
    _rokt_log(@"[mParticle-Rokt] safeExtractRoktConfigDict: extracting config");
    NSMutableDictionary *roktConfigDict = [[NSMutableDictionary alloc] init];
    if (roktConfig.colorMode() != nil) {
        roktConfigDict[@"colorMode"] = roktConfig.colorMode();
        _rokt_log(@"[mParticle-Rokt] safeExtractRoktConfigDict: colorMode present");
    }
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
            placeholders:(NSArray *)placeholders
               roktConfig:(JS::NativeMPRokt::RoktConfigType &)roktConfig
            fontFilesMap:(NSDictionary *)fontFilesMap
{
    _rokt_log(@"[mParticle-Rokt] New Architecture Implementation");
    NSMutableDictionary *finalAttributes = [self convertToMutableDictionaryOfStrings:attributes];

    NSDictionary *roktConfigDict = safeExtractRoktConfigDict(roktConfig);
    RoktConfig *config = [RNMPRoktConfigFactory configFromDictionary:roktConfigDict];
#else
// Old Architecture Implementation — selectPlacements
RCT_EXPORT_METHOD(selectPlacements:(NSString *) identifer attributes:(NSDictionary *)attributes placeholders:(NSArray * _Nullable)placeholders roktConfig:(NSDictionary * _Nullable)roktConfig fontFilesMap:(NSDictionary * _Nullable)fontFilesMap)
{
    _rokt_log(@"[mParticle-Rokt] Old Architecture Implementation");
    NSMutableDictionary *finalAttributes = [self convertToMutableDictionaryOfStrings:attributes];
    RoktConfig *config = [RNMPRoktConfigFactory configFromDictionary:roktConfig];
#endif

    _rokt_log(@"[mParticle-Rokt] selectPlacements called with identifier: %@, attributes count: %lu", identifer, (unsigned long)finalAttributes.count);

    [MParticle _setWrapperSdk_internal:MPWrapperSdkReactNative version:@""];
    [self ensureEventManager];
    __weak __typeof__(self) weakSelf = self;

    // Replaces [self.bridge.uiManager addUIBlock:], which silently drops the call (no
    // event emitted) when RCT_REMOVE_LEGACY_ARCH is set, React Native 0.84's default.
    RCTExecuteOnMainQueue(^{
        dispatch_block_t select = ^{
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
        };

        // A placeholder named by the app may not be mounted yet (e.g. selectPlacements from the
        // same useEffect that rendered it), so wait for it briefly rather than dropping it.
        NSArray<NSString *> *pending = [RNMPRokt unmountedPlaceholderNames:placeholders];
        if (pending.count == 0) {
            select();
            return;
        }
        _rokt_log(@"[mParticle-Rokt] waiting up to %.0fs for placeholder(s) to mount: %@", kRoktPlaceholderMountTimeout, pending);
        [RoktPlaceholderRegistry waitForNames:pending
                                          key:identifer
                                      timeout:kRoktPlaceholderMountTimeout
                                   completion:select
                                    discarded:^{
            // Replaced by a newer call with the same identifier, or cancelled by close(): the SDK
            // is never called, so report the failure the way the SDK reports a call it rejects.
            _rokt_log(@"[mParticle-Rokt] pending selectPlacements dropped for: %@", identifer);
            [weakSelf.eventManager onRoktEvents:[RNMPRoktEventMapper placementFailure] viewName:identifer];
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
    RoktConfig *config = [RNMPRoktConfigFactory configFromDictionary:roktConfigDict];
#else
// Old Architecture Implementation — selectShoppableAds
RCT_EXPORT_METHOD(selectShoppableAds:(NSString *)identifier attributes:(NSDictionary *)attributes roktConfig:(NSDictionary * _Nullable)roktConfig)
{
    _rokt_log(@"[mParticle-Rokt] selectShoppableAds Old Architecture");
    NSMutableDictionary *finalAttributes = [self convertToMutableDictionaryOfStrings:attributes];
    RoktConfig *config = [RNMPRoktConfigFactory configFromDictionary:roktConfig];
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
    // methodQueue is the main queue, so this runs inline; kept as one block so pending waits are
    // always cancelled before close even if that changes. Matches Android's MPRoktModuleImpl.close.
    RCTExecuteOnMainQueue(^{
        [RoktPlaceholderRegistry cancelAllWaits];
        [[[MParticle sharedInstance] rokt] close];
        resolve(nil);
    });
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

// Coerces React Native attribute values to strings, matching mParticle-Rokt kit
// transformValuesToString behavior (MPKitRokt.m).
- (NSMutableDictionary<NSString *, NSString *> *)convertToMutableDictionaryOfStrings:(NSDictionary *)attributes
{
    NSMutableDictionary<NSString *, NSString *> *finalAttributes = [[NSMutableDictionary alloc] init];
    if (!attributes) {
        return finalAttributes;
    }

    [attributes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (![key isKindOfClass:[NSString class]] || obj == nil || obj == [NSNull null]) {
            return;
        }

        NSString *stringKey = (NSString *)key;
        if ([obj isKindOfClass:[NSString class]]) {
            finalAttributes[stringKey] = obj;
        } else if ([obj isKindOfClass:[NSNumber class]]) {
            NSNumber *numberAttribute = (NSNumber *)obj;
            if (numberAttribute == (id)kCFBooleanTrue || numberAttribute == (id)kCFBooleanFalse) {
                finalAttributes[stringKey] = [numberAttribute boolValue] ? @"true" : @"false";
            } else {
                finalAttributes[stringKey] = [numberAttribute stringValue];
            }
        } else if ([obj isKindOfClass:[NSDictionary class]] || [obj isKindOfClass:[NSArray class]]) {
            finalAttributes[stringKey] = [obj description];
        }
    }];

    return finalAttributes;
}

// Main thread only — RoktPlaceholderRegistry reads the mounted view hierarchy.
- (NSMutableDictionary *)resolvePlaceholders:(NSArray *)placeholders
{
    _rokt_log(@"[mParticle-Rokt] resolvePlaceholders: %lu placeholder(s)", (unsigned long)placeholders.count);
    NSMutableDictionary *nativePlaceholders = [[NSMutableDictionary alloc]initWithCapacity:placeholders.count];

    for (id name in placeholders) {
        if (![name isKindOfClass:[NSString class]]) {
            RCTLogError(@"Cannot resolve placeholder %@: expected a placeholderName string", name);
            continue;
        }
        UIView *view = [RoktPlaceholderRegistry viewForName:name];
        // nil is not an embedded view, covering both "not mounted" and "wrong class".
        if (![RNMPRoktViews isEmbeddedView:view]) {
            RCTLogError(@"Cannot resolve placeholder %@", name);
            continue;
        }
        nativePlaceholders[name] = view;
    }

    _rokt_log(@"[mParticle-Rokt] resolvePlaceholders: resolved %lu native placeholder(s)", (unsigned long)nativePlaceholders.count);
    return nativePlaceholders;
}

// Placeholder names that have no mounted view yet.
+ (NSArray<NSString *> *)unmountedPlaceholderNames:(NSArray *)placeholders
{
    NSMutableArray<NSString *> *pending = [NSMutableArray array];
    for (id name in placeholders) {
        if ([name isKindOfClass:[NSString class]] && [RoktPlaceholderRegistry viewForName:name] == nil) {
            [pending addObject:name];
        }
    }
    return pending;
}

#ifdef RCT_NEW_ARCH_ENABLED
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const facebook::react::ObjCTurboModule::InitParams &)params {
    return std::make_shared<facebook::react::NativeMPRoktSpecJSI>(params);
}
#endif // RCT_NEW_ARCH_ENABLED

@end
