#import "RoktEventManager.h"
// Not `@import RoktContracts` -- this file is Objective-C++ and the pod builds without
// -fcxx-modules, so the module import fails. Matches how RNMPRokt.mm imports the same types.
#if __has_include(<RoktContracts/RoktContracts-Swift.h>)
    #import <RoktContracts/RoktContracts-Swift.h>
#elif __has_include(<RoktContracts/RoktContracts.h>)
    #import <RoktContracts/RoktContracts.h>
#endif
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
     NSString *eventClass = event ? NSStringFromClass([event class]) : @"nil";
     _rokt_events_log(@"[mParticle-Rokt] RoktEventManager onRoktEvents: %@ viewName: %@", eventClass, viewName ?: @"(nil)");
     if (hasListeners) {
         NSString *placementId;
         NSString *eventName = @"";
         NSString *status;
         NSString *url;
         NSString *cartItemId;
         NSString *catalogItemId;
         NSString *currency;
         NSString *itemDescription;
         NSString *linkedProductId;
         NSString *providerData;
         NSDecimalNumber *quantity;
         NSDecimalNumber *totalPrice;
         NSDecimalNumber *unitPrice;
         NSString *error;
         NSString *paymentProvider;

         if ([event isKindOfClass:[RoktShowLoadingIndicator class]]) {
             eventName = @"ShowLoadingIndicator";
             [self onRoktCallbackReceived:@"onShouldShowLoadingIndicator"];
         } else if ([event isKindOfClass:[RoktHideLoadingIndicator class]]) {
             eventName = @"HideLoadingIndicator";
             [self onRoktCallbackReceived:@"onShouldHideLoadingIndicator"];
         } else if ([event isKindOfClass:[RoktPlacementInteractive class]]) {
             placementId = ((RoktPlacementInteractive *)event).identifier;
             eventName = @"PlacementInteractive";
         } else if ([event isKindOfClass:[RoktPlacementReady class]]) {
             placementId = ((RoktPlacementReady *)event).identifier;
             eventName = @"PlacementReady";
             [self onRoktCallbackReceived:@"onLoad"];
         } else if ([event isKindOfClass:[RoktOfferEngagement class]]) {
             placementId = ((RoktOfferEngagement *)event).identifier;
             eventName = @"OfferEngagement";
         } else if ([event isKindOfClass:[RoktPositiveEngagement class]]) {
             placementId = ((RoktPositiveEngagement *)event).identifier;
             eventName = @"PositiveEngagement";
         } else if ([event isKindOfClass:[RoktPlacementClosed class]]) {
             placementId = ((RoktPlacementClosed *)event).identifier;
             eventName = @"PlacementClosed";
             [self onRoktCallbackReceived:@"onUnLoad"];
         } else if ([event isKindOfClass:[RoktPlacementCompleted class]]) {
             placementId = ((RoktPlacementCompleted *)event).identifier;
             eventName = @"PlacementCompleted";
         } else if ([event isKindOfClass:[RoktPlacementFailure class]]) {
             placementId = ((RoktPlacementFailure *)event).identifier;
             eventName = @"PlacementFailure";
         } else if ([event isKindOfClass:[RoktFirstPositiveEngagement class]]) {
             placementId = ((RoktFirstPositiveEngagement *)event).identifier;
             eventName = @"FirstPositiveEngagement";
         } else if ([event isKindOfClass:[RoktInitComplete class]]) {
             eventName = @"InitComplete";
             status = ((RoktInitComplete *)event).success ? @"true" : @"false";
         } else if ([event isKindOfClass:[RoktOpenUrl class]]) {
             eventName = @"OpenUrl";
             placementId = ((RoktOpenUrl *)event).identifier;
             url = ((RoktOpenUrl *)event).url;
         } else if ([event isKindOfClass:[RoktEmbeddedSizeChanged class]]) {
             RoktEmbeddedSizeChanged *sizeEvent = (RoktEmbeddedSizeChanged *)event;
             placementId = sizeEvent.identifier;
             eventName = @"EmbeddedSizeChanged";
             [self onWidgetHeightChanges:sizeEvent.updatedHeight placement:sizeEvent.identifier];
         } else if ([event isKindOfClass:[RoktCartItemInstantPurchase class]]) {
             RoktCartItemInstantPurchase *cartEvent = (RoktCartItemInstantPurchase *)event;
             eventName = @"CartItemInstantPurchase";
             placementId = cartEvent.identifier;
             cartItemId = cartEvent.cartItemId;
             catalogItemId = cartEvent.catalogItemId;
             currency = cartEvent.currency;
             providerData = cartEvent.providerData;
             linkedProductId = cartEvent.linkedProductId;
             itemDescription = cartEvent.description;
             quantity = cartEvent.quantity;
             totalPrice = cartEvent.totalPrice;
             unitPrice = cartEvent.unitPrice;
         } else if ([event isKindOfClass:[RoktCartItemInstantPurchaseInitiated class]]) {
             RoktCartItemInstantPurchaseInitiated *initiatedEvent = (RoktCartItemInstantPurchaseInitiated *)event;
             eventName = @"CartItemInstantPurchaseInitiated";
             placementId = initiatedEvent.identifier;
             catalogItemId = initiatedEvent.catalogItemId;
             cartItemId = initiatedEvent.cartItemId;
         } else if ([event isKindOfClass:[RoktCartItemInstantPurchaseFailure class]]) {
             RoktCartItemInstantPurchaseFailure *failureEvent = (RoktCartItemInstantPurchaseFailure *)event;
             eventName = @"CartItemInstantPurchaseFailure";
             placementId = failureEvent.identifier;
             catalogItemId = failureEvent.catalogItemId;
             cartItemId = failureEvent.cartItemId;
             error = failureEvent.error;
         } else if ([event isKindOfClass:[RoktInstantPurchaseDismissal class]]) {
             RoktInstantPurchaseDismissal *dismissalEvent = (RoktInstantPurchaseDismissal *)event;
             eventName = @"InstantPurchaseDismissal";
             placementId = dismissalEvent.identifier;
         } else if ([event isKindOfClass:[RoktCartItemDevicePay class]]) {
             RoktCartItemDevicePay *devicePayEvent = (RoktCartItemDevicePay *)event;
             eventName = @"CartItemDevicePay";
             placementId = devicePayEvent.identifier;
             catalogItemId = devicePayEvent.catalogItemId;
             cartItemId = devicePayEvent.cartItemId;
             paymentProvider = devicePayEvent.paymentProvider;
         }

         NSMutableDictionary *payload = [@{@"event": eventName} mutableCopy];
         if (viewName != nil) {
             [payload setObject:viewName forKey:@"viewName"];
         }
         if (placementId != nil) {
             [payload setObject:placementId forKey:@"placementId"];
         }
         if (status != nil) {
             [payload setObject:status forKey:@"status"];
         }
         if (url != nil) {
             [payload setObject:url forKey:@"url"];
         }
         if (cartItemId != nil) {
             [payload setObject:cartItemId forKey:@"cartItemId"];
         }
         if (catalogItemId != nil) {
             [payload setObject:catalogItemId forKey:@"catalogItemId"];
         }
         if (currency != nil) {
             [payload setObject:currency forKey:@"currency"];
         }
         if (itemDescription != nil) {
             [payload setObject:itemDescription forKey:@"description"];
         }
         if (linkedProductId != nil) {
             [payload setObject:linkedProductId forKey:@"linkedProductId"];
         }
         if (providerData != nil) {
             [payload setObject:providerData forKey:@"providerData"];
         }
         if (quantity != nil) {
             [payload setObject:quantity forKey:@"quantity"];
         }
         if (totalPrice != nil) {
             [payload setObject:totalPrice forKey:@"totalPrice"];
         }
         if (unitPrice != nil) {
             [payload setObject:unitPrice forKey:@"unitPrice"];
         }
         if (error != nil) {
             [payload setObject:error forKey:@"error"];
         }
         if (paymentProvider != nil) {
             [payload setObject:paymentProvider forKey:@"paymentProvider"];
         }

         [self sendEventWithName:@"RoktEvents" body:payload];
     }
}

#ifdef RCT_NEW_ARCH_ENABLED
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const facebook::react::ObjCTurboModule::InitParams &)params {
    return std::make_shared<facebook::react::NativeRoktEventManagerSpecJSI>(params);
}
#endif // RCT_NEW_ARCH_ENABLED

@end
