package com.mparticle.react.rokt

import com.facebook.react.common.MapBuilder
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewGroupManager
import com.mparticle.rokt.RoktEmbeddedView

class RoktLayoutViewManager : SimpleViewManager<RoktEmbeddedView>() {
    private val impl = RoktLayoutViewManagerImpl()

    override fun getName(): String = impl.getName()

    override fun createViewInstance(reactContext: ThemedReactContext): RoktEmbeddedView = impl.createViewInstance(reactContext)

    override fun getExportedCustomDirectEventTypeConstants(): Map<String, Any>? =
        MapBuilder
            .builder<String, Any>()
            .put(
                RoktLayoutViewManagerImpl.EVENT_HEIGHT_CHANGED,
                MapBuilder.of("registrationName", RoktLayoutViewManagerImpl.EVENT_HEIGHT_CHANGED),
            ).put(
                RoktLayoutViewManagerImpl.EVENT_MARGIN_CHANGED,
                MapBuilder.of("registrationName", RoktLayoutViewManagerImpl.EVENT_MARGIN_CHANGED),
            ).build()

    //override fun needsCustomLayoutForChildren(): Boolean = false

    fun setPlaceholderName(
        view: RoktEmbeddedView?,
        value: String?,
    ) {
        impl.setPlaceholderName(view, value)
    }
}
