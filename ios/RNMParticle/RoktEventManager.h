#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <mParticle_Apple_SDK/MPRokt.h>

NS_ASSUME_NONNULL_BEGIN

@interface RoktEventManager : RCTEventEmitter <RCTBridgeModule>
+ (instancetype _Nonnull)allocWithZone:(NSZone * _Nullable)zone;
- (void)onWidgetHeightChanges:(CGFloat)widgetHeight placement:(NSString * _Nonnull)selectedPlacement;
- (void)onFirstPositiveResponse;
- (void)onRoktCallbackReceived:(NSString * _Nonnull)eventValue;
- (void)onRoktEvents:(MPRoktEvent * _Nonnull)event viewName:(NSString * _Nullable)viewName;

@end

NS_ASSUME_NONNULL_END
