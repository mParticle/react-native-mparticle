package com.mparticlesample

import android.app.Application
import com.facebook.react.PackageList
import com.facebook.react.ReactApplication
import com.facebook.react.ReactHost
import com.facebook.react.ReactNativeApplicationEntryPoint.loadReactNative
import com.facebook.react.defaults.DefaultReactHost.getDefaultReactHost
import com.mparticle.MParticle
import com.mparticle.MParticleOptions
import com.mparticle.identity.IdentityApiRequest
import com.mparticle.react.MParticlePackage

class MainApplication : Application(), ReactApplication {

    override val reactHost: ReactHost by lazy {
        getDefaultReactHost(
            context = applicationContext,
            packageList =
            PackageList(this).packages.apply {
                add(MParticlePackage())
                add(DeferredInitPackage())
            },
        )
    }

    override fun onCreate() {
        super.onCreate()
        loadReactNative(this)

        if (DeferredInitModule.DEFERRED_INIT_EXAMPLE) {
            // Deferred-init edge case (see DeferredInitModule for the full explanation).
            // Register an eager activity tracker at process start -- before the first
            // Activity is created -- so logcat can contrast it against the deferred path.
            // MParticle.start() is intentionally NOT called here; DeferredInitModule
            // starts it at first-frame paint instead (see index.js).
            val eager = ActivityTracker("EAGER")
            registerActivityLifecycleCallbacks(eager)
            DeferredInitModule.eagerTracker = eager
        } else {
            // Standard, supported integration: start mParticle in Application.onCreate().
            val identityRequest = IdentityApiRequest.withEmptyUser()
            val options = MParticleOptions.builder(this)
                .credentials("REPLACE_ME", "REPLACE_ME")
                .logLevel(MParticle.LogLevel.VERBOSE)
                .identify(identityRequest.build())
                .build()
            MParticle.start(options)
        }
    }
}
