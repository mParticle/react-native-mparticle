#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Implemented in Swift (Swift/*.swift). Declared by hand instead of importing the generated
// -Swift.h header: under Swift Package Manager the Swift code is a separate target, and
// Objective-C++ files cannot reach another target's generated header without C++ modules.
// Only Foundation and UIKit types appear here, so Objective-C++ never needs the RoktContracts
// headers. Keep each declaration in sync with its @objc name; RNMPRoktSwiftTests checks them.

@interface RNMPRoktEventMapper : NSObject
// Keys: "payload" (the RoktEvents body), optional "callback" (a RoktCallback value), and
// optional "height" and "placement" (LayoutHeightChanges).
+ (NSDictionary<NSString *, id> *)mapEvent:(id)event viewName:(nullable NSString *)viewName;
// A RoktPlacementFailure with no identifier.
+ (id)placementFailure;
@end

@interface RNMPRoktConfigFactory : NSObject
// A RoktConfig, or nil when the dictionary has no usable keys.
+ (nullable id)configFromDictionary:(nullable NSDictionary<NSString *, id> *)dictionary;
@end

@interface RNMPRoktViews : NSObject
// A RoktEmbeddedView.
+ (UIView *)makeEmbeddedViewWithFrame:(CGRect)frame;
+ (BOOL)isEmbeddedView:(nullable UIView *)view;
@end

NS_ASSUME_NONNULL_END
