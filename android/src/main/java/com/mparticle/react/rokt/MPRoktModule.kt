package com.mparticle.react.rokt

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.mparticle.MParticle
import com.mparticle.rokt.CacheConfig
import com.mparticle.rokt.RoktConfig

class MPRoktModule(private val reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {

    override fun getName(): String = "MPRokt"

    @ReactMethod
    fun selectPlacements(
        identifier: String,
        attributes: ReadableMap?,
        placeholders: ReadableMap?,
        roktConfig: ReadableMap?,
        fontFilesMap: ReadableMap?,
    ) {
        val finalAttributes = readableMapToMapOfStrings(attributes)
        val config = buildRoktConfig(roktConfig)
        MParticle.getInstance()?.Rokt()?.selectPlacements(
            identifier = identifier,
            attributes = finalAttributes,
            callbacks = null,
            embeddedViews = null, /*TODO*/
            fontTypefaces = null /*TODO*/,
            config = config,
        )
    }

    private fun readableMapToMapOfStrings(attributes: ReadableMap?): Map<String, String> =
        attributes?.toHashMap()?.filter { it.value is String }?.mapValues { it.value as String }
            ?: emptyMap()

    private fun String.toColorMode(): RoktConfig.ColorMode = when (this) {
        "dark" -> RoktConfig.ColorMode.DARK
        "light" -> RoktConfig.ColorMode.LIGHT
        else -> RoktConfig.ColorMode.SYSTEM
    }

    private fun buildRoktConfig(roktConfig: ReadableMap?): RoktConfig {
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

    private fun buildCacheConfig(cacheConfigMap: ReadableMap?): CacheConfig {
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
}