#ifdef RCT_NEW_ARCH_ENABLED
#import <SafariServices/SafariServices.h>
#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>
#import <mParticle_Apple_SDK/MPRokt.h>

#ifndef RoktNativeLayoutComponentView_h
#define RoktNativeLayoutComponentView_h

NS_ASSUME_NONNULL_BEGIN

@interface RoktNativeLayoutComponentView : RCTViewComponentView
@property (nonatomic, readonly) MPRoktEmbeddedView *roktEmbeddedView;
@end

NS_ASSUME_NONNULL_END
#endif // RoktNativeLayoutComponentView_h
#endif // RCT_NEW_ARCH_ENABLED
