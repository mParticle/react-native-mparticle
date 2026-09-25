#ifdef RCT_NEW_ARCH_ENABLED
#import <SafariServices/SafariServices.h>
#import "RoktNativeLayoutComponentView.h"
#import "RoktPlaceholderRegistry.h"

#import <React/renderer/components/RNMParticle/ComponentDescriptors.h>
#import <react/renderer/components/RNMParticle/Props.h>
#import <React/renderer/components/RNMParticle/RCTComponentViewHelpers.h>
#import <React/RCTConversions.h>

using namespace facebook::react;

@interface RoktNativeLayoutComponentView () <RCTRoktNativeLayoutViewProtocol>
@property (nonatomic, nullable) RoktEmbeddedView *roktEmbeddedView;
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
    _roktEmbeddedView = [[RoktEmbeddedView alloc] initWithFrame:self.bounds];
    // Width only: the Rokt SDK owns the height (updateEmbeddedSize sets it before JS
    // resizes this view), so flexible height would re-apply that delta once React Native
    // caught up, doubling the embedded view and centring the layout below blank space.
    _roktEmbeddedView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self addSubview:_roktEmbeddedView];
    NSLog(@"[ROKT] iOS Fabric: RoktFabricWrapperView initialized");
  }
  return self;
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
  // Register by placeholderName so selectPlacements can resolve this view by name.
  const auto &newProps = *std::static_pointer_cast<const RoktNativeLayoutProps>(props);
  NSString *placeholderName = RCTNSStringFromStringNilIfEmpty(newProps.placeholderName);
  if (![placeholderName isEqualToString:_placeholderName]) {
    _placeholderName = placeholderName;
    [RoktPlaceholderRegistry registerView:_roktEmbeddedView name:placeholderName];
  }
  [super updateProps:props oldProps:oldProps];
}

- (void)prepareForRecycle
{
  [RoktPlaceholderRegistry unregisterView:_roktEmbeddedView];
  _placeholderName = nil;
  [super prepareForRecycle];
}

// Export function for codegen compatibility
// This may be referenced by generated code even though we use the class name in package.json
extern "C" Class<RCTComponentViewProtocol> RoktNativeLayoutCls(void) {
  return RoktNativeLayoutComponentView.class;
}

@end
#endif // RCT_NEW_ARCH_ENABLED
