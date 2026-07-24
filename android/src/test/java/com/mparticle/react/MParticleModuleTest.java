package com.mparticle.react;

import com.facebook.react.bridge.ReactApplicationContext;
import com.mparticle.BaseEvent;
import com.mparticle.MParticle;
import com.mparticle.react.testutils.MockMap;

import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mockito;
import org.mockito.junit.MockitoJUnitRunner;

import java.util.HashMap;
import java.util.Map;

import static org.junit.Assert.assertEquals;

@RunWith(MockitoJUnitRunner.class)
public class MParticleModuleTest {
    private MParticle mParticle;
    private MParticleModule module;

    @Before
    public void before() {
        mParticle = Mockito.mock(MParticle.class);
        MParticle.setInstance(mParticle);
        module = new MParticleModule(Mockito.mock(ReactApplicationContext.class));
    }

    @Test
    public void logEventConvertsNullCustomAttributeToEmptyString() {
        Map<String, Object> attributes = new HashMap<>();
        attributes.put("coupon_code", null);

        module.logEvent("Purchase", MParticle.EventType.Other.getValue(), new MockMap(attributes));

        ArgumentCaptor<BaseEvent> eventCaptor = ArgumentCaptor.forClass(BaseEvent.class);
        Mockito.verify(mParticle).logEvent(eventCaptor.capture());
        assertEquals("", eventCaptor.getValue().getCustomAttributes().get("coupon_code"));
    }
}
