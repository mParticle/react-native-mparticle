package com.mparticlesample;

import android.app.Application;
import android.util.Log;

import com.facebook.react.ReactApplication;
import com.mparticle.MParticle;
import com.mparticle.identity.IdentityApiRequest;
import com.mparticle.react.MParticlePackage;
import com.facebook.react.ReactInstanceManager;
import com.facebook.react.ReactNativeHost;
import com.facebook.react.ReactPackage;
import com.facebook.react.shell.MainReactPackage;
import com.facebook.soloader.SoLoader;

import java.util.Arrays;
import java.util.List;

import com.mparticle.MParticleOptions;
import com.mparticle.identity.BaseIdentityTask;

public class MainApplication extends Application implements ReactApplication {

  private final ReactNativeHost mReactNativeHost = new ReactNativeHost(this) {
    @Override
    public boolean getUseDeveloperSupport() {
      return BuildConfig.DEBUG;
    }

    @Override
    protected List<ReactPackage> getPackages() {
      return Arrays.<ReactPackage>asList(
          new MainReactPackage(),
            new MParticlePackage()
      );
    }
  };

  @Override
  public ReactNativeHost getReactNativeHost() {
    return mReactNativeHost;
  }

  @Override
  public void onCreate() {
    super.onCreate();

    IdentityApiRequest.Builder identityRequest = IdentityApiRequest.withEmptyUser();

    MParticleOptions options = MParticleOptions.builder(this)
      .credentials("REPLACE ME WITH KEY","REPLACE ME WITH SECRET")
      .logLevel(MParticle.LogLevel.VERBOSE)
      .identify(identityRequest.build())
      .build();

    MParticle.start(options);
    SoLoader.init(this, /* native exopackage */ false);
  }
}
