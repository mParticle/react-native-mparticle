package com.mparticle.react.rokt

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactContext
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.events.RCTEventEmitter
import com.mparticle.rokt.RoktEmbeddedView
import com.mparticle.rokt.RoktLayoutDimensionCallBack

class RoktLayoutViewManagerImpl {
    companion object {
        const val REACT_CLASS = "RoktNativeLayout"
        const val EVENT_HEIGHT_CHANGED = "onLayoutHeightChanged"
        const val EVENT_MARGIN_CHANGED = "onLayoutMarginChanged"
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

                override fun onMarginChanged(
                    start: Int,
                    top: Int,
                    end: Int,
                    bottom: Int,
                ) {
                    changeMargin(widget.context as ReactContext, widget.id, start, top, end, bottom)
                }
            }
    }

    fun changeHeight(
        context: ReactContext,
        height: Int,
        id: Int,
    ) {
        val event = Arguments.createMap()
        event.putString("height", height.toString())
        context
            .getJSModule(RCTEventEmitter::class.java)
            .receiveEvent(id, EVENT_HEIGHT_CHANGED, event)
    }

    fun changeMargin(
        context: ReactContext,
        id: Int,
        start: Int,
        top: Int,
        end: Int,
        bottom: Int,
    ) {
        val event = Arguments.createMap()
        event.putString("marginLeft", start.toString())
        event.putString("marginTop", top.toString())
        event.putString("marginRight", end.toString())
        event.putString("marginBottom", bottom.toString())
        context
            .getJSModule(RCTEventEmitter::class.java)
            .receiveEvent(id, EVENT_MARGIN_CHANGED, event)
    }
}
