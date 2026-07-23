package com.mparticle.react.rokt

import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.viewmanagers.RoktNativeLayoutManagerDelegate
import com.facebook.react.viewmanagers.RoktNativeLayoutManagerInterface
import com.mparticle.kits.RoktEmbeddedView

class RoktLayoutViewManager :
    SimpleViewManager<RoktEmbeddedView>(),
    RoktNativeLayoutManagerInterface<RoktEmbeddedView> {
    private val impl = RoktLayoutViewManagerImpl()

    // Fabric routes props through the codegen-generated delegate; without this override the
    // base ViewManager logs "ViewManager using codegen must override getDelegate method".
    private val delegate = RoktNativeLayoutManagerDelegate<RoktEmbeddedView, RoktLayoutViewManager>(this)

    override fun getDelegate(): ViewManagerDelegate<RoktEmbeddedView> = delegate

    override fun getName(): String = impl.getName()

    override fun createViewInstance(reactContext: ThemedReactContext): RoktEmbeddedView =
        impl.createViewInstance(reactContext)

    override fun setPlaceholderName(view: RoktEmbeddedView?, value: String?) {
        impl.setPlaceholderName(view, value)
    }
}
