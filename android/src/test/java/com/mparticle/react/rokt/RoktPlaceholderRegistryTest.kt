package com.mparticle.react.rokt

import android.view.View
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Before
import org.junit.Test
import org.mockito.Mockito.mock
import org.mockito.Mockito.`when`

class RoktPlaceholderRegistryTest {
    private val registered = mutableListOf<View>()

    // Runs posted work only when the test says so, standing in for the UI thread's looper.
    private class FakeScheduler : RoktPlaceholderRegistry.Scheduler {
        val posted = mutableListOf<Runnable>()
        val delayed = mutableListOf<Runnable>()

        override fun post(runnable: Runnable) {
            posted += runnable
        }

        override fun postDelayed(
            runnable: Runnable,
            delayMillis: Long,
        ) {
            delayed += runnable
        }

        override fun cancel(runnable: Runnable) {
            delayed -= runnable
        }

        fun runPosted() = posted.toList().also { posted.clear() }.forEach { it.run() }

        fun fireTimeouts() = delayed.toList().also { delayed.clear() }.forEach { it.run() }
    }

    private val scheduler = FakeScheduler()
    private lateinit var originalScheduler: RoktPlaceholderRegistry.Scheduler

    @Before
    fun setUp() {
        originalScheduler = RoktPlaceholderRegistry.scheduler
        RoktPlaceholderRegistry.scheduler = scheduler
    }

    @After
    fun tearDown() {
        RoktPlaceholderRegistry.cancelWaits()
        registered.forEach { RoktPlaceholderRegistry.unregister(it) }
        RoktPlaceholderRegistry.scheduler = originalScheduler
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

    @Test
    fun `a wait runs once its placeholder mounts, after the mount pass`() {
        var runs = 0
        RoktPlaceholderRegistry.awaitNames("page", listOf("Location1"), 2000) { runs++ }
        assertEquals(0, runs)

        RoktPlaceholderRegistry.register(view(), "Location1")
        assertEquals("posted, not run inside registration", 0, runs)

        scheduler.runPosted()
        assertEquals(1, runs)
        scheduler.fireTimeouts()
        scheduler.runPosted()
        assertEquals("timeout cancelled once satisfied", 1, runs)
    }

    @Test
    fun `a wait runs on timeout when its placeholder never mounts`() {
        var runs = 0
        RoktPlaceholderRegistry.awaitNames("page", listOf("Location1"), 2000) { runs++ }

        scheduler.fireTimeouts()
        scheduler.runPosted()

        assertEquals(1, runs)
    }

    @Test
    fun `a wait needs every name`() {
        var runs = 0
        RoktPlaceholderRegistry.awaitNames("page", listOf("Location1", "Location2"), 2000) { runs++ }

        RoktPlaceholderRegistry.register(view(), "Location1")
        scheduler.runPosted()
        assertEquals(0, runs)

        RoktPlaceholderRegistry.register(view(), "Location2")
        scheduler.runPosted()
        assertEquals(1, runs)
    }

    @Test
    fun `a newer wait with the same key replaces the older one`() {
        var older = 0
        var newer = 0
        RoktPlaceholderRegistry.awaitNames("page", listOf("Location1"), 2000) { older++ }
        RoktPlaceholderRegistry.awaitNames("page", listOf("Location1"), 2000) { newer++ }

        RoktPlaceholderRegistry.register(view(), "Location1")
        scheduler.runPosted()
        scheduler.fireTimeouts()
        scheduler.runPosted()

        assertEquals(0, older)
        assertEquals(1, newer)
    }

    @Test
    fun `cancelled waits never run`() {
        var runs = 0
        RoktPlaceholderRegistry.awaitNames("page", listOf("Location1"), 2000) { runs++ }

        RoktPlaceholderRegistry.cancelWaits()
        RoktPlaceholderRegistry.register(view(), "Location1")
        scheduler.runPosted()
        scheduler.fireTimeouts()

        assertEquals(0, runs)
    }
}
