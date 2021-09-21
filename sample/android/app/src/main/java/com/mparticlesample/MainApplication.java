package com.mparticlesample;

import android.app.Application;
import android.content.Context;
import com.facebook.react.PackageList;
import com.facebook.react.ReactApplication;
import com.facebook.react.ReactInstanceManager;
import com.facebook.react.ReactNativeHost;
import com.facebook.react.ReactPackage;
import com.facebook.soloader.SoLoader;

import com.mparticle.MParticle;
import com.mparticle.identity.IdentityApiRequest;
import com.mparticle.react.MParticlePackage;
import com.mparticle.MParticleOptions;


import java.lang.reflect.InvocationTargetException;
import java.util.List;


public class MainApplication extends Application implements ReactApplication {

  private final ReactNativeHost mReactNativeHost =
      new ReactNativeHost(this) {
        @Override
        public boolean getUseDeveloperSupport() {
          return BuildConfig.DEBUG;
        }

       @Override
    protected List<ReactPackage> getPackages() {
         @SuppressWarnings("UnnecessaryLocalVariable")
         List<ReactPackage> packages = new PackageList(this).getPackages();
         // Packages that cannot be autolinked yet can be added manually here, for example:
         // packages.add(new MyReactNativePackage());
         packages.add(new MParticlePackage());
         return packages;

    }

        @Override
        protected String getJSMainModuleName() {
          return "index";
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
      .credentials("us1-352af4d005e49047a7bcc78281f33e9c","flR34mIajnAA5F-Ouha7JQF5v0JqFUfo_QjJtM_16VESU2hS0ikp3hRILG70-aBk")
      .logLevel(MParticle.LogLevel.VERBOSE)
      .identify(identityRequest.build())
      .build();

    MParticle.start(options);

    SoLoader.init(this, /* native exopackage */ false);
    initializeFlipper(this, getReactNativeHost().getReactInstanceManager());
  }

  /**
   * Loads Flipper in React Native templates. Call this in the onCreate method with something like
   * initializeFlipper(this, getReactNativeHost().getReactInstanceManager());
   *
   * @param context
   * @param reactInstanceManager
   */
  private static void initializeFlipper(
      Context context, ReactInstanceManager reactInstanceManager) {
    if (BuildConfig.DEBUG) {
      try {
        /*
         We use reflection here to pick up the class that initializes Flipper,
        since Flipper library is not available in release mode
        */
        Class<?> aClass = Class.forName("com.mparticlesample.ReactNativeFlipper");
        aClass
            .getMethod("initializeFlipper", Context.class, ReactInstanceManager.class)
            .invoke(null, context, reactInstanceManager);
      } catch (ClassNotFoundException e) {
        e.printStackTrace();
      } catch (NoSuchMethodException e) {
        e.printStackTrace();
      } catch (IllegalAccessException e) {
        e.printStackTrace();
      } catch (InvocationTargetException e) {
        e.printStackTrace();
      }
    }
  }
}
