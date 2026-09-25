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

@end
