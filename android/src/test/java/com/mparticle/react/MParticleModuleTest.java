package com.mparticle.react;

import android.support.annotation.NonNull;
import android.support.annotation.Nullable;

import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableType;
import com.mparticle.MParticle;
import com.mparticle.UserAttributeListener;
import com.mparticle.commerce.Cart;
import com.mparticle.consent.ConsentState;
import com.mparticle.identity.IdentityApi;
import com.mparticle.identity.MParticleUser;
import com.mparticle.react.testutils.Mutable;

import org.junit.Before;
import org.junit.Test;
import org.mockito.Mockito;

import java.util.HashMap;
import java.util.Map;
import java.util.Random;

import static junit.framework.TestCase.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

public class MParticleModuleTest {
    MParticleModule module;
    Random random = new Random();

    @Before
    public void before() {
        MParticle.setInstance(Mockito.mock(MParticle.class));
        Mockito.when(MParticle.getInstance().Identity()).thenReturn(Mockito.mock(IdentityApi.class));
        Mockito.when(MParticle.getInstance().Identity().getUser(null)).thenReturn(null);
        module = new MParticleModule(Mockito.mock(ReactApplicationContext.class));
    }

    @Test
    public void tesNullMParticleUserSetters() {
        Exception exception = null;
        try {
            module.setUserAttribute(null, "key", "values");
            module.setUserTag(null, "test");
            module.setUserAttributeArray(null, "keuy", new MockReadableArray());
        } catch (Exception e) {
            exception = e;
        }
        assertNull(exception);
    }

    @Test
    public void testSetUserAttribute() {
        String testKey = "test key";
        String testValue = "test value";

        final Mutable<String> uaKey = new Mutable<>();
        final Mutable<Object> uaValue = new Mutable<>();
        MParticleUser mockUser = new MockMParticleUser() {
            @Override
            public boolean setUserAttribute(@NonNull String s, @NonNull Object o) {
                uaKey.value = s;
                uaValue.value = o;
                return true;
            }
        };
        Mockito.when(MParticle.getInstance().Identity().getUser(Mockito.anyLong())).thenReturn(mockUser);

        module.setUserAttribute("1", testKey, testValue);

        assertEquals(testKey, uaKey.value);
        assertEquals(testValue, uaValue.value);
    }

    @Test
    public void getUserIdentitiesTest() {
        final Map<MParticle.IdentityType, String> identities = new HashMap<>();
        for (MParticle.IdentityType identityType: MParticle.IdentityType.values()) {
            identities.put(identityType, random.nextInt() + "");
        }
        MParticleUser mockUser = new MockMParticleUser() {
            @NonNull
            @Override
            public Map<MParticle.IdentityType, String> getUserIdentities() {
                return identities;
            }
        };

        Mockito.when(MParticle.getInstance().Identity().getUser(Mockito.anyLong())).thenReturn(mockUser);

        final Mutable<Map<MParticle.IdentityType, String>> callbackResult = new Mutable<>();
        module.getUserIdentities("1", new Callback() {
            @Override
            public void invoke(Object... args) {
                assertEquals(1, args.length);
                callbackResult.value = (Map<MParticle.IdentityType,String>)args[0];
            }
        });

        assertNotNull(callbackResult.value);
        assertEquals(identities.size(), callbackResult.value.size());

        for (Map.Entry<MParticle.IdentityType, String> entry: identities.entrySet()) {
            assertEquals(entry.getValue(), callbackResult.value.get(entry.getKey()));
        }
    }

    @Test
    public void testGetUserIdentitiesNullUser() {
        final Mutable<Boolean> callbackInvoked = new Mutable<>(false);

        module.getUserIdentities(null, new Callback() {
            @Override
            public void invoke(Object... args) {
                assertEquals(0, args.length);
                callbackInvoked.value = true;
            }
        });

        assertTrue(callbackInvoked.value);
    }

