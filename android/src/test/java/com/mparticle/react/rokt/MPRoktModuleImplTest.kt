package com.mparticle.react.rokt

import com.facebook.react.bridge.ReactApplicationContext
import com.mparticle.MParticle
import com.mparticle.WrapperSdk
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mockito
import org.mockito.junit.MockitoJUnitRunner

@RunWith(MockitoJUnitRunner::class)
class MPRoktModuleImplTest {
    @Test
    fun `setWrapperSdk is reported on module creation`() {
        val mParticle = Mockito.mock(MParticle::class.java)
        MParticle.setInstance(mParticle)

        MPRoktModuleImpl(Mockito.mock(ReactApplicationContext::class.java))

        Mockito.verify(mParticle).setWrapperSdk(WrapperSdk.WrapperSdkReactNative, "")
    }

    @Test
    fun `setWrapperSdk reports wrapper type on each call`() {
        val mParticle = Mockito.mock(MParticle::class.java)
        MParticle.setInstance(mParticle)
        val impl = MPRoktModuleImpl(Mockito.mock(ReactApplicationContext::class.java))

        impl.setWrapperSdk()
        impl.setWrapperSdk()

        Mockito.verify(mParticle, Mockito.times(3)).setWrapperSdk(WrapperSdk.WrapperSdkReactNative, "")
    }

    @Test
    fun `setWrapperSdk does not crash when MParticle is not started`() {
        MParticle.setInstance(null)

        val impl = MPRoktModuleImpl(Mockito.mock(ReactApplicationContext::class.java))

        impl.setWrapperSdk()
    }
}
