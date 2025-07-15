package com.mparticle.react.rokt

import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.RoktNativeLayoutManagerInterface
import com.mparticle.rokt.RoktEmbeddedView

class RoktLayoutViewManager : SimpleViewManager<RoktEmbeddedView>(),
    RoktNativeLayoutManagerInterface<RoktEmbeddedView> {
    private val impl = RoktLayoutViewManagerImpl()

    override fun getName(): String = impl.getName()

    override fun createViewInstance(reactContext: ThemedReactContext): RoktEmbeddedView =
        impl.createViewInstance(reactContext)

    @ReactProp(name = "placeholderName")
    override fun setPlaceholderName(view: RoktEmbeddedView?, value: String?) {
        impl.setPlaceholderName(view, value)
    }
}
