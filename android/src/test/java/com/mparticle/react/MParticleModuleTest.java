package com.mparticle.react;

import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReactApplicationContext;
import com.mparticle.BaseEvent;
import com.mparticle.MParticle;
import com.mparticle.commerce.CommerceEvent;
import com.mparticle.commerce.Product;
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
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;

@RunWith(MockitoJUnitRunner.class)
public class MParticleModuleTest {
    private static final int ADD_TO_CART_ACTION = 1;
    private static final int PURCHASE_ACTION = 7;

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

    @Test
    public void logCommerceEventLogsAddToCartWithoutTransactionAttributes() {
        ReadableArray products = products(
                product("Shirt", "shirt-1", 25.0),
                product("Shoes", "shoes-1", 50.0));

        module.logCommerceEvent(commerceEvent(ADD_TO_CART_ACTION, products, null));

        CommerceEvent event = captureCommerceEvent();
        assertEquals(Product.ADD_TO_CART, event.getProductAction());
        assertNotNull(event.getProducts());
        assertEquals(2, event.getProducts().size());
        assertNotNull(event.getTransactionAttributes());
        assertNull(event.getTransactionAttributes().getId());
    }

    @Test
    public void logCommerceEventLogsAddToCartWithEmptyTransactionAttributes() {
        ReadableMap transactionAttributes = Mockito.mock(ReadableMap.class);

        module.logCommerceEvent(commerceEvent(
                ADD_TO_CART_ACTION,
                products(product("Shirt", "shirt-1", 25.0)),
                transactionAttributes));

        CommerceEvent event = captureCommerceEvent();
        assertEquals(Product.ADD_TO_CART, event.getProductAction());
        assertNotNull(event.getTransactionAttributes());
        assertNull(event.getTransactionAttributes().getId());
    }

    @Test
    public void logCommerceEventLogsAddToCartWithEmptyTransactionId() {
        ReadableMap transactionAttributes = transactionAttributes("");

        module.logCommerceEvent(commerceEvent(
                ADD_TO_CART_ACTION,
                products(product("Shirt", "shirt-1", 25.0)),
                transactionAttributes));

        CommerceEvent event = captureCommerceEvent();
        assertEquals(Product.ADD_TO_CART, event.getProductAction());
        assertEquals("", event.getTransactionAttributes().getId());
    }

    @Test
    public void logCommerceEventAttachesValidPurchaseTransactionAttributes() {
        ReadableMap transactionAttributes = transactionAttributes("order-123");

        module.logCommerceEvent(commerceEvent(
                PURCHASE_ACTION,
                products(product("Shirt", "shirt-1", 25.0)),
                transactionAttributes));

        CommerceEvent event = captureCommerceEvent();
        assertEquals(Product.PURCHASE, event.getProductAction());
        assertEquals("order-123", event.getTransactionAttributes().getId());
    }

    @Test
    public void logCommerceEventPassesPurchaseWithoutTransactionAttributesToNativeSdk() {
        module.logCommerceEvent(commerceEvent(
                PURCHASE_ACTION,
                products(product("Shirt", "shirt-1", 25.0)),
                null));

        CommerceEvent event = captureCommerceEvent();
        assertEquals(Product.PURCHASE, event.getProductAction());
        assertNotNull(event.getTransactionAttributes());
        assertNull(event.getTransactionAttributes().getId());
    }

    private CommerceEvent captureCommerceEvent() {
        ArgumentCaptor<BaseEvent> eventCaptor = ArgumentCaptor.forClass(BaseEvent.class);
        Mockito.verify(mParticle).logEvent(eventCaptor.capture());
        return (CommerceEvent) eventCaptor.getValue();
    }

    private ReadableMap commerceEvent(
            int productActionType,
            ReadableArray products,
            ReadableMap transactionAttributes) {
        ReadableMap event = Mockito.mock(ReadableMap.class);
        Mockito.when(event.hasKey("productActionType")).thenReturn(true);
        Mockito.when(event.getInt("productActionType")).thenReturn(productActionType);
        Mockito.when(event.getArray("products")).thenReturn(products);
        Mockito.when(event.getMap("transactionAttributes")).thenReturn(transactionAttributes);
        return event;
    }

    private ReadableArray products(ReadableMap... products) {
        ReadableArray productArray = Mockito.mock(ReadableArray.class);
        Mockito.when(productArray.size()).thenReturn(products.length);
        for (int i = 0; i < products.length; i++) {
            Mockito.when(productArray.getMap(i)).thenReturn(products[i]);
        }
        return productArray;
    }

    private ReadableMap product(String name, String sku, double price) {
        ReadableMap product = Mockito.mock(ReadableMap.class);
        Mockito.when(product.getString("name")).thenReturn(name);
        Mockito.when(product.getString("sku")).thenReturn(sku);
        Mockito.when(product.getDouble("price")).thenReturn(price);
        return product;
    }

    private ReadableMap transactionAttributes(String transactionId) {
        ReadableMap transactionAttributes = Mockito.mock(ReadableMap.class);
        Mockito.when(transactionAttributes.hasKey("transactionId")).thenReturn(true);
        Mockito.when(transactionAttributes.getString("transactionId")).thenReturn(transactionId);
        return transactionAttributes;
    }
}
