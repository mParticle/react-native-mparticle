#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

#ifdef RCT_NEW_ARCH_ENABLED
#import <RNMParticle/RNMParticle.h>
#endif // RCT_NEW_ARCH_ENABLED

@class RoktEvent;

NS_ASSUME_NONNULL_BEGIN

// Conforms to the codegen'd spec under the New Architecture so the emitter is
// registered as a TurboModule. Without it this class is a plain RCTBridgeModule,
// which bridgeless only instantiates when the host app enables TurboModule interop
// -- otherwise NativeModules.RoktEventManager is undefined and every Rokt event is
// dropped before reaching JS.
#ifdef RCT_NEW_ARCH_ENABLED
@interface RoktEventManager : RCTEventEmitter <RCTBridgeModule, NativeRoktEventManagerSpec>
#else
@interface RoktEventManager : RCTEventEmitter <RCTBridgeModule>
#endif // RCT_NEW_ARCH_ENABLED

+ (instancetype _Nonnull)allocWithZone:(NSZone * _Nullable)zone;
- (void)onWidgetHeightChanges:(CGFloat)widgetHeight placement:(NSString * _Nonnull)selectedPlacement;
- (void)onFirstPositiveResponse;
- (void)onRoktCallbackReceived:(NSString * _Nonnull)eventValue;
- (void)onRoktEvents:(RoktEvent * _Nonnull)event viewName:(NSString * _Nullable)viewName;

@end

NS_ASSUME_NONNULL_END
