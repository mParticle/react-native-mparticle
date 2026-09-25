package com.mparticle.react.rokt

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.NativeViewHierarchyManager
import com.facebook.react.uimanager.UIManagerModule
import com.mparticle.MParticle
import com.mparticle.internal.Logger
import com.mparticle.kits.RoktEmbeddedView
import com.mparticle.kits.rokt
import com.mparticle.react.NativeMPRoktSpec
import java.lang.ref.WeakReference

class MPRoktModule(
    private val reactContext: ReactApplicationContext,
) : NativeMPRoktSpec(reactContext) {
    private val impl = MPRoktModuleImpl(reactContext)

    override fun getName(): String = impl.getName()

    @ReactMethod
    override fun selectPlacements(
        identifier: String,
        attributes: ReadableMap?,
        placeholders: ReadableMap?,
        roktConfig: ReadableMap?,
        fontFilesMap: ReadableMap?,
    ) {
        if (identifier.isBlank()) {
            Logger.warning("selectPlacements failed. identifier cannot be empty")
            return
        }
        impl.setWrapperSdk()
        val uiManager = reactContext.getNativeModule(UIManagerModule::class.java)
        MParticle.getInstance()?.rokt?.events(identifier)?.let {
            impl.startRoktEventListener(it, reactContext.currentActivity, identifier)
        }

        val config = roktConfig?.let { impl.buildRoktConfig(it) }
        uiManager?.addUIBlock { nativeViewHierarchyManager ->
            MParticle.getInstance()?.rokt?.selectPlacements(
                identifier = identifier,
                attributes = impl.readableMapToMapOfStrings(attributes),
                embeddedViews = safeUnwrapPlaceholders(placeholders, nativeViewHierarchyManager),
                fontTypefaces = null, // TODO
                config = config,
            )
        }
    }

    @ReactMethod
    override fun selectShoppableAds(
        identifier: String,
        attributes: ReadableMap?,
        roktConfig: ReadableMap?,
    ) {
        impl.selectShoppableAds(identifier, attributes, roktConfig)
    }

    @ReactMethod
    override fun purchaseFinalized(
        placementId: String,
        catalogItemId: String,
        success: Boolean,
    ) {
        impl.purchaseFinalized(placementId, catalogItemId, success)
    }

    @ReactMethod
    override fun close(promise: Promise) {
        impl.close(promise)
    }

    @ReactMethod
    override fun setSessionId(
        sessionId: String,
        promise: Promise,
    ) {
        impl.setSessionId(sessionId, promise)
    }

    @ReactMethod
    override fun getSessionId(promise: Promise) {
        impl.getSessionId(promise)
    }

    // Positive numeric values are legacy react tags. Zero is the name-lookup sentinel used by
    // the JS wrapper; unresolved tags also fall back to placeholderName.
    private fun safeUnwrapPlaceholders(
        placeholders: ReadableMap?,
        nativeViewHierarchyManager: NativeViewHierarchyManager,
    ): Map<String, WeakReference<RoktEmbeddedView>> {
        val placeholderMap: MutableMap<String, WeakReference<RoktEmbeddedView>> = HashMap()

        placeholders?.toHashMap()?.forEach { (key, value) ->
            val view =
                (value as? Double)?.takeIf { it > 0 }?.let {
                    runCatching { nativeViewHierarchyManager.resolveView(it.toInt()) as? RoktEmbeddedView }.getOrNull()
                } ?: RoktPlaceholderRegistry.lookup(key) as? RoktEmbeddedView
            if (view != null) {
                placeholderMap[key] = WeakReference(view)
            } else {
                Logger.warning("Cannot resolve placeholder for key: $key")
            }
        }
        return placeholderMap
    }
}
