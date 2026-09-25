#import <Foundation/Foundation.h>
#import <React/RCTViewManager.h>
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK_ObjC/MPRokt.h>)
    #import <mParticle_Apple_SDK_ObjC/MPRokt.h>
#else
    #import <mParticle_Apple_SDK/MPRokt.h>
#endif
@import RoktContracts;
#import "RoktPlaceholderRegistry.h"

@interface RoktLayoutViewManager : RCTViewManager
@end

@implementation RoktLayoutViewManager

RCT_EXPORT_MODULE(RoktLegacyLayout)

// Register by placeholderName so selectPlacements can resolve this view by name. Weak refs drop
// the entry when the view is deallocated.
RCT_CUSTOM_VIEW_PROPERTY(placeholderName, NSString, RoktEmbeddedView)
{
  [RoktPlaceholderRegistry registerView:view name:json ? [RCTConvert NSString:json] : nil];
}

- (UIView *)view
{
  return [[RoktEmbeddedView alloc] init];
}

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

@end
