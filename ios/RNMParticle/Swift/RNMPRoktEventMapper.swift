import Foundation
import RoktContracts

/// Maps a Rokt SDK event to the `RoktEvents` payload sent to JavaScript, plus the side effects
/// RoktEventManager performs for it. Pure mapping only; React stays in RoktEventManager.mm.
@objc(RNMPRoktEventMapper)
public final class RNMPRoktEventMapper: NSObject {
    /// Keys: "payload" (the JS body), optional "callback" (RoktCallback value), and optional
    /// "height" + "placement" (LayoutHeightChanges).
    @objc(mapEvent:viewName:)
    public static func map(_ event: RoktEvent, viewName: String?) -> [String: Any] {
        var name = ""
        var fields: [String: Any?] = [:]
        var callback: String?
        var height: CGFloat?
        var placement: String?

        switch event {
        case is RoktEvent.ShowLoadingIndicator:
            name = "ShowLoadingIndicator"; callback = "onShouldShowLoadingIndicator"
        case is RoktEvent.HideLoadingIndicator:
            name = "HideLoadingIndicator"; callback = "onShouldHideLoadingIndicator"
        case let e as RoktEvent.PlacementInteractive:
            name = "PlacementInteractive"; fields["placementId"] = e.identifier
        case let e as RoktEvent.PlacementReady:
            name = "PlacementReady"; fields["placementId"] = e.identifier; callback = "onLoad"
        case let e as RoktEvent.OfferEngagement:
            name = "OfferEngagement"; fields["placementId"] = e.identifier
        case let e as RoktEvent.PositiveEngagement:
            name = "PositiveEngagement"; fields["placementId"] = e.identifier
        case let e as RoktEvent.PlacementClosed:
            name = "PlacementClosed"; fields["placementId"] = e.identifier; callback = "onUnLoad"
        case let e as RoktEvent.PlacementCompleted:
            name = "PlacementCompleted"; fields["placementId"] = e.identifier
        case let e as RoktEvent.PlacementFailure:
            name = "PlacementFailure"; fields["placementId"] = e.identifier
        case let e as RoktEvent.FirstPositiveEngagement:
            name = "FirstPositiveEngagement"; fields["placementId"] = e.identifier
        case let e as RoktEvent.InitComplete:
            name = "InitComplete"; fields["status"] = e.success ? "true" : "false"
        case let e as RoktEvent.OpenUrl:
            name = "OpenUrl"; fields["placementId"] = e.identifier; fields["url"] = e.url
        case let e as RoktEvent.EmbeddedSizeChanged:
            name = "EmbeddedSizeChanged"; fields["placementId"] = e.identifier
            height = e.updatedHeight; placement = e.identifier
        case let e as RoktEvent.CartItemInstantPurchase:
            name = "CartItemInstantPurchase"
            fields = ["placementId": e.identifier, "cartItemId": e.cartItemId, "catalogItemId": e.catalogItemId,
                      "currency": e.currency, "providerData": e.providerData, "linkedProductId": e.linkedProductId,
                      "description": e.description, "quantity": e.quantity, "totalPrice": e.totalPrice,
                      "unitPrice": e.unitPrice]
        case let e as RoktEvent.CartItemInstantPurchaseInitiated:
            name = "CartItemInstantPurchaseInitiated"
            fields = ["placementId": e.identifier, "catalogItemId": e.catalogItemId, "cartItemId": e.cartItemId]
        case let e as RoktEvent.CartItemInstantPurchaseFailure:
            name = "CartItemInstantPurchaseFailure"
            fields = ["placementId": e.identifier, "catalogItemId": e.catalogItemId, "cartItemId": e.cartItemId,
                      "error": e.error]
        case let e as RoktEvent.InstantPurchaseDismissal:
            name = "InstantPurchaseDismissal"; fields["placementId"] = e.identifier
        case let e as RoktEvent.CartItemDevicePay:
            name = "CartItemDevicePay"
            fields = ["placementId": e.identifier, "catalogItemId": e.catalogItemId, "cartItemId": e.cartItemId,
                      "paymentProvider": e.paymentProvider]
        default:
            break
        }

        var payload: [String: Any] = fields.compactMapValues { $0 }
        payload["event"] = name
        if let viewName { payload["viewName"] = viewName }

        var result: [String: Any] = ["payload": payload]
        if let callback { result["callback"] = callback }
        if let height, let placement { result["height"] = Double(height); result["placement"] = placement }
        return result
    }

    /// The event the SDK sends for a call it rejects; also sent when a pending call is dropped.
    @objc(placementFailure)
    public static func placementFailure() -> RoktEvent {
        RoktEvent.PlacementFailure(identifier: nil)
    }
}
