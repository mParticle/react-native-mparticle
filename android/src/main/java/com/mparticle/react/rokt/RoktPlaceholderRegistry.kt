package com.mparticle.react.rokt

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
    // ponytail: linear scan over a handful of views; global across React hosts, key by surface
    // if a brownfield app ever mounts the same name in two surfaces at once.
    private val views = HashMap<String, MutableList<WeakReference<View>>>()

    /** Registers [view] under [name], moving it off any name it was previously registered under. */
    fun register(
        view: View,
        name: String?,
    ) {
        unregister(view)
        if (!name.isNullOrEmpty()) {
            views.getOrPut(name) { mutableListOf() }.add(WeakReference(view))
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
}
