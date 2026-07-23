package com.mparticle.react.rokt

import android.app.Activity
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.UiThreadUtil
import com.facebook.react.bridge.WritableMap
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.mparticle.MParticle
import com.mparticle.WrapperSdk
import com.mparticle.internal.Logger
import com.mparticle.kits.rokt
import com.rokt.roktsdk.CacheConfig
import com.rokt.roktsdk.RoktConfig
import com.rokt.roktsdk.RoktEvent
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch

class MPRoktModuleImpl(
    private val reactContext: ReactApplicationContext,
) {
    init {
        MParticle.getInstance()?.setWrapperSdk(WrapperSdk.WrapperSdkReactNative, "")
    }

    private val eventSubscriptions = mutableMapOf<String, Job?>()

    fun getName(): String = MODULE_NAME

    fun selectShoppableAds(
        identifier: String,
        attributes: ReadableMap?,
        roktConfig: ReadableMap?,
    ) {
        Logger.warning("selectShoppableAds is not yet supported on Android")
    }

    fun purchaseFinalized(
        placementId: String,
        catalogItemId: String,
        success: Boolean,
    ) {
        MParticle.getInstance()?.rokt?.purchaseFinalized(placementId, catalogItemId, success)
    }

    fun close(promise: Promise) {
        // rokt.close() dismisses/detaches Compose overlay views, which must happen on the main thread.
        UiThreadUtil.runOnUiThread {
            MParticle.getInstance()?.rokt?.close()
            promise.resolve(null)
        }
    }

    fun setSessionId(
        sessionId: String,
        promise: Promise,
    ) {
        MParticle.getInstance()?.rokt?.setSessionId(sessionId)
        promise.resolve(null)
    }

    fun getSessionId(promise: Promise) {
        promise.resolve(MParticle.getInstance()?.rokt?.getSessionId())
    }

    fun sendCallback(
        eventValue: String,
        reason: String? = null,
    ) {
        val params = Arguments.createMap()
        params.putString("callbackValue", eventValue)
        if (reason != null) {
            params.putString("reason", reason)
        }
        sendEvent(reactContext, "RoktCallback", params)
    }

    fun sendEvent(
        reactContext: ReactContext?,
        eventName: String,
        params: WritableMap?,
    ) {
        reactContext?.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)?.emit(eventName, params)
    }

    fun readableMapToMapOfStrings(attributes: ReadableMap?): Map<String, String> =
        attributes?.toHashMap()?.filter { it.value is String }?.mapValues { it.value as String }
            ?: emptyMap()

    fun String.toColorMode(): RoktConfig.ColorMode =
        when (this) {
            "dark" -> RoktConfig.ColorMode.DARK
            "light" -> RoktConfig.ColorMode.LIGHT
            else -> RoktConfig.ColorMode.SYSTEM
        }

    fun buildRoktConfig(roktConfig: ReadableMap?): RoktConfig {
        val builder = RoktConfig.Builder()
        val configMap: Map<String, String> = readableMapToMapOfStrings(roktConfig)
        configMap["colorMode"]?.let {
            builder.colorMode(it.toColorMode())
        }
        roktConfig?.getMap("cacheConfig")?.let {
            builder.cacheConfig(buildCacheConfig(it))
        }
        return builder.build()
    }

    fun buildCacheConfig(cacheConfigMap: ReadableMap?): CacheConfig {
        val cacheDurationInSeconds =
            if (cacheConfigMap?.hasKey("cacheDurationInSeconds") == true) {
                cacheConfigMap.getDouble("cacheDurationInSeconds").toLong()
            } else {
                0L
            }
        val cacheAttributes =
            if (cacheConfigMap?.hasKey("cacheAttributes") == true) {
                cacheConfigMap
                    .getMap("cacheAttributes")
                    ?.toHashMap()
                    ?.mapNotNull { (key, value) -> (value as? String)?.let { key to it } }
                    ?.toMap()
            } else {
                null
            }
        return CacheConfig(
            cacheDurationInSeconds = cacheDurationInSeconds,
            cacheAttributes = cacheAttributes,
        )
    }

    fun startRoktEventListener(
        flow: Flow<RoktEvent>,
        currentActivity: Activity?,
        viewName: String? = null,
    ) {
        val activeJob = eventSubscriptions[viewName.orEmpty()]?.takeIf { it.isActive }
        if (activeJob != null) {
            return
        }
        val job =
            (currentActivity as? LifecycleOwner)?.lifecycleScope?.launch {
                (currentActivity as LifecycleOwner).repeatOnLifecycle(Lifecycle.State.CREATED) {
                    flow.collect { event ->
                        val params = Arguments.createMap()
                        var eventName: String
                        val placementId: String? =
                            when (event) {
                                is RoktEvent.FirstPositiveEngagement -> {
                                    eventName = "FirstPositiveEngagement"
                                    event.identifier
                                }

                                RoktEvent.HideLoadingIndicator -> {
                                    eventName = "HideLoadingIndicator"
                                    sendCallback("onShouldHideLoadingIndicator")
                                    null
                                }

                                is RoktEvent.OfferEngagement -> {
                                    eventName = "OfferEngagement"
                                    event.identifier
                                }

                                is RoktEvent.PlacementClosed -> {
                                    eventName = "PlacementClosed"
                                    sendCallback("onUnLoad")
                                    event.identifier
                                }

                                is RoktEvent.PlacementCompleted -> {
                                    eventName = "PlacementCompleted"
                                    event.identifier
                                }

                                is RoktEvent.PlacementFailure -> {
                                    eventName = "PlacementFailure"
                                    event.identifier
                                }

                                is RoktEvent.PlacementInteractive -> {
                                    eventName = "PlacementInteractive"
                                    event.identifier
                                }

                                is RoktEvent.PlacementReady -> {
                                    eventName = "PlacementReady"
                                    sendCallback("onLoad")
                                    event.identifier
                                }

                                is RoktEvent.PositiveEngagement -> {
                                    eventName = "PositiveEngagement"
                                    event.identifier
                                }

                                RoktEvent.ShowLoadingIndicator -> {
                                    eventName = "ShowLoadingIndicator"
                                    sendCallback("onShouldShowLoadingIndicator")
                                    null
                                }

                                is RoktEvent.InitComplete -> {
                                    eventName = "InitComplete"
                                    params.putString("status", event.success.toString())
                                    null
                                }

                                is RoktEvent.OpenUrl -> {
                                    eventName = "OpenUrl"
                                    params.putString("url", event.url)
                                    event.identifier
                                }

                                is RoktEvent.CartItemInstantPurchase -> {
                                    eventName = "CartItemInstantPurchase"
                                    params.putString("cartItemId", event.cartItemId)
                                    params.putString("catalogItemId", event.catalogItemId)
                                    params.putString("currency", event.currency)
                                    params.putString("description", event.description)
                                    params.putString("linkedProductId", event.linkedProductId)
                                    params.putDouble("totalPrice", event.totalPrice)
                                    params.putInt("quantity", event.quantity)
                                    params.putDouble("unitPrice", event.unitPrice)
                                    event.identifier
                                }

                                else -> {
                                    eventName = "Unknown"
                                    null
                                }
                            }

                        placementId?.let { params.putString("placementId", it) }
                        params.putString("event", eventName)
                        viewName?.let { params.putString("viewName", it) }
                        sendEvent(reactContext, "RoktEvents", params)
                    }
                }
            }
        eventSubscriptions[viewName.orEmpty()] = job
    }

    companion object {
        const val MODULE_NAME = "RNMPRokt"
    }
}
