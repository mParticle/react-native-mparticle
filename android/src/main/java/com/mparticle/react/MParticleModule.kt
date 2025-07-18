package com.mparticle.react

import android.location.Location
import android.util.Log
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Callback
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
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
import javax.annotation.Nullable

class MParticleModule(
    reactContext: ReactApplicationContext,
) : ReactContextBaseJavaModule(reactContext) {
    companion object {
        const val MODULE_NAME = "MParticle"
        private const val LOG_TAG = "MParticleModule"
    }

    override fun getName(): String = MODULE_NAME

    @ReactMethod
    fun upload() {
        MParticle.getInstance()?.upload()
    }

    @ReactMethod
    fun setUploadInterval(uploadInterval: Int) {
        MParticle.getInstance()?.setUpdateInterval(uploadInterval)
    }

    @ReactMethod
    fun setLocation(
        latitude: Double,
        longitude: Double,
    ) {
        val newLocation =
            Location("").apply {
                this.latitude = latitude
                this.longitude = longitude
            }
        MParticle.getInstance()?.setLocation(newLocation)
    }

    @ReactMethod
    fun logEvent(
        name: String,
        type: Int,
        attributesMap: ReadableMap?,
    ) {
        val attributes = convertStringMap(attributesMap)
        val eventType = convertEventType(type)

        val event =
            MPEvent
                .Builder(name, eventType)
                .customAttributes(attributes)
                .build()
        MParticle.getInstance()?.logEvent(event)
    }

    @ReactMethod
    fun logMPEvent(attributesMap: ReadableMap?) {
        val event = convertMPEvent(attributesMap)
        if (event != null) {
            MParticle.getInstance()?.logEvent(event)
        }
    }

    @ReactMethod
    fun logCommerceEvent(map: ReadableMap?) {
        if (map != null) {
            val commerceEvent = convertCommerceEvent(map)
            if (commerceEvent != null) {
                MParticle.getInstance()?.logEvent(commerceEvent)
            }
        }
    }

    @ReactMethod
    fun logScreenEvent(
        eventName: String,
        attributesMap: ReadableMap?,
        shouldUploadEvent: Boolean,
    ) {
        val attributes = convertStringMap(attributesMap)
        MParticle.getInstance()?.logScreen(eventName, attributes, shouldUploadEvent)
    }

    @ReactMethod
    fun setUserAttribute(
        userId: String,
        userAttribute: String,
        value: String,
    ) {
        val selectedUser = MParticle.getInstance()?.Identity()?.getUser(parseMpid(userId))
        selectedUser?.setUserAttribute(userAttribute, value)
    }

    @ReactMethod
    fun setUserAttributeArray(
        userId: String,
        key: String,
        values: ReadableArray?,
    ) {
        if (values != null) {
            val list = mutableListOf<String>()
            for (i in 0 until values.size()) {
                values.getString(i)?.let { list.add(it) }
            }

            val selectedUser = MParticle.getInstance()?.Identity()?.getUser(parseMpid(userId))
            selectedUser?.setUserAttributeList(key, list)
        }
    }

    @ReactMethod
    fun getUserAttributes(
        userId: String,
        completion: Callback,
    ) {
        val selectedUser = MParticle.getInstance()?.Identity()?.getUser(parseMpid(userId))
        if (selectedUser != null) {
            selectedUser.getUserAttributes(
                object : UserAttributeListener {
                    override fun onUserAttributesReceived(
                        userAttributes: MutableMap<String, String>?,
                        userAttributeLists: MutableMap<String, MutableList<String>>?,
                        mpid: Long?,
                    ) {
                        val resultMap = WritableNativeMap()
                        userAttributes?.let { attrs ->
                            for ((key, value) in attrs) {
                                resultMap.putString(key, value)
                            }
                        }
                        userAttributeLists?.let { attrLists ->
                            for ((key, valueList) in attrLists) {
                                val resultArray = WritableNativeArray()
                                for (arrayVal in valueList) {
                                    resultArray.pushString(arrayVal)
                                }
                                resultMap.putArray(key, resultArray)
                            }
                        }
                        completion.invoke(null, resultMap)
                    }
                },
            )
        } else {
            completion.invoke()
        }
    }

    @ReactMethod
    fun setUserTag(
        userId: String,
        tag: String,
    ) {
        val selectedUser = MParticle.getInstance()?.Identity()?.getUser(parseMpid(userId))
        selectedUser?.setUserTag(tag)
    }

    @ReactMethod
    fun removeUserAttribute(
        userId: String,
        key: String,
    ) {
        val selectedUser = MParticle.getInstance()?.Identity()?.getUser(parseMpid(userId))
        selectedUser?.removeUserAttribute(key)
    }

    @ReactMethod
    fun incrementUserAttribute(
        userId: String,
        key: String,
        value: Int,
    ) {
        val selectedUser = MParticle.getInstance()?.Identity()?.getUser(parseMpid(userId))
        selectedUser?.incrementUserAttribute(key, value)
    }

    @ReactMethod
    fun identify(
        requestMap: ReadableMap?,
        completion: Callback,
    ) {
        val request = convertIdentityAPIRequest(requestMap)

        MParticle
            .getInstance()
            ?.Identity()
            ?.identify(request)
            ?.addFailureListener { identityHttpResponse ->
                completion.invoke(convertIdentityHttpResponse(identityHttpResponse), null)
            }?.addSuccessListener { identityApiResult ->
                val user = identityApiResult.user
                val userID = user.id.toString()
                completion.invoke(null, userID)
            }
    }

    @ReactMethod
    fun login(
        requestMap: ReadableMap?,
        completion: Callback,
    ) {
        val request = convertIdentityAPIRequest(requestMap)

        MParticle
            .getInstance()
            ?.Identity()
            ?.login(request)
            ?.addFailureListener { identityHttpResponse ->
                completion.invoke(convertIdentityHttpResponse(identityHttpResponse), null)
            }?.addSuccessListener { identityApiResult ->
                val user = identityApiResult.user
                val userId = user.id.toString()
                val previousUser = identityApiResult.previousUser
                val previousUserId = previousUser?.id?.toString()
                completion.invoke(null, userId, previousUserId)
            }
    }

    @ReactMethod
    fun logout(
        requestMap: ReadableMap?,
        completion: Callback,
    ) {
        val request = convertIdentityAPIRequest(requestMap)

        MParticle
            .getInstance()
            ?.Identity()
            ?.logout(request)
            ?.addFailureListener { identityHttpResponse ->
                completion.invoke(convertIdentityHttpResponse(identityHttpResponse), null)
            }?.addSuccessListener { identityApiResult ->
                val user = identityApiResult.user
                val userID = user.id.toString()
                completion.invoke(null, userID)
            }
    }

    @ReactMethod
    fun modify(
        requestMap: ReadableMap?,
        completion: Callback,
    ) {
        val request = convertIdentityAPIRequest(requestMap)

        MParticle
            .getInstance()
            ?.Identity()
            ?.modify(request)
            ?.addFailureListener { identityHttpResponse ->
                completion.invoke(convertIdentityHttpResponse(identityHttpResponse), null)
            }?.addSuccessListener { identityApiResult ->
                val user = identityApiResult.user
                val userID = user.id.toString()
                completion.invoke(null, userID)
            }
    }

    @ReactMethod
    fun getCurrentUserWithCompletion(completion: Callback) {
        val currentUser = MParticle.getInstance()?.Identity()?.currentUser
        if (currentUser != null) {
            val userID = currentUser.id.toString()
            completion.invoke(null, userID)
        } else {
            completion.invoke(null, null)
        }
    }

    @ReactMethod
    fun aliasUsers(
        readableMap: ReadableMap?,
        completion: Callback,
    ) {
        val identityApi = MParticle.getInstance()?.Identity() ?: return
        val iterator = readableMap?.keySetIterator() ?: return
        var destinationMpid: Long? = null
        var sourceMpid: Long? = null
        var startTime: Long? = null
        var endTime: Long? = null

        while (iterator.hasNextKey()) {
            try {
                when (iterator.nextKey()) {
                    "destinationMpid" -> destinationMpid = Utils.getLong(readableMap, "destinationMpid", false)
                    "sourceMpid" -> sourceMpid = Utils.getLong(readableMap, "sourceMpid", false)
                    "startTime" -> startTime = Utils.getLong(readableMap, "startTime", true)
                    "endTime" -> endTime = Utils.getLong(readableMap, "endTime", true)
                }
            } catch (ex: NumberFormatException) {
                Logger.error(ex.message)
                completion.invoke(false, ex.message)
                return
            }
        }

        if (startTime == null && endTime == null) {
            var sourceUser: MParticleUser? = null
            var destinationUser: MParticleUser? = null
            sourceMpid?.let { sourceUser = identityApi.getUser(it) }
            destinationMpid?.let { destinationUser = identityApi.getUser(it) }

            if (sourceUser != null && destinationUser != null) {
                val request = AliasRequest.builder(sourceUser, destinationUser).build()
                val success = MParticle.getInstance()?.Identity()?.aliasUsers(request) ?: false
                completion.invoke(success)
            } else {
                completion.invoke(false, "MParticleUser could not be found for provided sourceMpid and destinationMpid")
            }
        } else {
            val request =
                AliasRequest
                    .builder()
                    .destinationMpid(destinationMpid ?: 0)
                    .sourceMpid(sourceMpid ?: 0)
                    .startTime(startTime ?: 0)
                    .endTime(endTime ?: 0)
                    .build()
            val success = identityApi.aliasUsers(request)
            completion.invoke(success)
        }
    }

    @ReactMethod
    fun getSession(completion: Callback) {
        val session = MParticle.getInstance()?.currentSession
        if (session != null) {
            val sessionId = session.sessionUUID
            completion.invoke(sessionId)
        } else {
            completion.invoke()
        }
    }

    @ReactMethod
    fun getUserIdentities(
        userId: String,
        completion: Callback,
    ) {
        val selectedUser = MParticle.getInstance()?.Identity()?.getUser(parseMpid(userId))
        if (selectedUser != null) {
            completion.invoke(null, convertToUserIdentities(selectedUser.userIdentities))
        } else {
            completion.invoke()
        }
    }

    @ReactMethod
    fun getFirstSeen(
        userId: String,
        completion: Callback,
    ) {
        val selectedUser = MParticle.getInstance()?.Identity()?.getUser(Utils.parseMpid(userId))
        if (selectedUser != null) {
            completion.invoke(selectedUser.firstSeenTime.toString())
        } else {
            completion.invoke()
        }
    }

    @ReactMethod
    fun getLastSeen(
        userId: String,
        completion: Callback,
    ) {
        val selectedUser = MParticle.getInstance()?.Identity()?.getUser(Utils.parseMpid(userId))
        if (selectedUser != null) {
            completion.invoke(selectedUser.lastSeenTime.toString())
        } else {
            completion.invoke()
        }
    }

    @ReactMethod
    fun getAttributions(completion: Callback) {
        val attributionResultMap = MParticle.getInstance()?.attributionResults
        val map = Arguments.createMap()
        attributionResultMap?.let { resultMap ->
            for ((key, attribution) in resultMap) {
                val attributeMap = Arguments.createMap()
                attribution?.let { attr ->
                    attributeMap.putInt("kitId", attr.serviceProviderId)
                    attr.link?.let { attributeMap.putString("link", it) }
                    attr.parameters?.let { attributeMap.putString("linkParameters", it.toString()) }
                }
                map.putMap(key.toString(), attributeMap)
            }
        }
        completion.invoke(map)
    }

    @ReactMethod
    fun setOptOut(optOut: Boolean) {
        MParticle.getInstance()?.setOptOut(optOut)
    }

    @ReactMethod
    fun getOptOut(completion: Callback) {
        val optedOut = MParticle.getInstance()?.optOut ?: false
        completion.invoke(optedOut)
    }

    @ReactMethod
    fun isKitActive(
        kitId: Int,
        completion: Callback,
    ) {
        val isActive = MParticle.getInstance()?.isKitActive(kitId) ?: false
        completion.invoke(isActive)
    }

    @ReactMethod
    fun logPushRegistration(
        instanceId: String?,
        senderId: String?,
    ) {
        if (!instanceId.isNullOrEmpty() && !senderId.isNullOrEmpty()) {
            MParticle.getInstance()?.logPushRegistration(instanceId, senderId)
        }
    }

    @ReactMethod
    fun addGDPRConsentState(
        map: ReadableMap?,
        purpose: String,
    ) {
        val currentUser = MParticle.getInstance()?.Identity()?.currentUser
        if (currentUser != null) {
            val consent = convertToGDPRConsent(map)
            if (consent != null) {
                val consentState =
                    ConsentState
                        .withConsentState(currentUser.consentState)
                        .addGDPRConsentState(purpose, consent)
                        .build()
                currentUser.setConsentState(consentState)
                Logger.info("GDPRConsentState added, \n\t\"purpose\": $purpose\n$consentState")
            } else {
                Logger.warning("GDPRConsentState was not able to be deserialized, will not be added")
            }
        }
    }

    @ReactMethod
    fun removeGDPRConsentStateWithPurpose(purpose: String) {
        val currentUser = MParticle.getInstance()?.Identity()?.currentUser
        if (currentUser != null) {
            val consentState =
                ConsentState
                    .withConsentState(currentUser.consentState)
                    .removeGDPRConsentState(purpose)
                    .build()
            currentUser.setConsentState(consentState)
        }
    }

    @ReactMethod
    fun setCCPAConsentState(map: ReadableMap?) {
        val currentUser = MParticle.getInstance()?.Identity()?.currentUser
        if (currentUser != null) {
            val consent = convertToCCPAConsent(map)
            if (consent != null) {
                val consentState =
                    ConsentState
                        .withConsentState(currentUser.consentState)
                        .setCCPAConsentState(consent)
                        .build()
                currentUser.setConsentState(consentState)
                Logger.info("CCPAConsentState added, \n$consentState")
            } else {
                Logger.warning("CCPAConsentState was not able to be deserialized, will not be added")
            }
        }
    }

    @ReactMethod
    fun removeCCPAConsentState() {
        val currentUser = MParticle.getInstance()?.Identity()?.currentUser
        if (currentUser != null) {
            val consentState =
                ConsentState
                    .withConsentState(currentUser.consentState)
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
                builder.category(map.getString("category"))
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
                for ((key, value) in customFlags) {
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
        response?.errors?.let { errors ->
            for (error in errors) {
                error?.let {
                    stringBuilder.append("Code: ${it.code}\n")
                    stringBuilder.append("Message: ${it.message}\n")
                }
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

        var builder: CommerceEvent.Builder?

        when {
            isProductAction -> {
                val productActionInt = map.getInt("productActionType")
                val productAction = convertProductActionType(productActionInt)
                val productsArray = map.getArray("products") ?: return null
                val productMap = productsArray.getMap(0)
                val product = convertProduct(productMap) ?: return null
                val transactionAttributesMap = map.getMap("transactionAttributes")
                val transactionAttributes = convertTransactionAttributes(transactionAttributesMap)

                builder = CommerceEvent.Builder(productAction, product)
                transactionAttributes?.let { builder.transactionAttributes(it) }

                for (i in 1 until productsArray.size()) {
                    val nextProductMap = productsArray.getMap(i)
                    val nextProduct = convertProduct(nextProductMap)
                    if (nextProduct != null) {
                        builder.addProduct(nextProduct)
                    }
                }
            }
            isPromotion -> {
                val promotionActionTypeInt = map.getInt("promotionActionType")
                val promotionAction = convertPromotionActionType(promotionActionTypeInt)
                val promotionsReadableArray = map.getArray("promotions") ?: return null
                val promotionMap = promotionsReadableArray.getMap(0)
                val promotion = convertPromotion(promotionMap)
                builder = CommerceEvent.Builder(promotionAction, promotion)

                for (i in 1 until promotionsReadableArray.size()) {
                    val nextPromotionMap = promotionsReadableArray.getMap(i)
                    val nextPromotion = convertPromotion(nextPromotionMap)
                    builder.addPromotion(nextPromotion)
                }
            }
            else -> {
                val impressionsArray = map.getArray("impressions") ?: return null
                val impressionMap = impressionsArray.getMap(0)
                val impression = convertImpression(impressionMap) ?: return null
                builder = CommerceEvent.Builder(impression)

                for (i in 1 until impressionsArray.size()) {
                    val nextImpressionMap = impressionsArray.getMap(i)
                    val nextImpression = convertImpression(nextImpressionMap)
                    if (nextImpression != null) {
                        builder.addImpression(nextImpression)
                    }
                }
            }
        }

        return builder.let { b ->
            if (map.hasKey("shouldUploadEvent")) {
                b.shouldUploadEvent(map.getBoolean("shouldUploadEvent"))
            }
            if (map.hasKey("customAttributes")) {
                b.customAttributes(convertStringMap(map.getMap("customAttributes")))
            }
            if (map.hasKey("currency")) {
                b.currency(map.getString("currency"))
            }
            if (map.hasKey("checkoutStep")) {
                b.checkoutStep(map.getInt("checkoutStep"))
            }
            if (map.hasKey("checkoutOptions")) {
                b.checkoutOptions(map.getString("checkoutOptions"))
            }
            b.build()
        }
    }

    private fun convertProduct(map: ReadableMap?): Product? {
        if (map == null) return null

        val name = map.getString("name") ?: return null
        val sku = map.getString("sku") ?: return null
        val unitPrice = map.getDouble("price")
        val builder = Product.Builder(name, sku, unitPrice)

        if (map.hasKey("brand")) {
            val brand = map.getString("brand")
            builder.brand(brand)
        }

        if (map.hasKey("category")) {
            val category = map.getString("category")
            builder.category(category)
        }

        if (map.hasKey("couponCode")) {
            val couponCode = map.getString("couponCode")
            builder.couponCode(couponCode)
        }

        if (map.hasKey("customAttributes")) {
            val customAttributesMap = map.getMap("customAttributes")
            val customAttributes = convertStringMap(customAttributesMap)
            builder.customAttributes(customAttributes)
        }

        if (map.hasKey("position")) {
            val position = map.getInt("position")
            builder.position(position)
        }

        if (map.hasKey("quantity")) {
            val quantity = map.getDouble("quantity")
            builder.quantity(quantity)
        }

        if (map.hasKey("variant")) {
            val variant = map.getString("variant")
            builder.variant(variant)
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
            transactionAttributes.affiliation = map.getString("affiliation")
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
            transactionAttributes.couponCode = map.getString("couponCode")
        }

        return transactionAttributes
    }

    private fun convertPromotion(map: ReadableMap?): Promotion {
        val promotion = Promotion()

        map?.let { m ->
            if (m.hasKey("id")) {
                promotion.id = m.getString("id")
            }

            if (m.hasKey("name")) {
                promotion.name = m.getString("name")
            }

            if (m.hasKey("creative")) {
                promotion.creative = m.getString("creative")
            }

            if (m.hasKey("position")) {
                promotion.position = m.getString("position")
            }
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

    private fun convertStringMap(readableMap: ReadableMap?): Map<String, String> {
        val map = mutableMapOf<String, String>()

        readableMap?.let { rm ->
            val iterator = rm.keySetIterator()
            while (iterator.hasNextKey()) {
                val key = iterator.nextKey()
                when (rm.getType(key)) {
                    ReadableType.Null -> map[key] = ""
                    ReadableType.Boolean -> map[key] = rm.getBoolean(key).toString()
                    ReadableType.Number -> {
                        try {
                            map[key] = rm.getInt(key).toString()
                        } catch (_: Exception) {
                            try {
                                map[key] = rm.getDouble(key).toString()
                            } catch (_: Exception) {
                                Logger.warning("Unable to parse value for \"$key\"")
                            }
                        }
                    }
                    ReadableType.String -> map[key] = rm.getString(key) ?: ""
                    ReadableType.Map -> Logger.warning("Maps are not supported Attribute value types")
                    ReadableType.Array -> Logger.warning("Lists are not supported Attribute value types")
                }
            }
        }

        return map
    }

    private fun convertUserIdentities(readableMap: ReadableMap?): Map<MParticle.IdentityType, String> {
        val map = mutableMapOf<MParticle.IdentityType, String>()
        readableMap?.let { rm ->
            val iterator = rm.keySetIterator()
            while (iterator.hasNextKey()) {
                val key = iterator.nextKey()
                val identity =
                    when (key) {
                        "email" -> MParticle.IdentityType.Email
                        "customerId" -> MParticle.IdentityType.CustomerId
                        else -> MParticle.IdentityType.parseInt(key.toIntOrNull() ?: 0)
                    }
                identity.let { identityType ->
                    rm.getString(key)?.let { value ->
                        map[identityType] = value
                    }
                }
            }
        }
        return map
    }

    private fun convertToUserIdentities(userIdentities: Map<MParticle.IdentityType, String>): WritableMap {
        val nativeMap = getWritableMap()
        for ((identityType, value) in userIdentities) {
            nativeMap.putString(identityType.value.toString(), value)
        }
        return nativeMap
    }

    private fun convertEventType(eventType: Int): MParticle.EventType =
        when (eventType) {
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

    private fun convertProductActionType(productActionType: Int): String =
        when (productActionType) {
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

    private fun convertPromotionActionType(promotionActionType: Int): String =
        when (promotionActionType) {
            0 -> Promotion.VIEW
            else -> Promotion.CLICK
        }

    private fun parseMpid(longString: String): Long =
        try {
            longString.toLong()
        } catch (_: NumberFormatException) {
            0L
        }

    @Nullable
    private fun convertToGDPRConsent(map: ReadableMap?): GDPRConsent? {
        if (map == null) return null

        val consented: Boolean =
            try {
                when (map.getType("consented")) {
                    ReadableType.Boolean -> map.getBoolean("consented")
                    else -> map.getString("consented")?.toBoolean() ?: false
                }
            } catch (_: Exception) {
                Logger.error("failed to convert \"consented\" value to a Boolean, unable to process addGDPRConsentState")
                return null
            }

        val builder = GDPRConsent.builder(consented)

        if (map.hasKey("document")) {
            val document = map.getString("document")
            builder.document(document)
        }
        if (map.hasKey("hardwareId")) {
            val hardwareId = map.getString("hardwareId")
            builder.hardwareId(hardwareId)
        }
        if (map.hasKey("location")) {
            val location = map.getString("location")
            builder.location(location)
        }
        if (map.hasKey("timestamp")) {
            try {
                val timestampString = map.getString("timestamp")
                val timestamp = timestampString?.toLong()
                timestamp?.let { builder.timestamp(it) }
            } catch (_: Exception) {
                Logger.warning("failed to convert \"timestamp\" value to Long")
            }
        }
        return builder.build()
    }

    @Nullable
    private fun convertToCCPAConsent(map: ReadableMap?): CCPAConsent? {
        if (map == null) return null

        val consented: Boolean =
            try {
                when (map.getType("consented")) {
                    ReadableType.Boolean -> map.getBoolean("consented")
                    else -> map.getString("consented")?.toBoolean() ?: false
                }
            } catch (_: Exception) {
                Logger.error("failed to convert \"consented\" value to a Boolean, unable to process addCCPAConsentState")
                return null
            }

        val builder = CCPAConsent.builder(consented)

        if (map.hasKey("document")) {
            val document = map.getString("document")
            builder.document(document)
        }
        if (map.hasKey("hardwareId")) {
            val hardwareId = map.getString("hardwareId")
            builder.hardwareId(hardwareId)
        }
        if (map.hasKey("location")) {
            val location = map.getString("location")
            builder.location(location)
        }
        if (map.hasKey("timestamp")) {
            try {
                val timestampString = map.getString("timestamp")
                val timestamp = timestampString?.toLong()
                timestamp?.let { builder.timestamp(it) }
            } catch (_: Exception) {
                Logger.warning("failed to convert \"timestamp\" value to Long")
            }
        }
        return builder.build()
    }
}
