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
import com.facebook.react.bridge.ReadableType
import com.facebook.react.bridge.WritableMap
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.mparticle.MParticle
import com.mparticle.MpRoktEventCallback
import com.mparticle.RoktEvent
import com.mparticle.UnloadReasons
import com.mparticle.WrapperSdk
import com.mparticle.internal.Logger
import com.mparticle.rokt.CacheConfig
import com.mparticle.rokt.RoktConfig
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch
import java.math.BigDecimal

class MPRoktModuleImpl(
    private val reactContext: ReactApplicationContext,
) {
    init {
        MParticle.getInstance()?.setWrapperSdk(WrapperSdk.WrapperSdkReactNative, "")
    }

    private var roktEventHandler: MpRoktEventCallback? = null

    private val eventSubscriptions = mutableMapOf<String, Job?>()
    private val listeners: MutableMap<Long, MpRoktEventCallback> =
        object : LinkedHashMap<Long, MpRoktEventCallback>() {
            override fun removeEldestEntry(eldest: Map.Entry<Long, MpRoktEventCallback>): Boolean = this.size > MAX_LISTENERS
        }

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
        MParticle.getInstance()?.Rokt()?.purchaseFinalized(placementId, catalogItemId, success)
    }

    fun close(promise: Promise) {
        MParticle.getInstance()?.Rokt()?.close()
        promise.resolve(null)
    }

    fun setSessionId(
        sessionId: String,
        promise: Promise,
    ) {
        MParticle.getInstance()?.Rokt()?.setSessionId(sessionId)
        promise.resolve(null)
    }

    fun getSessionId(promise: Promise) {
        promise.resolve(MParticle.getInstance()?.Rokt()?.getSessionId())
    }

    fun setRoktEventHandler(roktEventHandler: MpRoktEventCallback) {
        this.roktEventHandler = roktEventHandler
    }

    fun createRoktCallback(): MpRoktEventCallback {
        val callback: MpRoktEventCallback =
            object : MpRoktEventCallback {
                override fun onLoad() {
                    sendCallback("onLoad", null)
                }

                override fun onUnload(reason: UnloadReasons) {
                    sendCallback("onUnLoad", reason.toString())
                }

                override fun onShouldShowLoadingIndicator() {
                    sendCallback("onShouldShowLoadingIndicator", null)
                }

                override fun onShouldHideLoadingIndicator() {
                    sendCallback("onShouldHideLoadingIndicator", null)
                }
            }
        listeners[System.currentTimeMillis()] = callback
        return callback
    }

    fun sendCallback(
        eventValue: String,
        reason: String?,
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

    fun readableMapToMapOfStrings(attributes: ReadableMap?): Map<String, String> {
        if (attributes == null) {
            return emptyMap()
        }

        val result = mutableMapOf<String, String>()
        val iterator = attributes.keySetIterator()
        while (iterator.hasNextKey()) {
            val key = iterator.nextKey()
            when (attributes.getType(key)) {
                ReadableType.String -> attributes.getString(key)?.let { result[key] = it }
                ReadableType.Number -> result[key] = formatNumberAttribute(attributes.getDouble(key))
                ReadableType.Boolean ->
                    result[key] = if (attributes.getBoolean(key)) "true" else "false"
                ReadableType.Map ->
                    attributes.getMap(key)?.toHashMap()?.let { result[key] = it.toString() }
                ReadableType.Array ->
                    attributes.getArray(key)?.toArrayList()?.let { result[key] = it.toString() }
                ReadableType.Null -> Unit
            }
        }
        return result
    }

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
                cacheConfigMap.getMap("cacheAttributes")?.toHashMap()?.mapValues { it.value as String }
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
                                    event.placementId
                                }

                                RoktEvent.HideLoadingIndicator -> {
                                    eventName = "HideLoadingIndicator"
                                    null
                                }

                                is RoktEvent.OfferEngagement -> {
                                    eventName = "OfferEngagement"
                                    event.placementId
                                }

                                is RoktEvent.PlacementClosed -> {
                                    eventName = "PlacementClosed"
                                    event.placementId
                                }

                                is RoktEvent.PlacementCompleted -> {
                                    eventName = "PlacementCompleted"
                                    event.placementId
                                }

                                is RoktEvent.PlacementFailure -> {
                                    eventName = "PlacementFailure"
                                    event.placementId
                                }

                                is RoktEvent.PlacementInteractive -> {
                                    eventName = "PlacementInteractive"
                                    event.placementId
                                }

                                is RoktEvent.PlacementReady -> {
                                    eventName = "PlacementReady"
                                    event.placementId
                                }

                                is RoktEvent.PositiveEngagement -> {
                                    eventName = "PositiveEngagement"
                                    event.placementId
                                }

                                RoktEvent.ShowLoadingIndicator -> {
                                    eventName = "ShowLoadingIndicator"
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
                                    event.placementId
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
                                    event.placementId
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
        const val MAX_LISTENERS = 5
        const val MODULE_NAME = "RNMPRokt"

        // Match iOS NSNumber stringValue: plain decimals, no trailing ".0", no scientific notation.
        internal fun formatNumberAttribute(value: Double): String {
            if (value.isNaN() || value.isInfinite()) {
                return value.toString()
            }
            val longValue = value.toLong()
            if (value == longValue.toDouble()) {
                return longValue.toString()
            }
            return BigDecimal.valueOf(value).stripTrailingZeros().toPlainString()
        }
    }
}
