#import "RoktEventManager.h"
#import <mParticle_Apple_SDK/mParticle_Apple_SDK-Swift.h>

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
    });
    return sharedInstance;
}

// Will be called when this module's first listener is added.
-(void)startObserving {
    hasListeners = YES;
}

// Will be called when this module's last listener is removed, or on dealloc.
-(void)stopObserving {
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
    if (hasListeners) {
        [self sendEventWithName:@"RoktCallback" body:@{@"callbackValue": eventValue}];
    }
}

- (void)onRoktEvents:(MPRoktEvent * _Nonnull)event viewName:(NSString * _Nullable)viewName
{
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
         
         if ([event isKindOfClass:[MPRoktShowLoadingIndicator class]]) {
             eventName = @"ShowLoadingIndicator";
         } else if ([event isKindOfClass:[MPRoktHideLoadingIndicator class]]) {
             eventName = @"HideLoadingIndicator";
         } else if ([event isKindOfClass:[MPRoktPlacementInteractive class]]) {
             placementId = ((MPRoktPlacementInteractive *)event).placementId;
             eventName = @"PlacementInteractive";
         } else if ([event isKindOfClass:[MPRoktPlacementReady class]]) {
             placementId = ((MPRoktPlacementReady *)event).placementId;
             eventName = @"PlacementReady";
         } else if ([event isKindOfClass:[MPRoktOfferEngagement class]]) {
             placementId = ((MPRoktOfferEngagement *)event).placementId;
             eventName = @"OfferEngagement";
         } else if ([event isKindOfClass:[MPRoktPositiveEngagement class]]) {
             placementId = ((MPRoktPositiveEngagement *)event).placementId;
             eventName = @"PositiveEngagement";
         } else if ([event isKindOfClass:[MPRoktPlacementClosed class]]) {
             placementId = ((MPRoktPlacementClosed *)event).placementId;
             eventName = @"PlacementClosed";
         } else if ([event isKindOfClass:[MPRoktPlacementCompleted class]]) {
             placementId = ((MPRoktPlacementCompleted *)event).placementId;
             eventName = @"PlacementCompleted";
         } else if ([event isKindOfClass:[MPRoktPlacementFailure class]]) {
             placementId = ((MPRoktPlacementFailure *)event).placementId;
             eventName = @"PlacementFailure";
         } else if ([event isKindOfClass:[MPRoktFirstPositiveEngagement class]]) {
             placementId = ((MPRoktFirstPositiveEngagement *)event).placementId;
             eventName = @"FirstPositiveEngagement";
         } else if ([event isKindOfClass:[MPRoktInitComplete class]]) {
             eventName = @"InitComplete";
             status = ((MPRoktInitComplete *)event).success ? @"true" : @"false";
         } else if ([event isKindOfClass:[MPRoktOpenUrl class]]) {
             eventName = @"OpenUrl";
             placementId = ((MPRoktOpenUrl *)event).placementId;
             url = ((MPRoktOpenUrl *)event).url;
         } else if ([event isKindOfClass:[MPRoktCartItemInstantPurchase class]]) {
             MPRoktCartItemInstantPurchase *cartEvent = (MPRoktCartItemInstantPurchase *)event;
             eventName = @"CartItemInstantPurchase";
             // Required properties
             placementId = cartEvent.placementId;
             cartItemId = cartEvent.cartItemId;
             catalogItemId = cartEvent.catalogItemId;
             currency = cartEvent.currency;
             providerData = cartEvent.providerData;
             // Optional properties
             linkedProductId = cartEvent.linkedProductId;
             // Overridden description property
             itemDescription = cartEvent.description;
             // Decimal properties
             quantity = cartEvent.quantity;
             totalPrice = cartEvent.totalPrice;
             unitPrice = cartEvent.unitPrice;
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

         [self sendEventWithName:@"RoktEvents" body:payload];
     }
}

@end
