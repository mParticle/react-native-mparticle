package com.mparticle.react

import com.facebook.react.TurboReactPackage
import com.facebook.react.bridge.ModuleSpec
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.model.ReactModuleInfo
import com.facebook.react.module.model.ReactModuleInfoProvider
import com.facebook.react.uimanager.ViewManager
import com.mparticle.react.rokt.MPRoktModule
import com.mparticle.react.rokt.MPRoktModuleImpl
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

            MPRoktModuleImpl.MODULE_NAME -> {
                MPRoktModule(reactContext)
            }

            else -> null
        }

    override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> = listOf(RoktLayoutViewManager())

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
            moduleInfos.put(
                MPRoktModuleImpl.MODULE_NAME,
                ReactModuleInfo(
                    MPRoktModuleImpl.MODULE_NAME,
                    MPRoktModuleImpl.MODULE_NAME,
                    true, // canOverrideExistingModule
                    false, // needsEagerInit
                    true, // hasConstants
                    false, // isCxxModule
                    BuildConfig.IS_NEW_ARCHITECTURE_ENABLED, // isTurboModule
                ),
            )
            moduleInfos.toMap()
        }

    override fun getViewManagers(reactContext: ReactApplicationContext): List<ModuleSpec> =
        listOf(
            ModuleSpec.viewManagerSpec { RoktLayoutViewManager() },
        )
}
