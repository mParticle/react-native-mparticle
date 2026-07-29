package com.mparticle.react

import com.facebook.react.TurboReactPackage
import com.facebook.react.bridge.ModuleSpec
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.model.ReactModuleInfo
import com.facebook.react.module.model.ReactModuleInfoProvider
import com.facebook.react.uimanager.ViewManager
import com.mparticle.react.rokt.MPRoktModule
import com.mparticle.react.rokt.RoktLayoutViewManager

class MParticlePackage : TurboReactPackage() {
    override fun getModule(
        name: String,
        reactContext: ReactApplicationContext,
    ): NativeModule? =
        when (name) {
            MParticleModule.MODULE_NAME -> {
                MParticleModule(reactContext)
            }

            ROKT_MODULE_NAME -> {
                if (isRoktKitAvailable) {
                    MPRoktModule(reactContext)
                } else {
                    null
                }
            }

            else -> null
        }

    override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> =
        if (isRoktKitAvailable) {
            listOf(RoktLayoutViewManager())
        } else {
            emptyList()
        }

    override fun getReactModuleInfoProvider() =
        ReactModuleInfoProvider {
            val moduleInfos: MutableMap<String, ReactModuleInfo> =
                HashMap()
            moduleInfos.put(
                MParticleModule.MODULE_NAME,
                ReactModuleInfo(
                    MParticleModule.MODULE_NAME,
                    MParticleModule.MODULE_NAME,
                    true, // canOverrideExistingModule
                    false, // needsEagerInit
                    true, // hasConstants
                    false, // isCxxModule
                    BuildConfig.IS_NEW_ARCHITECTURE_ENABLED, // isTurboModule
                ),
            )
            if (isRoktKitAvailable) {
                moduleInfos.put(
                    ROKT_MODULE_NAME,
                    ReactModuleInfo(
                        ROKT_MODULE_NAME,
                        ROKT_MODULE_NAME,
                        true, // canOverrideExistingModule
                        false, // needsEagerInit
                        true, // hasConstants
                        false, // isCxxModule
                        BuildConfig.IS_NEW_ARCHITECTURE_ENABLED, // isTurboModule
                    ),
                )
            }
            moduleInfos.toMap()
        }

    override fun getViewManagers(reactContext: ReactApplicationContext): List<ModuleSpec> =
        if (isRoktKitAvailable) {
            listOf(
                ModuleSpec.viewManagerSpec { RoktLayoutViewManager() },
            )
        } else {
            emptyList()
        }

    // The Rokt kit's presence on the classpath is fixed for the app's lifetime; compute the
    // reflective check once instead of on every module/view-manager registration call.
    private val isRoktKitAvailable: Boolean by lazy {
        try {
            Class.forName("com.mparticle.kits.RoktEmbeddedView")
            true
        } catch (_: ClassNotFoundException) {
            false
        } catch (_: LinkageError) {
            false
        }
    }

    private companion object {
        const val ROKT_MODULE_NAME = "RNMPRokt"
    }
}
