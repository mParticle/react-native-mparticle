#import "RoktPlaceholderRegistry.h"

// A name keeps every live view registered under it (newest last) rather than only the latest,
// because stacked screens can each mount the same placeholder name: popping the top screen must
// leave the one underneath resolvable.
// ponytail: linear scan over a handful of views; global across React hosts, key by surface if a
// brownfield app ever mounts the same name in two surfaces at once.
static NSMutableDictionary<NSString *, NSPointerArray *> *RoktPlaceholderViews(void) {
    static NSMutableDictionary<NSString *, NSPointerArray *> *views;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        views = [NSMutableDictionary new];
    });
    return views;
}

@interface RoktPlaceholderWait : NSObject
@property (nonatomic, copy) NSArray<NSString *> *names;
@property (nonatomic, copy) dispatch_block_t completion;
@end

@implementation RoktPlaceholderWait
@end

// Pending selectPlacements calls waiting for their placeholders to mount, keyed by caller.
static NSMutableDictionary<NSString *, RoktPlaceholderWait *> *RoktPlaceholderWaits(void) {
    static NSMutableDictionary<NSString *, RoktPlaceholderWait *> *waits;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        waits = [NSMutableDictionary new];
    });
    return waits;
}

@implementation RoktPlaceholderRegistry

+ (void)registerView:(UIView *)view name:(NSString *)name
{
    [self unregisterView:view];
    if (name.length == 0) {
        return;
    }
    NSPointerArray *views = RoktPlaceholderViews()[name];
    if (views == nil) {
        views = [NSPointerArray weakObjectsPointerArray];
        RoktPlaceholderViews()[name] = views;
    }
    [views addPointer:(__bridge void *)view];
    [self completeSatisfiedWaits];
}

+ (void)unregisterView:(UIView *)view
{
    NSMutableDictionary<NSString *, NSPointerArray *> *all = RoktPlaceholderViews();
    for (NSString *name in all.allKeys) {
        NSPointerArray *views = all[name];
        for (NSInteger i = (NSInteger)views.count - 1; i >= 0; i--) {
            void *pointer = [views pointerAtIndex:(NSUInteger)i];
            if (pointer == NULL || pointer == (__bridge void *)view) {
                [views removePointerAtIndex:(NSUInteger)i];
            }
        }
        if (views.count == 0) {
            [all removeObjectForKey:name];
        }
    }
}

+ (UIView *)viewForName:(NSString *)name
{
    UIView *newestAlive = nil;
    for (UIView *view in RoktPlaceholderViews()[name].allObjects.reverseObjectEnumerator) {
        if (view.window != nil) {
            return view;
        }
        newestAlive = newestAlive ?: view;
    }
    return newestAlive;
}

+ (void)waitForNames:(NSArray<NSString *> *)names
                 key:(NSString *)key
             timeout:(NSTimeInterval)timeout
          completion:(dispatch_block_t)completion
{
    RoktPlaceholderWait *wait = [RoktPlaceholderWait new];
    wait.names = names;
    wait.completion = completion;
    RoktPlaceholderWaits()[key] = wait;
    if ([self allNamesRegistered:names]) {
        [self completeWaitForKey:key];
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Only if this wait is still the pending one for its key.
        if (RoktPlaceholderWaits()[key] == wait) {
            [self completeWaitForKey:key];
        }
    });
}

+ (void)cancelAllWaits
{
    [RoktPlaceholderWaits() removeAllObjects];
}

+ (BOOL)allNamesRegistered:(NSArray<NSString *> *)names
{
    for (NSString *name in names) {
        if ([self viewForName:name] == nil) {
            return NO;
        }
    }
    return YES;
}

+ (void)completeSatisfiedWaits
{
    NSDictionary<NSString *, RoktPlaceholderWait *> *waits = [RoktPlaceholderWaits() copy];
    for (NSString *key in waits) {
        if ([self allNamesRegistered:waits[key].names]) {
            [self completeWaitForKey:key];
        }
    }
}

+ (void)completeWaitForKey:(NSString *)key
{
    RoktPlaceholderWait *wait = RoktPlaceholderWaits()[key];
    [RoktPlaceholderWaits() removeObjectForKey:key];
    // Asynchronously: registration happens mid-mount, and the Rokt SDK mutates the placeholder
    // view hierarchy, so it must not run inside the mount transaction.
    dispatch_async(dispatch_get_main_queue(), wait.completion);
}

@end
