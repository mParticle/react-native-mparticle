package com.mparticle.react.rokt

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.NativeViewHierarchyManager
import com.facebook.react.uimanager.UIManagerModule
import com.mparticle.MParticle
import com.mparticle.WrapperSdk
import com.mparticle.internal.Logger
import com.mparticle.react.NativeMPRoktSpec
import com.mparticle.rokt.RoktEmbeddedView
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
        val uiManager = reactContext.getNativeModule(UIManagerModule::class.java)
        MParticle.getInstance()?.Rokt()?.events(identifier)?.let {
            impl.startRoktEventListener(it, reactContext.currentActivity, identifier)
        }

        val config = roktConfig?.let { impl.buildRoktConfig(it) }
        uiManager?.addUIBlock { nativeViewHierarchyManager ->
            MParticle.getInstance()?.Rokt()?.selectPlacements(
                identifier = identifier,
                attributes = impl.readableMapToMapOfStrings(attributes),
                callbacks = impl.createRoktCallback(),
                embeddedViews = safeUnwrapPlaceholders(placeholders, nativeViewHierarchyManager),
                fontTypefaces = null, // TODO
                config = config,
            )
        }
    }

    @ReactMethod
    override fun purchaseFinalized(
        placementId: String,
        catalogItemId: String,
        success: Boolean,
    ) {
        impl.purchaseFinalized(placementId, catalogItemId, success)
    }

    private fun safeUnwrapPlaceholders(
        placeholders: ReadableMap?,
        nativeViewHierarchyManager: NativeViewHierarchyManager,
    ): Map<String, WeakReference<RoktEmbeddedView>> {
        val placeholderMap: MutableMap<String, WeakReference<RoktEmbeddedView>> = HashMap()

        if (placeholders != null) {
            placeholderMap.putAll(
                placeholders
                    .toHashMap()
                    .filterValues { value -> value is Double }
                    .mapValues { pair -> (pair.value as Double).toInt() }
                    .mapValues { pair -> nativeViewHierarchyManager.resolveView(pair.value) as? RoktEmbeddedView }
                    .filterValues { value -> value != null }
                    .mapValues { WeakReference(it.value as RoktEmbeddedView) },
            )
        }
        return placeholderMap
    }
}
