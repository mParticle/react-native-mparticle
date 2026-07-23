package com.mparticle.react.rokt

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.events.Event
import com.mparticle.kits.RoktEmbeddedView
import com.mparticle.kits.RoktLayoutDimensionCallBack

class RoktLayoutViewManagerImpl {
    companion object {
        const val REACT_CLASS = "RoktNativeLayout"
        const val EVENT_HEIGHT_CHANGED = "onLayoutHeightChanged"
    }

    fun getName(): String = REACT_CLASS

    fun createViewInstance(reactContext: ThemedReactContext): RoktEmbeddedView {
        val widget = RoktEmbeddedView(reactContext)
        setUpWidgetListeners(widget)
        return widget
    }

    fun setPlaceholderName(
        view: RoktEmbeddedView?,
        value: String?,
    ) {
        view?.tag = value
    }

    private fun setUpWidgetListeners(widget: RoktEmbeddedView) {
        widget.dimensionCallBack =
            object : RoktLayoutDimensionCallBack {
                override fun onHeightChanged(height: Int) {
                    changeHeight(widget.context as ReactContext, height, widget.id)
                }
            }
    }

    fun changeHeight(
        context: ReactContext,
        height: Int,
        id: Int,
    ) {
        // Use the EventDispatcher API instead of getJSModule(RCTEventEmitter), which is
        // unsupported under the New Architecture bridgeless runtime (RN >= 0.76). This path
        // works on both Paper and Fabric across all supported RN versions.
        val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, id) ?: return
        val surfaceId = UIManagerHelper.getSurfaceId(context)
        dispatcher.dispatchEvent(OnLayoutHeightChangedEvent(surfaceId, id, height))
    }

    private class OnLayoutHeightChangedEvent(
        surfaceId: Int,
        viewId: Int,
        private val height: Int,
    ) : Event<OnLayoutHeightChangedEvent>(surfaceId, viewId) {
        override fun getEventName(): String = RoktLayoutViewManagerImpl.EVENT_HEIGHT_CHANGED

        override fun getEventData(): WritableMap = Arguments.createMap().apply { putString("height", height.toString()) }
    }
}
