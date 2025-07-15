package com.mparticle.react

import android.location.Location
import android.util.Log
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Callback
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.ReadableType
import com.facebook.react.bridge.WritableMap
import com.facebook.react.bridge.WritableNativeArray
import com.facebook.react.bridge.WritableNativeMap
import com.mparticle.MPEvent
import com.mparticle.MParticle
import com.mparticle.UserAttributeListener
import com.mparticle.commerce.CommerceEvent
import com.mparticle.commerce.Impression
import com.mparticle.commerce.Product
import com.mparticle.commerce.Promotion
import com.mparticle.commerce.TransactionAttributes
import com.mparticle.consent.CCPAConsent
import com.mparticle.consent.ConsentState
import com.mparticle.consent.GDPRConsent
import com.mparticle.identity.AliasRequest
import com.mparticle.identity.IdentityApiRequest
import com.mparticle.identity.IdentityHttpResponse
import com.mparticle.identity.MParticleUser
import com.mparticle.internal.Logger

class MParticleModule(private val reactContext: ReactApplicationContext) :
    NativeMParticleSpec(reactContext) {

    companion object {
        const val MODULE_NAME = "MParticle"
        private const val LOG_TAG = "MParticleModule"
    }

    override fun getName(): String = MODULE_NAME

    @ReactMethod
    override fun upload() {
        MParticle.getInstance()?.upload()
    }

    @ReactMethod
    override fun setUploadInterval(uploadInterval: Double) {
        MParticle.getInstance()?.setUpdateInterval(uploadInterval.toInt())
    }

    @ReactMethod
    override fun setLocation(latitude: Double, longitude: Double) {
        val newLocation = Location("").apply {
            setLatitude(latitude)
            setLongitude(longitude)
        }
        MParticle.getInstance()?.setLocation(newLocation)
    }

    @ReactMethod
    override fun logEvent(eventName: String, eventType: Double, attributes: ReadableMap?) {
        val attributes = convertStringMap(attributes)
        val eventType = convertEventType(eventType.toInt())

        val event = MPEvent.Builder(name, eventType)
            .customAttributes(attributes)
            .build()
        MParticle.getInstance()?.logEvent(event)
    }

    @ReactMethod
    override fun logMPEvent(event: ReadableMap?) {
        val convertedEvent = convertMPEvent(event)
        if (convertedEvent != null) {
            MParticle.getInstance()?.logEvent(convertedEvent)
        }
    }

    @ReactMethod
    override fun logCommerceEvent(commerceEvent: ReadableMap?) {
        commerceEvent?.let {
            val convertedCommerceEvent = convertCommerceEvent(it)
            if (convertedCommerceEvent != null) {
                MParticle.getInstance()?.logEvent(convertedCommerceEvent)
            }
        }
    }

    @ReactMethod
    override fun logScreenEvent(screenName: String, attributes: ReadableMap?, shouldUploadEvent: Boolean) {
        val convertedAttributes = convertStringMap(attributes)
        MParticle.getInstance()?.logScreen(screenName, convertedAttributes, shouldUploadEvent)
    }

    override fun setATTStatus(status: Double) {
        // Not implemented
    }

    override fun setATTStatusWithCustomTimestamp(status: Double, timestamp: Double) {
        // Not implemented
    }

    @ReactMethod
    override fun setUserAttribute(mpid: String, key: String, value: String) {
        val selectedUser = MParticle.getInstance()?.Identity()?.getUser(parseMpid(mpid))
        selectedUser?.setUserAttribute(key, value)
    }

    @ReactMethod
    override fun setUserAttributeArray(mpid: String, key: String, value: ReadableArray?) {
        value?.let {
            val list = mutableListOf<String>()
            for (i in 0 until it.size()) {
                list.add(it.getString(i))
            }

            val selectedUser = MParticle.getInstance()?.Identity()?.getUser(parseMpid(mpid))
            selectedUser?.setUserAttributeList(key, list)
        }
    }

    @ReactMethod
    override fun getUserAttributes(mpid: String, callback: Callback) {
        val selectedUser = MParticle.getInstance()?.Identity()?.getUser(parseMpid(mpid))
        if (selectedUser != null) {
            selectedUser.getUserAttributes(object : UserAttributeListener {
                override fun onUserAttributesReceived(
                    userAttributes: Map<String, String>?,
                    userAttributeLists: Map<String, List<String>>?,
                    mpid: Long?
                ) {
                    val resultMap = WritableNativeMap()
                    userAttributes?.forEach { (key, value) ->
                        resultMap.putString(key, value)
                    }
                    userAttributeLists?.forEach { (key, valueList) ->
                        val resultArray = WritableNativeArray()
                        valueList.forEach { arrayVal ->
                            resultArray.pushString(arrayVal)
                        }
                        resultMap.putArray(key, resultArray)
                    }
                    callback.invoke(null, resultMap)
                }
            })
        } else {
            callback.invoke()
        }
    }

    @ReactMethod
    override fun setUserTag(mpid: String, tag: String) {
        val selectedUser = MParticle.getInstance()?.Identity()?.getUser(parseMpid(mpid))
        selectedUser?.setUserTag(tag)
    }

    @ReactMethod
    override fun removeUserAttribute(mpid: String, key: String) {
        val selectedUser = MParticle.getInstance()?.Identity()?.getUser(parseMpid(mpid))
        selectedUser?.removeUserAttribute(key)
    }

    @ReactMethod
    override fun incrementUserAttribute(mpid: String, key: String, value: Double) {
        val selectedUser = MParticle.getInstance()?.Identity()?.getUser(parseMpid(mpid))
        selectedUser?.incrementUserAttribute(key, value)
    }

    @ReactMethod
    override fun identify(identityRequest: ReadableMap?, callback: Callback) {
        val request = convertIdentityAPIRequest(identityRequest)

        MParticle.getInstance()?.Identity()?.identify(request)
            ?.addFailureListener { identityHttpResponse ->
                callback.invoke(convertIdentityHttpResponse(identityHttpResponse), null)
            }
            ?.addSuccessListener { identityApiResult ->
                val user = identityApiResult.user
                val userID = user.id.toString()
                callback.invoke(null, userID)
            }
    }

    @ReactMethod
    override fun login(identityRequest: ReadableMap?, callback: Callback) {
        val request = convertIdentityAPIRequest(identityRequest)

        MParticle.getInstance()?.Identity()?.login(request)
            ?.addFailureListener { identityHttpResponse ->
                callback.invoke(convertIdentityHttpResponse(identityHttpResponse), null)
            }
            ?.addSuccessListener { identityApiResult ->
                val user = identityApiResult.user
                val userId = user.id.toString()
                val previousUser = identityApiResult.previousUser
                val previousUserId = previousUser?.id?.toString()
                callback.invoke(null, userId, previousUserId)
            }
    }

    @ReactMethod
    override fun logout(identityRequest: ReadableMap?, callback: Callback) {
        val request = convertIdentityAPIRequest(identityRequest)

        MParticle.getInstance()?.Identity()?.logout(request)
            ?.addFailureListener { identityHttpResponse ->
                callback.invoke(convertIdentityHttpResponse(identityHttpResponse), null)
            }
            ?.addSuccessListener { identityApiResult ->
                val user = identityApiResult.user
                val userID = user.id.toString()
                callback.invoke(null, userID)
            }
    }

    @ReactMethod
    override fun modify(identityRequest: ReadableMap?, callback: Callback) {
        val request = convertIdentityAPIRequest(identityRequest)

        MParticle.getInstance()?.Identity()?.modify(request)
            ?.addFailureListener { identityHttpResponse ->
                callback.invoke(convertIdentityHttpResponse(identityHttpResponse), null)
            }
            ?.addSuccessListener { identityApiResult ->
                val user = identityApiResult.user
                val userID = user.id.toString()
                callback.invoke(null, userID)
            }
    }

    @ReactMethod
    override fun getCurrentUserWithCompletion(callback: Callback) {
        val currentUser = MParticle.getInstance()?.Identity()?.currentUser
        if (currentUser != null) {
            val userID = currentUser.id.toString()
            callback.invoke(null, userID)
        } else {
            callback.invoke(null, null)
        }
    }

    @ReactMethod
    override fun aliasUsers(aliasRequest: ReadableMap?, callback: Callback) {
        val identityApi = MParticle.getInstance()?.Identity()
        if (identityApi == null || aliasRequest == null) {
            callback.invoke(false, "MParticle not initialized")
            return
        }

        val iterator = aliasRequest.keySetIterator()
        var destinationMpid: Long? = null
        var sourceMpid: Long? = null
        var startTime: Long? = null
        var endTime: Long? = null

        while (iterator.hasNextKey()) {
            try {
                when (val key = iterator.nextKey()) {
                    "destinationMpid" -> destinationMpid =
                        Utils.getLong(aliasRequest, "destinationMpid", false)

                    "sourceMpid" -> sourceMpid = Utils.getLong(aliasRequest, "sourceMpid", false)
                    "startTime" -> startTime = Utils.getLong(aliasRequest, "startTime", true)
                    "endTime" -> endTime = Utils.getLong(aliasRequest, "endTime", true)
                }
            } catch (ex: NumberFormatException) {
                Logger.error(ex.message)
                callback.invoke(false, ex.message)
                return
            }
        }

        if (startTime == null && endTime == null) {
            var sourceUser: MParticleUser? = null
            var destinationUser: MParticleUser? = null
            sourceMpid?.let { sourceUser = identityApi.getUser(it) }
            destinationMpid?.let { destinationUser = identityApi.getUser(it) }

            if (sourceUser != null && destinationUser != null) {
                val request = AliasRequest.builder(sourceUser!!, destinationUser!!).build()
                val success = MParticle.getInstance()?.Identity()?.aliasUsers(request) ?: false
                callback.invoke(success)
            } else {
                callback.invoke(
                    false,
                    "MParticleUser could not be found for provided sourceMpid and destinationMpid"
                )
            }
        } else {
            val request = AliasRequest.builder()
                .destinationMpid(destinationMpid ?: 0)
                .sourceMpid(sourceMpid ?: 0)
                .startTime(startTime ?: 0)
                .endTime(endTime ?: 0)
                .build()
            val success = identityApi.aliasUsers(request)
            callback.invoke(success)
        }
    }

    @ReactMethod
    override fun getSession(callback: Callback) {
        val session = MParticle.getInstance()?.currentSession
        if (session != null) {
            val sessionId = session.sessionUUID
            callback.invoke(sessionId)
        } else {
            callback.invoke()
        }
    }

    @ReactMethod
    override fun getUserIdentities(mpid: String, callback: Callback) {
        val selectedUser = MParticle.getInstance()?.Identity()?.getUser(parseMpid(mpid))
        if (selectedUser != null) {
            callback.invoke(null, convertToUserIdentities(selectedUser.userIdentities))
        } else {
            callback.invoke()
        }
    }

    @ReactMethod
    override fun getFirstSeen(mpid: String, callback: Callback) {
        val selectedUser = MParticle.getInstance()?.Identity()?.getUser(Utils.parseMpid(mpid))
        if (selectedUser != null) {
            callback.invoke(selectedUser.firstSeenTime.toString())
        } else {
            callback.invoke()
        }
    }

    @ReactMethod
    override fun getLastSeen(mpid: String, callback: Callback) {
        val selectedUser = MParticle.getInstance()?.Identity()?.getUser(Utils.parseMpid(mpid))
        if (selectedUser != null) {
            callback.invoke(selectedUser.lastSeenTime.toString())
        } else {
            callback.invoke()
        }
    }

    @ReactMethod
    override fun getAttributions(callback: Callback) {
        val attributionResultMap = MParticle.getInstance()?.attributionResults
        val map = Arguments.createMap()
        attributionResultMap?.forEach { (key, attribution) ->
            val attributeMap = Arguments.createMap()
            attribution?.let {
                attributeMap.putInt("kitId", it.serviceProviderId)
                it.link?.let { link -> attributeMap.putString("link", link) }
                it.parameters?.let { params ->
                    attributeMap.putString(
                        "linkParameters",
                        params.toString()
                    )
                }
            }
            map.putMap(key.toString(), attributeMap)
        }
        callback.invoke(map)
    }

    @ReactMethod
    override fun setOptOut(optOut: Boolean) {
        MParticle.getInstance()?.setOptOut(optOut)
    }

    @ReactMethod
    override fun getOptOut(callback: Callback) {
        val optedOut = MParticle.getInstance()?.optOut ?: false
        callback.invoke(optedOut)
    }

    @ReactMethod
    override fun isKitActive(kitId: Double, callback: Callback) {
        val isActive = MParticle.getInstance()?.isKitActive(kitId.toInt()) ?: false
        callback.invoke(isActive)
    }

    @ReactMethod
    override fun logPushRegistration(token: String?, senderId: String?) {
        if (!token.isNullOrEmpty() && !senderId.isNullOrEmpty()) {
            MParticle.getInstance()?.logPushRegistration(token, senderId)
        }
    }

    @ReactMethod
    override fun addGDPRConsentState(consent: ReadableMap?, purpose: String) {
        val currentUser = MParticle.getInstance()?.Identity()?.currentUser
        if (currentUser != null && consent != null) {
            val gDPRConsent = convertToGDPRConsent(consent)
            if (gDPRConsent != null) {
                val consentState = ConsentState.withConsentState(currentUser.consentState)
                    .addGDPRConsentState(purpose, gDPRConsent)
                    .build()
                currentUser.setConsentState(consentState)
                Logger.info("GDPRConsentState added, \n\t\"purpose\": $purpose\n$consentState")
            } else {
                Logger.warning("GDPRConsentState was not able to be deserialized, will not be added")
            }
        }
    }

    @ReactMethod
    override fun removeGDPRConsentStateWithPurpose(purpose: String) {
        val currentUser = MParticle.getInstance()?.Identity()?.currentUser
        if (currentUser != null) {
            val consentState = ConsentState.withConsentState(currentUser.consentState)
                .removeGDPRConsentState(purpose)
                .build()
            currentUser.setConsentState(consentState)
        }
    }

    @ReactMethod
    override fun setCCPAConsentState(consent: ReadableMap?) {
        val currentUser = MParticle.getInstance()?.Identity()?.currentUser
        if (currentUser != null && consent != null) {
            val cCPAConsent = convertToCCPAConsent(consent)
            if (cCPAConsent != null) {
                val consentState = ConsentState.withConsentState(currentUser.consentState)
                    .setCCPAConsentState(cCPAConsent)
                    .build()
                currentUser.setConsentState(consentState)
                Logger.info("CCPAConsentState added, \n$consentState")
            } else {
                Logger.warning("CCPAConsentState was not able to be deserialized, will not be added")
            }
        }
    }

    @ReactMethod
    override fun removeCCPAConsentState() {
        val currentUser = MParticle.getInstance()?.Identity()?.currentUser
        if (currentUser != null) {
            val consentState = ConsentState.withConsentState(currentUser.consentState)
                .removeCCPAConsentState()
                .build()
            currentUser.setConsentState(consentState)
        }
    }

    protected fun getWritableMap(): WritableMap = WritableNativeMap()

    private fun convertIdentityAPIRequest(map: ReadableMap?): IdentityApiRequest {
        val identityRequest = IdentityApiRequest.withEmptyUser()
        val userIdentities = convertUserIdentities(map)
        identityRequest.userIdentities(userIdentities)
        return identityRequest.build()
    }

    private fun convertMPEvent(map: ReadableMap?): MPEvent? {
        if (map?.hasKey("name") == true && map.hasKey("type")) {
            val name = map.getString("name") ?: return null
            val type = map.getInt("type")
            val builder = MPEvent.Builder(name, convertEventType(type))

            if (map.hasKey("category")) {
                map.getString("category")?.let { builder.category(it) }
            }

            if (map.hasKey("duration")) {
                builder.duration(map.getDouble("duration"))
            }

            if (map.hasKey("info")) {
                val customInfoMap = map.getMap("info")
                val customInfo = convertStringMap(customInfoMap)
                builder.customAttributes(customInfo)
            }

            if (map.hasKey("customFlags")) {
                val customFlagsMap = map.getMap("customFlags")
                val customFlags = convertStringMap(customFlagsMap)
                customFlags?.forEach { (key, value) ->
                    builder.addCustomFlag(key, value)
                }
            }

            if (map.hasKey("shouldUploadEvent")) {
                builder.shouldUploadEvent(map.getBoolean("shouldUploadEvent"))
            }

            return builder.build()
        }
        return null
    }

    private fun convertIdentityHttpResponse(response: IdentityHttpResponse?): ReadableMap {
        val map = Arguments.createMap()
        map.putInt("httpCode", response?.httpCode ?: 0)
        if (response?.mpId != 0L) {
            map.putString("mpid", response?.mpId.toString())
        }
        val stringBuilder = StringBuilder()
        response?.errors?.forEach { error ->
            error?.let {
                stringBuilder.append("Code: ${it.code}\n")
                stringBuilder.append("Message: ${it.message}\n")
            }
        }
        map.putString("errors", stringBuilder.toString())
        return map
    }

    private fun convertCommerceEvent(map: ReadableMap): CommerceEvent? {
        val isProductAction = map.hasKey("productActionType")
        val isPromotion = map.hasKey("promotionActionType")
        val isImpression = map.hasKey("impressions")

        if (!isProductAction && !isPromotion && !isImpression) {
            Log.e(LOG_TAG, "Invalid commerce event: $map")
            return null
        }

        val builder = when {
            isProductAction -> {
                val productActionInt = map.getInt("productActionType")
                val productAction = convertProductActionType(productActionInt)
                val productsArray = map.getArray("products") ?: return null
                val productMap = productsArray.getMap(0)
                val product = convertProduct(productMap) ?: return null
                val transactionAttributesMap = map.getMap("transactionAttributes")
                val transactionAttributes = convertTransactionAttributes(transactionAttributesMap)
                val builder =
                    transactionAttributes?.let {
                        CommerceEvent.Builder(productAction, product).transactionAttributes(it)
                    }

                for (i in 1 until productsArray.size()) {
                    val nextProductMap = productsArray.getMap(i)
                    val nextProduct = convertProduct(nextProductMap)
                    if (nextProduct != null) {
                        builder?.addProduct(nextProduct)
                    }
                }
                builder
            }

            isPromotion -> {
                val promotionActionTypeInt = map.getInt("promotionActionType")
                val promotionAction = convertPromotionActionType(promotionActionTypeInt)
                val promotionsReadableArray = map.getArray("promotions") ?: return null
                val promotionMap = promotionsReadableArray.getMap(0)
                val promotion = convertPromotion(promotionMap) ?: return null
                val builder = CommerceEvent.Builder(promotionAction, promotion)

                for (i in 1 until promotionsReadableArray.size()) {
                    val nextPromotionMap = promotionsReadableArray.getMap(i)
                    val nextPromotion = convertPromotion(nextPromotionMap)
                    if (nextPromotion != null) {
                        builder.addPromotion(nextPromotion)
                    }
                }
                builder
            }

            else -> {
                val impressionsArray = map.getArray("impressions") ?: return null
                val impressionMap = impressionsArray.getMap(0)
                val impression = convertImpression(impressionMap) ?: return null
                val builder = CommerceEvent.Builder(impression)

                for (i in 1 until impressionsArray.size()) {
                    val nextImpressionMap = impressionsArray.getMap(i)
                    val nextImpression = convertImpression(nextImpressionMap)
                    if (nextImpression != null) {
                        builder.addImpression(nextImpression)
                    }
                }
                builder
            }
        }

        if (map.hasKey("shouldUploadEvent")) {
            builder?.shouldUploadEvent(map.getBoolean("shouldUploadEvent"))
        }
        if (map.hasKey("customAttributes")) {
            builder?.customAttributes(convertStringMap(map.getMap("customAttributes")))
        }
        if (map.hasKey("currency")) {
            map.getString("currency")?.let { builder?.currency(it) }
        }
        if (map.hasKey("checkoutStep")) {
            builder?.checkoutStep(map.getInt("checkoutStep"))
        }
        if (map.hasKey("checkoutOptions")) {
            map.getString("checkoutOptions")?.let { builder?.checkoutOptions(it) }
        }

        return builder?.build()
    }

    private fun convertProduct(map: ReadableMap?): Product? {
        if (map == null) return null
        val name = map.getString("name") ?: return null
        val sku = map.getString("sku") ?: return null
        val unitPrice = map.getDouble("price")
        val builder = Product.Builder(name, sku, unitPrice)

        if (map.hasKey("brand")) {
            map.getString("brand")?.let { builder.brand(it) }
        }

        if (map.hasKey("category")) {
            map.getString("category")?.let { builder.category(it) }
        }

        if (map.hasKey("couponCode")) {
            map.getString("couponCode")?.let { builder.couponCode(it) }
        }

        if (map.hasKey("customAttributes")) {
            val customAttributesMap = map.getMap("customAttributes")
            val customAttributes = convertStringMap(customAttributesMap)
            builder.customAttributes(customAttributes)
        }

        if (map.hasKey("position")) {
            builder.position(map.getInt("position"))
        }

        if (map.hasKey("quantity")) {
            builder.quantity(map.getDouble("quantity"))
        }

        if (map.hasKey("variant")) {
            map.getString("variant")?.let { builder.variant(it) }
        }

        return builder.build()
    }

    private fun convertTransactionAttributes(map: ReadableMap?): TransactionAttributes? {
        if (map?.hasKey("transactionId") != true) {
            return null
        }

        val transactionId = map.getString("transactionId") ?: return null
        val transactionAttributes = TransactionAttributes(transactionId)

        if (map.hasKey("affiliation")) {
            map.getString("affiliation")?.let { transactionAttributes.affiliation = it }
        }

        if (map.hasKey("revenue")) {
            transactionAttributes.revenue = map.getDouble("revenue")
        }

        if (map.hasKey("shipping")) {
            transactionAttributes.shipping = map.getDouble("shipping")
        }

        if (map.hasKey("tax")) {
            transactionAttributes.tax = map.getDouble("tax")
        }

        if (map.hasKey("couponCode")) {
            map.getString("couponCode")?.let { transactionAttributes.couponCode = it }
        }

        return transactionAttributes
    }

    private fun convertPromotion(map: ReadableMap?): Promotion? {
        if (map == null) return null
        val promotion = Promotion()

        if (map.hasKey("id")) {
            map.getString("id")?.let { promotion.id = it }
        }

        if (map.hasKey("name")) {
            map.getString("name")?.let { promotion.name = it }
        }

        if (map.hasKey("creative")) {
            map.getString("creative")?.let { promotion.creative = it }
        }

        if (map.hasKey("position")) {
            map.getString("position")?.let { promotion.position = it }
        }

        return promotion
    }

    private fun convertImpression(map: ReadableMap?): Impression? {
        if (map == null) return null
        val listName = map.getString("impressionListName") ?: return null
        val productsArray = map.getArray("products") ?: return null
        val productMap = productsArray.getMap(0)
        val product = convertProduct(productMap) ?: return null
        val impression = Impression(listName, product)

        for (i in 1 until productsArray.size()) {
            val nextProductMap = productsArray.getMap(i)
            val nextProduct = convertProduct(nextProductMap)
            if (nextProduct != null) {
                impression.addProduct(nextProduct)
            }
        }

        return impression
    }

    private fun convertStringMap(readableMap: ReadableMap?): Map<String, String>? {
        if (readableMap == null) return null

        val map = mutableMapOf<String, String>()
        val iterator = readableMap.keySetIterator()
        while (iterator.hasNextKey()) {
            val key = iterator.nextKey()
            when (readableMap.getType(key)) {
                ReadableType.Null -> map[key] = ""
                ReadableType.Boolean -> map[key] = readableMap.getBoolean(key).toString()
                ReadableType.Number -> {
                    try {
                        map[key] = readableMap.getInt(key).toString()
                    } catch (e: Exception) {
                        try {
                            map[key] = readableMap.getDouble(key).toString()
                        } catch (ex: Exception) {
                            Logger.warning("Unable to parse value for \"$key\"")
                        }
                    }
                }

                ReadableType.String -> map[key] = readableMap.getString(key) ?: ""
                ReadableType.Map -> Logger.warning("Maps are not supported Attribute value types")
                ReadableType.Array -> Logger.warning("Lists are not supported Attribute value types")
            }
        }
        return map
    }

    private fun convertUserIdentities(readableMap: ReadableMap?): Map<MParticle.IdentityType, String> {
        val map = mutableMapOf<MParticle.IdentityType, String>()
        if (readableMap != null) {
            val iterator = readableMap.keySetIterator()
            while (iterator.hasNextKey()) {
                val key = iterator.nextKey()
                val identity = when (key) {
                    "email" -> MParticle.IdentityType.Email
                    "customerId" -> MParticle.IdentityType.CustomerId
                    else -> MParticle.IdentityType.parseInt(key.toInt())
                }
                identity.let {
                    readableMap.getString(key)?.let { value ->
                        map[it] = value
                    }
                }
            }
        }
        return map
    }

    private fun convertToUserIdentities(userIdentities: Map<MParticle.IdentityType, String>): WritableMap {
        val nativeMap = getWritableMap()
        userIdentities.forEach { (key, value) ->
            nativeMap.putString(key.value.toString(), value)
        }
        return nativeMap
    }

    private fun convertEventType(eventType: Int): MParticle.EventType {
        return when (eventType) {
            1 -> MParticle.EventType.Navigation
            2 -> MParticle.EventType.Location
            3 -> MParticle.EventType.Search
            4 -> MParticle.EventType.Transaction
            5 -> MParticle.EventType.UserContent
            6 -> MParticle.EventType.UserPreference
            7 -> MParticle.EventType.Social
            8 -> MParticle.EventType.Other
            9 -> MParticle.EventType.Media
            else -> MParticle.EventType.Other
        }
    }

    private fun convertProductActionType(productActionType: Int): String {
        return when (productActionType) {
            1 -> Product.ADD_TO_CART
            2 -> Product.REMOVE_FROM_CART
            3 -> Product.CHECKOUT
            4 -> Product.CHECKOUT_OPTION
            5 -> Product.CLICK
            6 -> Product.DETAIL
            7 -> Product.PURCHASE
            8 -> Product.REFUND
            9 -> Product.ADD_TO_WISHLIST
            else -> Product.REMOVE_FROM_WISHLIST
        }
    }

    private fun convertPromotionActionType(promotionActionType: Int): String {
        return when (promotionActionType) {
            0 -> Promotion.VIEW
            else -> Promotion.CLICK
        }
    }

    private fun parseMpid(longString: String): Long {
        return try {
            longString.toLong()
        } catch (ex: NumberFormatException) {
            0L
        }
    }

    private fun convertToGDPRConsent(map: ReadableMap): GDPRConsent? {
        val consented = try {
            when (map.getType("consented")) {
                ReadableType.Boolean -> map.getBoolean("consented")
                else -> map.getString("consented")?.toBoolean() ?: false
            }
        } catch (ex: Exception) {
            Logger.error("failed to convert \"consented\" value to a Boolean, unable to process addGDPRConsentState")
            return null
        }

        val builder = GDPRConsent.builder(consented)

        if (map.hasKey("document")) {
            map.getString("document")?.let { builder.document(it) }
        }
        if (map.hasKey("hardwareId")) {
            map.getString("hardwareId")?.let { builder.hardwareId(it) }
        }
        if (map.hasKey("location")) {
            map.getString("location")?.let { builder.location(it) }
        }
        if (map.hasKey("timestamp")) {
            try {
                val timestampString = map.getString("timestamp")
                val timestamp = timestampString?.toLong()
                timestamp?.let { builder.timestamp(it) }
            } catch (ex: Exception) {
                Logger.warning("failed to convert \"timestamp\" value to Long")
            }
        }
        return builder.build()
    }

    private fun convertToCCPAConsent(map: ReadableMap): CCPAConsent? {
        val consented = try {
            when (map.getType("consented")) {
                ReadableType.Boolean -> map.getBoolean("consented")
                else -> map.getString("consented")?.toBoolean() ?: false
            }
        } catch (ex: Exception) {
            Logger.error("failed to convert \"consented\" value to a Boolean, unable to process addCCPAConsentState")
            return null
        }

        val builder = CCPAConsent.builder(consented)

        if (map.hasKey("document")) {
            map.getString("document")?.let { builder.document(it) }
        }
        if (map.hasKey("hardwareId")) {
            map.getString("hardwareId")?.let { builder.hardwareId(it) }
        }
        if (map.hasKey("location")) {
            map.getString("location")?.let { builder.location(it) }
        }
        if (map.hasKey("timestamp")) {
            try {
                val timestampString = map.getString("timestamp")
                val timestamp = timestampString?.toLong()
                timestamp?.let { builder.timestamp(it) }
            } catch (ex: Exception) {
                Logger.warning("failed to convert \"timestamp\" value to Long")
            }
        }
        return builder.build()
    }
}
