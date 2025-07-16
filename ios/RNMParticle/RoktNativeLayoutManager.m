#import <Foundation/Foundation.h>
#import <React/RCTViewManager.h>
#import <mParticle_Apple_SDK/MPRokt.h>

@interface RoktNativeLayoutManager : RCTViewManager
@end

@implementation RoktNativeLayoutManager

RCT_EXPORT_MODULE(RoktNativeLayout)

- (UIView *)view
{
  return [[MPRoktEmbeddedView alloc] init];
}

@end
