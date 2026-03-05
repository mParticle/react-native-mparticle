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

class MainApplication : Application(), ReactApplication {

  override val reactHost: ReactHost by lazy {
    getDefaultReactHost(
      context = applicationContext,
      packageList =
        PackageList(this).packages.apply {
          // Packages that cannot be autolinked yet can be added manually here, for example:
          // add(MyReactNativePackage())
        },
    )
  }

  override fun onCreate() {
    super.onCreate()
    loadReactNative(this)

    val identityRequest = IdentityApiRequest.withEmptyUser()

    val options = MParticleOptions.builder(this)
      .credentials("REPLACE ME","REPLACE ME")
      .logLevel(MParticle.LogLevel.VERBOSE)
      .identify(identityRequest.build())
      .build()

    MParticle.start(options)
  }
}
