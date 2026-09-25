#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Maps a `RoktLayoutView`'s `placeholderName` to its mounted `RoktEmbeddedView`, so
 * `selectPlacements` can resolve placeholders by name instead of a `findNodeHandle` react tag.
 *
 * Main thread only. Plain Objective-C so the legacy `.m` view manager can import it.
 */
@interface RoktPlaceholderRegistry : NSObject

/// Registers `view` under `name`, moving it off any name it was previously registered under.
/// A nil or empty `name` only unregisters.
+ (void)registerView:(UIView *)view name:(nullable NSString *)name;

+ (void)unregisterView:(UIView *)view;

/// The newest view in a window, else the newest still alive.
+ (nullable UIView *)viewForName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
