import Foundation
import RoktContracts

/// Builds the Rokt SDK config from the `roktConfig` object JavaScript passes. Returns nil when the
/// object has no usable keys, which the SDK treats as "no config".
@objc(RNMPRoktConfigFactory)
public final class RNMPRoktConfigFactory: NSObject {
    @objc(configFromDictionary:)
    public static func config(from map: [String: Any]?) -> RoktConfig? {
        guard let map, !map.isEmpty else { return nil }

        let builder = RoktConfig.Builder()
        var isEmpty = true

        if let colorMode = map["colorMode"] as? String {
            isEmpty = false
            switch colorMode {
            case "dark": builder.colorMode(.dark)
            case "light": builder.colorMode(.light)
            default: builder.colorMode(.system)
            }
        }

        if let cache = map["cacheConfig"] as? [String: Any] {
            isEmpty = false
            // Whole seconds, as the Objective-C version read it (longLongValue).
            let seconds = (cache["cacheDurationInSeconds"] as? NSNumber)?.int64Value ?? 0
            let attributes = cache["cacheAttributes"] as? [String: String] ?? [:]
            builder.cacheConfig(RoktConfig.CacheConfig(cacheDuration: TimeInterval(seconds), cacheAttributes: attributes))
        }

        return isEmpty ? nil : builder.build()
    }
}
