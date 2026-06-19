package com.mparticlesample

import android.app.Activity
import android.app.Application
import android.os.Bundle
import android.util.Log
import java.lang.ref.WeakReference

/**
 * Mirrors the Rokt Android SDK's `ActivityLifeCycleObserver` caching strategy:
 * the "current activity" is captured ONLY in onActivityResumed. This is the
 * mechanism RoktModalActivity (overlay / bottom-sheet placements) depends on.
 *
 * We register two trackers in the repro:
 *   - EAGER  : registered in Application.onCreate (before MainActivity exists)
 *   - DEFERRED: registered when MParticle.start() is called at first-frame paint
 *
 * If the deferred tracker is registered AFTER the host Activity has already
 * resumed, it never sees onActivityResumed and currentActivity stays null --
 * exactly the failure ROKT/sdk-android-source#1062 / #1063 fix.
 */
class ActivityTracker(private val label: String) : Application.ActivityLifecycleCallbacks {

    @Volatile
    private var currentActivityRef: WeakReference<Activity>? = null

    val currentActivity: Activity?
        get() = currentActivityRef?.get()

    companion object {
        const val TAG = "DeferredInitRepro"
    }

    override fun onActivityResumed(activity: Activity) {
        currentActivityRef = WeakReference(activity)
        Log.i(TAG, "[$label] onActivityResumed -> captured ${activity.localClassName}")
    }

    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {
        Log.i(TAG, "[$label] onActivityCreated ${activity.localClassName}")
    }

    override fun onActivityStarted(activity: Activity) {}
    override fun onActivityPaused(activity: Activity) {}
    override fun onActivityStopped(activity: Activity) {}
    override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}
    override fun onActivityDestroyed(activity: Activity) {}
}
