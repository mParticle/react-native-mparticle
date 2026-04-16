#import <Foundation/Foundation.h>
#import <React/RCTViewManager.h>
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK_ObjC/MPRokt.h>)
    #import <mParticle_Apple_SDK_ObjC/MPRokt.h>
#else
    #import <mParticle_Apple_SDK/MPRokt.h>
#endif
@import RoktContracts;

@interface RoktLayoutViewManager : RCTViewManager
@end

@implementation RoktLayoutViewManager

RCT_EXPORT_MODULE(RoktLegacyLayout)

- (UIView *)view
{
  return [[RoktEmbeddedView alloc] init];
}

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

@end
