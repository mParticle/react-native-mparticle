package com.mparticle.react.rokt

import com.facebook.react.bridge.ReactApplicationContext
import com.mparticle.react.testutils.MockMap
import org.junit.Assert.assertEquals
import org.junit.Test
import org.mockito.Mockito.mock

class MPRoktModuleImplTest {
    private val impl = MPRoktModuleImpl(mock(ReactApplicationContext::class.java))

    @Test
    fun readableMapToMapOfStrings_coercesNumbersAndBooleans() {
        val attributes =
            MockMap(
                mapOf(
                    "amount" to 23.47,
                    "confirmationref" to 4600097641L,
                    "sandbox" to true,
                    "country" to "US",
                ),
            )

        val result = impl.readableMapToMapOfStrings(attributes)

        assertEquals("23.47", result["amount"])
        assertEquals("4600097641", result["confirmationref"])
        assertEquals("true", result["sandbox"])
        assertEquals("US", result["country"])
    }

    @Test
    fun readableMapToMapOfStrings_skipsNullValues() {
        val attributes = MockMap()
        attributes.putString("country", "US")
        attributes.putNull("amount")

        val result = impl.readableMapToMapOfStrings(attributes)

        assertEquals(mapOf("country" to "US"), result)
    }

    @Test
    fun readableMapToMapOfStrings_formatsWholeNumberDoublesWithoutTrailingDecimal() {
        val attributes = MockMap(mapOf("quantity" to 100.0))

        val result = impl.readableMapToMapOfStrings(attributes)

        assertEquals("100", result["quantity"])
    }

    @Test
    fun formatNumberAttribute_avoidsScientificNotation() {
        assertEquals("10000000000", MPRoktModuleImpl.formatNumberAttribute(1.0e10))
    }
}
