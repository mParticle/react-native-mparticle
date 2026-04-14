#ifdef RCT_NEW_ARCH_ENABLED
#import <SafariServices/SafariServices.h>
#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK_ObjC/MPRokt.h>)
    #import <mParticle_Apple_SDK_ObjC/MPRokt.h>
#else
    #import <mParticle_Apple_SDK/MPRokt.h>
#endif
#if __has_include(<RoktContracts/RoktContracts-Swift.h>)
    #import <RoktContracts/RoktContracts-Swift.h>
#elif __has_include(<RoktContracts/RoktContracts.h>)
    #import <RoktContracts/RoktContracts.h>
#endif

#ifndef RoktNativeLayoutComponentView_h
#define RoktNativeLayoutComponentView_h

NS_ASSUME_NONNULL_BEGIN

@interface RoktNativeLayoutComponentView : RCTViewComponentView
@property (nonatomic, readonly) RoktEmbeddedView *roktEmbeddedView;
@end

NS_ASSUME_NONNULL_END
#endif // RoktNativeLayoutComponentView_h
#endif // RCT_NEW_ARCH_ENABLED
