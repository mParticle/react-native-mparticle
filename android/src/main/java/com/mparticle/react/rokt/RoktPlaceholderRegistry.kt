package com.mparticle.react.rokt

import android.os.Handler
import android.os.Looper
import android.view.View
import java.lang.ref.WeakReference

/**
 * Maps a `RoktLayoutView`'s `placeholderName` to its mounted native view, so
 * `selectPlacements` can resolve placeholders by name instead of a `findNodeHandle` react tag.
 *
 * UI thread only: views register from the view manager and are resolved inside
 * `runOnUiThread` / `addUIBlock`, so no locking.
 *
 * A name keeps every live view registered under it (newest last) rather than only the latest,
 * because stacked screens can each mount the same placeholder name: popping the top screen must
 * leave the one underneath resolvable.
 *
 * Typed as [View] rather than `RoktEmbeddedView` because the Rokt kit is compile-only; callers
 * check the type when resolving.
 */
internal object RoktPlaceholderRegistry {
    // Linear scan over a handful of views; global across React hosts, key by surface
    // if a brownfield app ever mounts the same name in two surfaces at once.
    private val views = HashMap<String, MutableList<WeakReference<View>>>()

    /** Posts work to the UI thread; swapped in unit tests, which have no main looper. */
    internal interface Scheduler {
        fun post(runnable: Runnable)

        fun postDelayed(
            runnable: Runnable,
            delayMillis: Long,
        )

        fun cancel(runnable: Runnable)
    }

    internal var scheduler: Scheduler =
        object : Scheduler {
            private val handler by lazy { Handler(Looper.getMainLooper()) }

            override fun post(runnable: Runnable) {
                handler.post(runnable)
            }

            override fun postDelayed(
                runnable: Runnable,
                delayMillis: Long,
            ) {
                handler.postDelayed(runnable, delayMillis)
            }

            override fun cancel(runnable: Runnable) {
                handler.removeCallbacks(runnable)
            }
        }

    private class Wait(
        val names: Collection<String>,
        val onReady: () -> Unit,
        val onDiscard: () -> Unit,
    ) {
        lateinit var timeout: Runnable
    }

    // Pending selectPlacements calls waiting for their placeholders to mount, keyed by caller.
    private val waits = HashMap<String, Wait>()

    /** Registers [view] under [name], moving it off any name it was previously registered under. */
    fun register(
        view: View,
        name: String?,
    ) {
        unregister(view)
        if (!name.isNullOrEmpty()) {
            views.getOrPut(name) { mutableListOf() }.add(WeakReference(view))
            completeSatisfiedWaits()
        }
    }

    fun unregister(view: View) {
        val iterator = views.values.iterator()
        while (iterator.hasNext()) {
            val refs = iterator.next()
            refs.removeAll { it.get().let { registered -> registered == null || registered === view } }
            if (refs.isEmpty()) {
                iterator.remove()
            }
        }
    }

    /** The newest view attached to a window, else the newest still alive. */
    fun lookup(name: String): View? {
        val live = views[name]?.mapNotNull { it.get() } ?: return null
        return live.lastOrNull { it.isAttachedToWindow } ?: live.lastOrNull()
    }

    /**
     * Runs [onReady] on the UI thread once every name in [names] has a registered view, or after
     * [timeoutMillis], whichever comes first. A new wait with the same [key] replaces the previous
     * one; a replaced or cancelled wait never runs [onReady] and runs [onDiscard] on the UI thread
     * instead, so the caller can report the dropped request.
     */
    fun awaitNames(
        key: String,
        names: Collection<String>,
        timeoutMillis: Long,
        onDiscard: () -> Unit,
        onReady: () -> Unit,
    ) {
        waits.remove(key)?.let { discard(it) }
        val wait = Wait(names, onReady, onDiscard)
        wait.timeout = Runnable { if (waits[key] === wait) complete(key) }
        waits[key] = wait
        if (allRegistered(names)) {
            complete(key)
        } else {
            scheduler.postDelayed(wait.timeout, timeoutMillis)
        }
    }

    /** Drops every pending wait, running its onDiscard instead of onReady. */
    fun cancelWaits() {
        val cancelled = waits.values.toList()
        waits.clear()
        cancelled.forEach { discard(it) }
    }

    private fun discard(wait: Wait) {
        scheduler.cancel(wait.timeout)
        scheduler.post { wait.onDiscard() }
    }

    private fun allRegistered(names: Collection<String>) = names.all { lookup(it) != null }

    private fun completeSatisfiedWaits() {
        waits.filterValues { allRegistered(it.names) }.keys.forEach { complete(it) }
    }

    private fun complete(key: String) {
        val wait = waits.remove(key) ?: return
        scheduler.cancel(wait.timeout)
        // Posted: registration happens mid-mount, and the Rokt SDK mutates the placeholder view
        // hierarchy, so it must not run inside the mount pass.
        scheduler.post { wait.onReady() }
    }
}
