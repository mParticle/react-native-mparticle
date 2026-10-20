package com.mparticle.react.rokt

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.UiThreadUtil
import com.mparticle.MParticle
import com.mparticle.internal.Logger
import com.mparticle.kits.rokt
import com.mparticle.react.NativeMPRoktSpec

class MPRoktModule(
    private val reactContext: ReactApplicationContext,
) : NativeMPRoktSpec(reactContext) {
    private val impl = MPRoktModuleImpl(reactContext)

    override fun getName(): String = impl.getName()

    @ReactMethod
    override fun selectPlacements(
        identifier: String,
        attributes: ReadableMap?,
        placeholders: ReadableArray?,
        roktConfig: ReadableMap?,
        fontFilesMap: ReadableMap?,
    ) {
        if (identifier.isBlank()) {
            Logger.warning("selectPlacements failed. identifier cannot be empty")
            return
        }
        impl.setWrapperSdk()
        MParticle.getInstance()?.rokt?.events(identifier)?.let {
            impl.startRoktEventListener(it, reactContext.currentActivity, identifier)
        }

        val config = roktConfig?.let { impl.buildRoktConfig(it) }
        val attributeMap = impl.readableMapToMapOfStrings(attributes)

        // Rokt SDK 6's selectPlacements clears prior placeholder content via removeAllViews(),
        // which detaches Compose views and must run on the main thread. Resolve the placeholder
        // views and invoke the SDK together on the UI thread, as oldarch's UIManager.addUIBlock does.
        UiThreadUtil.runOnUiThread {
            impl.whenPlaceholdersMounted(identifier, placeholders) {
                MParticle.getInstance()?.rokt?.selectPlacements(
                    identifier = identifier,
                    attributes = attributeMap,
                    embeddedViews = impl.resolvePlaceholders(placeholders),
                    fontTypefaces = null, // TODO
                    config = config,
                )
            }
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
}
