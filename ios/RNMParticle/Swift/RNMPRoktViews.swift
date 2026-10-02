import RoktContracts
import UIKit

/// The embedded view the Rokt SDK renders into, for Objective-C++ code that cannot see its type.
@objc(RNMPRoktViews)
public final class RNMPRoktViews: NSObject {
    @objc(makeEmbeddedViewWithFrame:)
    public static func makeEmbeddedView(frame: CGRect) -> UIView {
        RoktEmbeddedView(frame: frame)
    }

    @objc(isEmbeddedView:)
    public static func isEmbeddedView(_ view: UIView?) -> Bool {
        view is RoktEmbeddedView
    }
}
