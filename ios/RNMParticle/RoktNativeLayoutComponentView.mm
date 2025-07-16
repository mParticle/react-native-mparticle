#ifdef RCT_NEW_ARCH_ENABLED
#import <SafariServices/SafariServices.h>
#import "RoktNativeLayoutComponentView.h"

#import <React/renderer/components/RNMParticle/ComponentDescriptors.h>
#import <react/renderer/components/RNMParticle/Props.h>
#import <React/renderer/components/RNMParticle/RCTComponentViewHelpers.h>

using namespace facebook::react;

@interface RoktNativeLayoutComponentView () <RCTRoktNativeLayoutViewProtocol>
@property (nonatomic, nullable) MPRoktEmbeddedView *roktEmbeddedView;
@property (nonatomic, nullable) NSString *placeholderName;
@end

@implementation RoktNativeLayoutComponentView {
    UIView * _view;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
    return concreteComponentDescriptorProvider<RoktNativeLayoutComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    _roktEmbeddedView = [[MPRoktEmbeddedView alloc] initWithFrame:self.bounds];
    _roktEmbeddedView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_roktEmbeddedView];
    NSLog(@"[ROKT] iOS Fabric: RoktFabricWrapperView initialized");
  }
  return self;
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
  // This is intentionally left blank.
  // The props are handled by the view manager and direct access to the swift view.
  [super updateProps:props oldProps:oldProps];
}

// Export function for codegen compatibility
// This may be referenced by generated code even though we use the class name in package.json
extern "C" Class<RCTComponentViewProtocol> RoktNativeLayoutCls(void) {
  return RoktNativeLayoutComponentView.class;
}

@end
#endif // RCT_NEW_ARCH_ENABLED
