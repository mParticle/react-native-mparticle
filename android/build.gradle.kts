plugins {
    id("com.android.library")
}

android {
    compileSdk = 31

    defaultConfig {
        minSdk = 16
        targetSdk = 31
        version = "1.0"
    }
    buildTypes {
        release {
            isMinifyEnabled = false
        }
    }
    adbOptions {
       timeOutInMs = 10 * 60 * 1000
       installOptions = listOf("-d","-t")
   }
}

repositories {
    mavenCentral()
    google()
}

dependencies {
    compileOnly("com.facebook.react:react-native:0.68.2")

    //
    // In your app, you should include mParticle core like this:
    //
    //   compile 'com.mparticle:android-core:REPLACEME'
    //
    // (See https://github.com/mparticle/mparticle-android-sdk for the latest version)
    //
    compileOnly("com.mparticle:android-core:[5.9.3, )")

    //
    // And, if you want to include kits, you can do so as follows:
    //
    //   compile 'com.mparticle:android-example-kit:REPLACEME'
    //

    testImplementation("org.mockito:mockito-android:2.18.3")
    testImplementation("androidx.annotation:annotation:1.3.0")
    testImplementation("junit:junit:4.13.2")
    testImplementation(files("libs/java-json.jar"))

    testImplementation("com.mparticle:android-core:5.39.0")
    testImplementation("com.facebook.react:react-native:0.20.1")

}
