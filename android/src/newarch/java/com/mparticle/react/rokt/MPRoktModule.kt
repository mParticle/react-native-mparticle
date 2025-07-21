package com.mparticle.react.rokt

import android.util.Log
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.ReadableType
import com.facebook.react.bridge.UiThreadUtil
import com.facebook.react.uimanager.UIManagerHelper
import com.mparticle.MParticle
import com.mparticle.WrapperSdk
import com.mparticle.react.NativeMPRoktSpec
import com.mparticle.rokt.RoktEmbeddedView
import java.lang.ref.WeakReference
import java.util.concurrent.CountDownLatch

class MPRoktModule(
    private val reactContext: ReactApplicationContext,
) : NativeMPRoktSpec(reactContext) {
    init {
        MParticle.getInstance()?.setWrapperSdk(WrapperSdk.WrapperSdkReactNative, "")
    }

    companion object {
        private const val TAG = "MPRoktModule"
    }

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
            Log.w(TAG, "selectPlacements failed. identifier cannot be empty")
            return
        }
        MParticle.getInstance()?.Rokt()?.events(identifier)?.let {
            impl.startRoktEventListener(it, reactContext.currentActivity, identifier)
        }

        // Process placeholders for Fabric
        val placeholdersMap = processPlaceholders(placeholders)
        val config = roktConfig?.let { impl.buildRoktConfig(it) }

        MParticle.getInstance()?.Rokt()?.selectPlacements(
            identifier = identifier,
            attributes = impl.readableMapToMapOfStrings(attributes),
            callbacks = impl.createRoktCallback(),
            embeddedViews = placeholdersMap,
            fontTypefaces = null, // TODO
            config = config,
        )
    }


    /**
     * Process placeholders from ReadableMap to a map of Widgets for use with Rokt.
     * This method handles the Fabric-specific view resolution.
     */
    private fun processPlaceholders(placeholders: ReadableMap?): Map<String, WeakReference<RoktEmbeddedView>> {
        val placeholdersMap = HashMap<String, WeakReference<RoktEmbeddedView>>()

        if (placeholders != null) {
            // Use CountDownLatch to wait for UI thread processing
            val latch = CountDownLatch(1)

            // Run view resolution on UI thread
            UiThreadUtil.runOnUiThread {
                try {
                    val iterator = placeholders.keySetIterator()
                    while (iterator.hasNextKey()) {
                        val key = iterator.nextKey()
                        try {
                            // Get the tag value as an integer
                            val reactTag =
                                when {
                                    placeholders.getType(key) == ReadableType.Number ->
                                        placeholders.getDouble(key).toInt()

                                    else -> {
                                        Log.w(TAG, "Invalid view tag for key: $key")
                                        continue
                                    }
                                }

                            // Get the UIManager for this specific tag
                            val uiManager =
                                UIManagerHelper.getUIManagerForReactTag(reactContext, reactTag)
                            if (uiManager == null) {
                                Log.w(TAG, "UIManager not found for tag: $reactTag")
                                continue
                            }

                            // Resolve the view using the manager (now on UI thread)
                            val view = uiManager.resolveView(reactTag)
                            if (view is RoktEmbeddedView) {
                                placeholdersMap[key] = WeakReference(view)
                                Log.d(TAG, "Successfully found Widget for key: $key with tag: $reactTag")
                            } else {
                                Log.w(TAG, "View with tag $reactTag is not a Widget: ${view?.javaClass?.simpleName}")
                            }
                        } catch (e: Exception) {
                            Log.w(TAG, "Error processing placeholder for key $key: ${e.message}")
                            e.printStackTrace()
                        }
                    }
                } finally {
                    latch.countDown()
                }
            }

            try {
                // Wait for UI thread to finish processing
                latch.await()
            } catch (e: InterruptedException) {
                Log.w(TAG, "Interrupted while waiting for UI thread: ${e.message}")
            }
        }

        return placeholdersMap
    }
}
