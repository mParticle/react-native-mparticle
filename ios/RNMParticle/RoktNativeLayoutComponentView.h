#ifdef RCT_NEW_ARCH_ENABLED
#import <SafariServices/SafariServices.h>
#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

#ifndef RoktNativeLayoutComponentView_h
#define RoktNativeLayoutComponentView_h

NS_ASSUME_NONNULL_BEGIN

@interface RoktNativeLayoutComponentView : RCTViewComponentView
// The RoktEmbeddedView the SDK renders into (typed UIView so Objective-C++ needs no Rokt headers).
@property (nonatomic, readonly) UIView *roktEmbeddedView;
@end

NS_ASSUME_NONNULL_END
#endif // RoktNativeLayoutComponentView_h
#endif // RCT_NEW_ARCH_ENABLED
