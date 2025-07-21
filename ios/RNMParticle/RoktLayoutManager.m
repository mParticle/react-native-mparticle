#import <Foundation/Foundation.h>
#import <React/RCTViewManager.h>
#import <mParticle_Apple_SDK/MPRokt.h>

@interface RoktLayoutViewManager : RCTViewManager
@end

@implementation RoktLayoutViewManager

RCT_EXPORT_MODULE(RoktLegacyLayout)

- (UIView *)view
{
  return [[MPRoktEmbeddedView alloc] init];
}

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

@end
