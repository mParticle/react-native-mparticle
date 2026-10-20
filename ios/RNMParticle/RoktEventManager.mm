#import "RoktEventManager.h"
#import "RNMPRoktSwift.h"
#import <os/log.h>

static os_log_t _rokt_events_os_log(void) {
  static os_log_t log;
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    log = os_log_create("com.mparticle.react-native", "rokt-events");
  });
  return log;
}

static void _rokt_events_log(NSString *format, ...) {
  va_list args;
  va_start(args, format);
  NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];
  va_end(args);
  os_log_with_type(_rokt_events_os_log(), OS_LOG_TYPE_INFO, "%{public}s", [msg UTF8String]);
}

@implementation RoktEventManager
{
  bool hasListeners;
}

RCT_EXPORT_MODULE(RoktEventManager);

+ (id)allocWithZone:(NSZone *)zone {
    static RoktEventManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [super allocWithZone:zone];
        _rokt_events_log(@"[mParticle-Rokt] RoktEventManager module alloc");
    });
    return sharedInstance;
}

// Will be called when this module's first listener is added.
-(void)startObserving {
    _rokt_events_log(@"[mParticle-Rokt] RoktEventManager startObserving (JS listener added)");
    hasListeners = YES;
}

// Will be called when this module's last listener is removed, or on dealloc.
-(void)stopObserving {
    _rokt_events_log(@"[mParticle-Rokt] RoktEventManager stopObserving (no JS listeners)");
    hasListeners = NO;
}


- (NSArray<NSString *> *)supportedEvents
{
  return @[@"LayoutHeightChanges", @"FirstPositiveResponse", @"RoktCallback", @"RoktEvents"];
}

- (void)onWidgetHeightChanges:(CGFloat)widgetHeight placement:(NSString*) selectedPlacement
{
    if (hasListeners) {
        [self sendEventWithName:@"LayoutHeightChanges" body:@{@"height": [NSNumber numberWithDouble: widgetHeight],
                                                              @"selectedPlacement": selectedPlacement
        }];
    }
}

- (void)onFirstPositiveResponse
{
    if (hasListeners) {
        [self sendEventWithName:@"FirstPositiveResponse" body:@{@"":@""}];
    }
}

- (void)onRoktCallbackReceived:(NSString*)eventValue
{
    _rokt_events_log(@"[mParticle-Rokt] RoktEventManager onRoktCallbackReceived: %@", eventValue ?: @"(nil)");
    if (hasListeners) {
        [self sendEventWithName:@"RoktCallback" body:@{@"callbackValue": eventValue}];
    }
}

- (void)onRoktEvents:(RoktEvent * _Nonnull)event viewName:(NSString * _Nullable)viewName
{
    // RoktEvent is only forward-declared here, so message it as an NSObject.
    NSString *eventClass = event ? NSStringFromClass([(NSObject *)event class]) : @"nil";
    _rokt_events_log(@"[mParticle-Rokt] RoktEventManager onRoktEvents: %@ viewName: %@", eventClass, viewName ?: @"(nil)");
    if (!hasListeners) {
        return;
    }
    // The mapping lives in Swift (RNMPRoktEventMapper), which can see the Rokt event types.
    NSDictionary<NSString *, id> *mapped = [RNMPRoktEventMapper mapEvent:event viewName:viewName];
    if (mapped[@"callback"] != nil) {
        [self onRoktCallbackReceived:mapped[@"callback"]];
    }
    if (mapped[@"height"] != nil) {
        [self onWidgetHeightChanges:[mapped[@"height"] doubleValue] placement:mapped[@"placement"]];
    }
    [self sendEventWithName:@"RoktEvents" body:mapped[@"payload"]];
}

#ifdef RCT_NEW_ARCH_ENABLED
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const facebook::react::ObjCTurboModule::InitParams &)params {
    return std::make_shared<facebook::react::NativeRoktEventManagerSpecJSI>(params);
}
#endif // RCT_NEW_ARCH_ENABLED

@end
