package com.mparticle.react.rokt

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.ReadableType
import com.facebook.react.bridge.UiThreadUtil
import com.facebook.react.uimanager.UIManagerHelper
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
        MParticle.getInstance()?.rokt?.events(identifier)?.let {
            impl.startRoktEventListener(it, reactContext.currentActivity, identifier)
        }

        val config = roktConfig?.let { impl.buildRoktConfig(it) }
        val attributeMap = impl.readableMapToMapOfStrings(attributes)

        // Rokt SDK 6's selectPlacements clears prior placeholder content via removeAllViews(),
        // which detaches Compose views and must run on the main thread. Resolve the placeholder
        // views and invoke the SDK together on the UI thread. (oldarch uses UIManager.addUIBlock;
        // iOS uses the uiManager methodQueue — same intent.)
        UiThreadUtil.runOnUiThread {
            MParticle.getInstance()?.rokt?.selectPlacements(
                identifier = identifier,
                attributes = attributeMap,
                embeddedViews = resolvePlaceholders(placeholders),
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

    /**
     * Resolve placeholders from a ReadableMap of react tags to their RoktEmbeddedView instances.
     * Must be called on the UI thread — it resolves live views via the UIManager.
     */
    private fun resolvePlaceholders(placeholders: ReadableMap?): Map<String, WeakReference<RoktEmbeddedView>> {
        val placeholdersMap = HashMap<String, WeakReference<RoktEmbeddedView>>()
        if (placeholders == null) {
            return placeholdersMap
        }

        val iterator = placeholders.keySetIterator()
        while (iterator.hasNextKey()) {
            val key = iterator.nextKey()
            try {
                val reactTag =
                    when {
                        placeholders.getType(key) == ReadableType.Number -> {
                            placeholders.getDouble(key).toInt()
                        }

                        else -> {
                            Logger.warning("Invalid view tag for key: $key")
                            continue
                        }
                    }

                val uiManager = UIManagerHelper.getUIManagerForReactTag(reactContext, reactTag)
                if (uiManager == null) {
                    Logger.warning("UIManager not found for tag: $reactTag")
                    continue
                }

                val view = uiManager.resolveView(reactTag)
                if (view is RoktEmbeddedView) {
                    placeholdersMap[key] = WeakReference(view)
                    Logger.debug("Successfully found Widget for key: $key with tag: $reactTag")
                } else {
                    Logger.warning("View with tag $reactTag is not a Widget: ${view?.javaClass?.simpleName}")
                }
            } catch (e: Exception) {
                Logger.warning("Error processing placeholder for key $key: ${e.message}")
            }
        }

        return placeholdersMap
    }
}
