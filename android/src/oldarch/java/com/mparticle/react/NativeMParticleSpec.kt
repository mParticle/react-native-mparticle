package com.mparticle.react

import com.facebook.react.bridge.Callback
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap

abstract class NativeMParticleSpec(
    reactContext: ReactApplicationContext,
) : ReactContextBaseJavaModule(reactContext) {
    companion object {
        private const val MODULE_NAME = "RNMParticle"
    }

    override fun getName(): String = MODULE_NAME

    abstract fun upload()

    abstract fun setUploadInterval(uploadInterval: Double)

    abstract fun logEvent(
        eventName: String,
        eventType: Double,
        attributes: ReadableMap?,
    )

    abstract fun logMPEvent(event: ReadableMap?)

    abstract fun logCommerceEvent(commerceEvent: ReadableMap?)

    abstract fun logScreenEvent(
        screenName: String,
        attributes: ReadableMap?,
        shouldUploadEvent: Boolean,
    )

    abstract fun setATTStatus(status: Double)

    abstract fun setATTStatusWithCustomTimestamp(
        status: Double,
        timestamp: Double,
    )

    abstract fun setOptOut(optOut: Boolean)

    abstract fun getOptOut(callback: Callback)

    abstract fun addGDPRConsentState(
        consent: ReadableMap?,
        purpose: String,
    )

    abstract fun removeGDPRConsentStateWithPurpose(purpose: String)

    abstract fun setCCPAConsentState(consent: ReadableMap?)

    abstract fun removeCCPAConsentState()

    abstract fun isKitActive(
        kitId: Double,
        callback: Callback,
    )

    abstract fun getAttributions(callback: Callback)

    abstract fun logPushRegistration(
        token: String?,
        senderId: String?,
    )

    abstract fun getSession(callback: Callback)

    abstract fun setLocation(
        latitude: Double,
        longitude: Double,
    )

    abstract fun setUserAttribute(
        mpid: String,
        key: String,
        value: String,
    )

    abstract fun setUserAttributeArray(
        mpid: String,
        key: String,
        value: ReadableArray?,
    )

    abstract fun getUserAttributes(
        mpid: String,
        callback: Callback,
    )

    abstract fun setUserTag(
        mpid: String,
        tag: String,
    )

    abstract fun incrementUserAttribute(
        mpid: String,
        key: String,
        value: Double,
    )

    abstract fun removeUserAttribute(
        mpid: String,
        key: String,
    )

    abstract fun getUserIdentities(
        mpid: String,
        callback: Callback,
    )

    abstract fun getFirstSeen(
        mpid: String,
        callback: Callback,
    )

    abstract fun getLastSeen(
        mpid: String,
        callback: Callback,
    )

    abstract fun getCurrentUserWithCompletion(callback: Callback)

    abstract fun identify(
        identityRequest: ReadableMap?,
        callback: Callback,
    )

    abstract fun login(
        identityRequest: ReadableMap?,
        callback: Callback,
    )

    abstract fun logout(
        identityRequest: ReadableMap?,
        callback: Callback,
    )

    abstract fun modify(
        identityRequest: ReadableMap?,
        callback: Callback,
    )

    abstract fun aliasUsers(
        aliasRequest: ReadableMap?,
        callback: Callback,
    )
}
