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
     * Resolve placeholders to their RoktEmbeddedView instances. A positive numeric value is a
     * legacy `findNodeHandle` react tag. Zero is the name-lookup sentinel used by the JS wrapper;
     * unresolved tags also fall back to placeholderName.
     * Must be called on the UI thread — it resolves live views.
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
                val taggedView =
                    if (
                        placeholders.getType(key) == ReadableType.Number &&
                        placeholders.getDouble(key) > 0
                    ) {
                        resolveReactTag(placeholders.getDouble(key).toInt())
                    } else {
                        null
                    }
                val view = taggedView ?: RoktPlaceholderRegistry.lookup(key) as? RoktEmbeddedView

                if (view != null) {
                    placeholdersMap[key] = WeakReference(view)
                    Logger.debug("Successfully found Widget for key: $key")
                } else {
                    Logger.warning("Cannot resolve placeholder for key: $key")
                }
            } catch (e: Exception) {
                Logger.warning("Error processing placeholder for key $key: ${e.message}")
            }
        }

        return placeholdersMap
    }

    private fun resolveReactTag(reactTag: Int): RoktEmbeddedView? {
        val uiManager = UIManagerHelper.getUIManagerForReactTag(reactContext, reactTag)
        if (uiManager == null) {
            Logger.warning("UIManager not found for tag: $reactTag")
            return null
        }
        // resolveView throws for a tag that is no longer mounted; the caller falls back to the name.
        val view = runCatching { uiManager.resolveView(reactTag) }.getOrNull()
        if (view !is RoktEmbeddedView) {
            Logger.warning("View with tag $reactTag is not a Widget: ${view?.javaClass?.simpleName}")
            return null
        }
        return view
    }
}
