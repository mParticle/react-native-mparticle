package com.mparticle.react.rokt

import android.view.View
import org.junit.After
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Test
import org.mockito.Mockito.mock
import org.mockito.Mockito.`when`

class RoktPlaceholderRegistryTest {
    private val registered = mutableListOf<View>()

    @After
    fun tearDown() {
        registered.forEach { RoktPlaceholderRegistry.unregister(it) }
    }

    private fun view(attached: Boolean = true): View =
        mock(View::class.java).also {
            `when`(it.isAttachedToWindow).thenReturn(attached)
            registered += it
        }

    @Test
    fun `resolves a registered view by name`() {
        val view = view()
        RoktPlaceholderRegistry.register(view, "Location1")

        assertSame(view, RoktPlaceholderRegistry.lookup("Location1"))
        assertNull(RoktPlaceholderRegistry.lookup("Location2"))
    }

    @Test
    fun `renaming moves the view to the new name`() {
        val view = view()
        RoktPlaceholderRegistry.register(view, "Location1")
        RoktPlaceholderRegistry.register(view, "Location2")

        assertNull(RoktPlaceholderRegistry.lookup("Location1"))
        assertSame(view, RoktPlaceholderRegistry.lookup("Location2"))
    }

    @Test
    fun `dropping the newest view with a shared name leaves the older one resolvable`() {
        val lower = view()
        val upper = view()
        RoktPlaceholderRegistry.register(lower, "Location1")
        RoktPlaceholderRegistry.register(upper, "Location1")
        assertSame(upper, RoktPlaceholderRegistry.lookup("Location1"))

        RoktPlaceholderRegistry.unregister(upper)

        assertSame(lower, RoktPlaceholderRegistry.lookup("Location1"))
    }

    @Test
    fun `prefers an attached view over a newer detached one`() {
        val attached = view(attached = true)
        val detached = view(attached = false)
        RoktPlaceholderRegistry.register(attached, "Location1")
        RoktPlaceholderRegistry.register(detached, "Location1")

        assertSame(attached, RoktPlaceholderRegistry.lookup("Location1"))
    }

    @Test
    fun `a null name only unregisters`() {
        val view = view()
        RoktPlaceholderRegistry.register(view, "Location1")
        RoktPlaceholderRegistry.register(view, null)

        assertNull(RoktPlaceholderRegistry.lookup("Location1"))
    }
}
