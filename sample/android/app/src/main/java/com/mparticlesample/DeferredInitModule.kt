package com.mparticlesample

import android.app.Application
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.mparticle.MParticle
import com.mparticle.MParticleOptions
import com.mparticle.identity.IdentityApiRequest

/**
 * Edge-case example: "deferred initialisation with Turbo Modules".
 *
 * Instead of calling MParticle.start() in MainApplication.onCreate() (the standard,
 * supported integration), JS calls startMParticle() from this native module after the
 * first frame is painted. This reproduces a partner pattern used to shave init cost off
 * app startup -- and exposes an Android-specific race that does NOT occur on iOS:
 *
 *   The Rokt SDK caches its "current Activity" only in onActivityResumed, via an observer
 *   registered during Rokt.init() (which mParticle calls from RoktKit.onKitCreate()). When
 *   init runs AFTER the host Activity has already resumed -- exactly what deferred init does
 *   -- that resume is missed, so overlay/bottom-sheet placements (RoktModalActivity) have no
 *   Activity to launch from until the next resume (the "press home and reopen" workaround).
 *   iOS is immune because it resolves the presenter lazily at execute time.
 *
 * Fixed upstream in the Rokt Android SDK by observing the lifecycle from process start:
 * ROKT/sdk-android-source#1062 and #1063 (v5 backport #1082). This example is kept around
 * as an easy way to re-trigger the scenario and confirm the fix / catch regressions.
 *
 * To enable: flip DEFERRED_INIT_EXAMPLE to true and watch `adb logcat -s DeferredInitRepro`
 * -- the DEFERRED tracker's currentActivity stays null while the EAGER one captures it.
 *
 * (Registered through a legacy ReactPackage; under the New Architecture it is invoked via the
 * TurboModule interop layer. The JS call timing -- after first-frame paint -- is identical to
 * a pure TurboModule, which is what the race depends on.)
 */
class DeferredInitModule(private val reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {

    companion object {
        const val TAG = "DeferredInitRepro"

        /**
         * Master switch for the deferred-init edge case. Keep this `false` so the sample uses the
         * standard eager init in MainApplication.onCreate(); set it to `true` to reproduce the
         * late-init Activity-capture race described above.
         */
        const val DEFERRED_INIT_EXAMPLE = false

        // Registered in Application.onCreate -- the eager path, for contrast.
        var eagerTracker: ActivityTracker? = null
    }

    // Registered at deferred-start time, mirroring Rokt.init()'s late registration.
    private val deferredTracker = ActivityTracker("DEFERRED")

    override fun getName(): String = "DeferredInit"

    @ReactMethod
    fun startMParticle(promise: Promise) {
        if (!DEFERRED_INIT_EXAMPLE) {
            // Standard mode: mParticle was already started in Application.onCreate(); nothing to do.
            promise.resolve("eager-init (deferred example disabled)")
            return
        }

        Log.i(TAG, "startMParticle() called from JS (post first-frame). MParticle.getInstance()=${MParticle.getInstance()}")

        val app = reactContext.applicationContext as Application

        // Mirror Rokt SDK: register the activity observer at init time, NOT at process start.
        app.registerActivityLifecycleCallbacks(deferredTracker)
        Log.i(TAG, "[DEFERRED] tracker registered. currentActivity right now = ${deferredTracker.currentActivity}")

        val identityRequest = IdentityApiRequest.withEmptyUser()
        val options = MParticleOptions.builder(app)
            .credentials("REPLACE_ME", "REPLACE_ME")
            .logLevel(MParticle.LogLevel.VERBOSE)
            .identify(identityRequest.build())
            .build()

        MParticle.start(options)
        Log.i(TAG, "MParticle.start() invoked from native module. getInstance()=${MParticle.getInstance()}")

        // Snapshot the captured activity 2s later: did the deferred observer ever
        // see a resume? (Rokt's currentActivity cache works exactly this way.)
        Handler(Looper.getMainLooper()).postDelayed({
            Log.i(
                TAG,
                "SNAPSHOT after 2s -> EAGER.currentActivity=${eagerTracker?.currentActivity?.localClassName} | " +
                    "DEFERRED.currentActivity=${deferredTracker.currentActivity?.localClassName}"
            )
        }, 2000)

        promise.resolve("started")
    }

    @ReactMethod
    fun reportActivityState(promise: Promise) {
        val msg = "EAGER=${eagerTracker?.currentActivity?.localClassName} | DEFERRED=${deferredTracker.currentActivity?.localClassName}"
        Log.i(TAG, "reportActivityState -> $msg")
        promise.resolve(msg)
    }
}