    @Test
    public void testSetUserTag() {
        final Mutable<String> tag = new Mutable<>();
        String testTag = "testTag";

        MParticleUser mockUser = new MockMParticleUser() {
            @Override
            public boolean setUserTag(@NonNull String s) {
                tag.value = s;
                return true;
            }
        };

        Mockito.when(MParticle.getInstance().Identity().getUser(Mockito.anyLong())).thenReturn(mockUser);

        module.setUserTag("1", testTag);

        assertEquals(testTag, tag.value);
    }

    @Test
    public void testGetCurrentUser() {
        final Mutable<Boolean> callbackCalled = new Mutable<>(false);
        final Long mockId = random.nextLong();

        MParticleUser mockUser = new MockMParticleUser() {
            @NonNull
            @Override
            public long getId() {
                return mockId;
            }
        };
        Mockito.when(MParticle.getInstance().Identity().getCurrentUser()).thenReturn(mockUser);
        module.getCurrentUserWithCompletion(new Callback() {
            @Override
            public void invoke(Object... args) {
                assertNull(args[0]);
                assertEquals(mockId.toString(), args[1]);
                callbackCalled.value = true;
            }
        });

        assertTrue(callbackCalled.value);
        callbackCalled.value = false;

        Mockito.when(MParticle.getInstance().Identity().getCurrentUser()).thenReturn(null);
        module.getCurrentUserWithCompletion(new Callback() {
            @Override
            public void invoke(Object... args) {
                assertNull(args[0]);
                assertNull(args[1]);
                callbackCalled.value = true;
            }
        });
        assertTrue(callbackCalled.value);
    }

    class MockMParticleUser implements MParticleUser {

        @NonNull
        @Override
        public long getId() {
            return 0;
        }

        @NonNull
        @Override
        public Cart getCart() {
            return null;
        }

        @NonNull
        @Override
        public Map<String, Object> getUserAttributes() {
            return null;
        }

        @Nullable
        @Override
        public Map<String, Object> getUserAttributes(@Nullable UserAttributeListener userAttributeListener) {
            return null;
        }

        @Override
        public boolean setUserAttributes(@NonNull Map<String, Object> map) {
            return false;
        }

        @NonNull
        @Override
        public Map<MParticle.IdentityType, String> getUserIdentities() {
            return null;
        }

        @Override
        public boolean setUserAttribute(@NonNull String s, @NonNull Object o) {
            return false;
        }

        @Override
        public boolean setUserAttributeList(@NonNull String s, @NonNull Object o) {
            return false;
        }

        @Override
        public boolean incrementUserAttribute(@NonNull String s, int i) {
            return false;
        }

        @Override
        public boolean removeUserAttribute(@NonNull String s) {
            return false;
        }

        @Override
        public boolean setUserTag(@NonNull String s) {
            return false;
        }

        @NonNull
        @Override
        public ConsentState getConsentState() {
            return null;
        }

        @Override
        public void setConsentState(@Nullable ConsentState consentState) {

        }

        @Override
        public boolean isLoggedIn() {
            return false;
        }

        @Override
        public long getFirstSeenTime() {
            return 0;
        }

        @Override
        public long getLastSeenTime() {
            return 0;
        }
    }

    class MockReadableArray implements ReadableArray {

        @Override
        public int size() {
            return 0;
        }

        @Override
        public boolean isNull(int index) {
            return false;
        }

        @Override
        public boolean getBoolean(int index) {
            return false;
        }

        @Override
        public double getDouble(int index) {
            return 0;
        }

        @Override
        public int getInt(int index) {
            return 0;
        }

        @Override
        public String getString(int index) {
            return null;
        }

        @Override
        public ReadableArray getArray(int index) {
            return null;
        }

        @Override
        public ReadableMap getMap(int index) {
            return null;
        }

        @Override
        public ReadableType getType(int index) {
            return null;
        }
    }
}
