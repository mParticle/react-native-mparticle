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

/// Calls `completion` on the main queue once every name in `names` has a registered view, or
/// after `timeout` seconds, whichever comes first. A new wait with the same `key` replaces the
/// previous one; a replaced or cancelled wait never completes and calls `discarded` on the main
/// queue instead, so the caller can report the dropped request.
+ (void)waitForNames:(NSArray<NSString *> *)names
                 key:(NSString *)key
             timeout:(NSTimeInterval)timeout
          completion:(dispatch_block_t)completion
           discarded:(dispatch_block_t)discarded;

/// Drops every pending wait, calling its `discarded` block.
+ (void)cancelAllWaits;

@end

NS_ASSUME_NONNULL_END
