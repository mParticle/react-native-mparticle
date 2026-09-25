#import <Foundation/Foundation.h>
#import <React/RCTViewManager.h>
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK_ObjC/MPRokt.h>)
    #import <mParticle_Apple_SDK_ObjC/MPRokt.h>
#else
    #import <mParticle_Apple_SDK/MPRokt.h>
#endif
@import RoktContracts;
#import <React/RCTInvalidating.h>
#import "RoktPlaceholderRegistry.h"

// This manager is mounted only when Fabric is off (React Native 0.76-0.81 with the legacy
// architecture); builds with RCT_REMOVE_LEGACY_ARCH never create it. The legacy architecture has
// no per-view drop callback on iOS, but RCTUIManager calls -invalidate on each view it removes
// that conforms to RCTInvalidating. RoktEmbeddedView is a Swift class closed to subclassing, so the
// conformance is added as a category; the trade-off is that another -invalidate category on this
// class would collide silently. Without it a dropped view that something still retains stays
// registered and resolvable by name.
@interface RoktEmbeddedView (RNMPPlaceholderRegistration) <RCTInvalidating>
@end

@implementation RoktEmbeddedView (RNMPPlaceholderRegistration)

- (void)invalidate
{
  [RoktPlaceholderRegistry unregisterView:self];
}

@end

@interface RoktLayoutViewManager : RCTViewManager
@end

@implementation RoktLayoutViewManager

RCT_EXPORT_MODULE(RoktLegacyLayout)

// Register by placeholderName so selectPlacements can resolve this view by name. The entry is
// dropped by -invalidate when React Native removes the view, or when the view is deallocated.
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
