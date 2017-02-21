package com.mparticle.react;

import com.facebook.react.bridge.LifecycleEventListener;
import com.mparticle.*;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.*;
import com.mparticle.commerce.CommerceApi;
import com.mparticle.commerce.CommerceEvent;
import com.mparticle.commerce.Impression;
import com.mparticle.commerce.Product;
import com.mparticle.commerce.Promotion;

import java.util.ArrayList;
import java.util.Dictionary;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class MParticleModule extends ReactContextBaseJavaModule {

    ReactApplicationContext reactContext;

    public MParticleModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
    }

    @Override
    public String getName() {
        return "MParticle";
    }

    @ReactMethod
    public void logEvent(final String name, int type, final ReadableMap attributesMap) {
        Map<String, String> attributes = ConvertStringMap(attributesMap);
        MParticle.EventType eventType = ConvertEventType(type);
        MParticle.getInstance().logEvent(name, eventType, attributes);
    }

    @ReactMethod
    public void logCommerceEvent(final ReadableMap map) {
        CommerceEvent commerceEvent = ConvertCommerceEvent(map);
        MParticle.getInstance().logEvent(commerceEvent);
    }

    @ReactMethod
    public void logScreenEvent(final String event, final ReadableMap attributesMap) {
        Map<String, String> attributes = ConvertStringMap(attributesMap);
        MParticle.getInstance().logScreen(event, attributes);
    }

    @ReactMethod
    public void setUserAttribute(final String userAttribute, final String value) {
        MParticle.getInstance().setUserAttribute(userAttribute, value);
    }

    @ReactMethod
    public void setUserAttributeList(final String key, final ReadableArray values) {
     if (values != null) {
        List<String> list = new ArrayList<String>();
        for (int i = 0; i < values.size(); ++i) {
            list.add(values.getString(i));
        }
        MParticle.getInstance().setUserAttributeList(key, list);
      }
    }

    @ReactMethod
    public void setUserTag(final String tag) {
        MParticle.getInstance().setUserTag(tag);
    }

    @ReactMethod
    public void removeUserAttribute(final String key) {
        MParticle.getInstance().removeUserAttribute(key);
    }

    @ReactMethod
    public void setUserIdentity(final String identity, int type) {
      MParticle.IdentityType identityType = MParticle.IdentityType.parseInt(type);
      MParticle.getInstance().setUserIdentity(identity, identityType);
    }

    private static CommerceEvent ConvertCommerceEvent(ReadableMap map) {
        Boolean isProductAction = map.hasKey("productActionType");
        Boolean isPromotion = map.hasKey("promotionActionType");
        Boolean isImpression = map.hasKey("promotionActionType");

        if (!isProductAction && !isPromotion && !isImpression) {
            throw new AssertionError("Invalid commerce event");
        }

        CommerceEvent.Builder builder = null;

        if (isProductAction) {
            int productActionInt = map.getInt("productActionType");
            String productAction = ConvertPromotionActionType(productActionInt);
            ReadableArray productsArray = map.getArray("products");
            ReadableMap productMap = productsArray.getMap(0);
            Product product = ConvertProduct(productMap);
            builder = new CommerceEvent.Builder(productAction, product);

            for (int i = 1; i < productsArray.size(); ++i) {
                productMap = productsArray.getMap(i);
                product = ConvertProduct(productMap);
                builder.addProduct(product);
            }
        }
        else if (isPromotion) {
            int promotionActionTypeInt = map.getInt("promotionActionType");
            String promotionAction = ConvertPromotionActionType(promotionActionTypeInt);
            ReadableArray promotionsReadableArray = map.getArray("promotions");
            ReadableMap promotionMap = promotionsReadableArray.getMap(0);
            Promotion promotion = ConvertPromotion(promotionMap);
            builder = new CommerceEvent.Builder(promotionAction, promotion);

            for (int i = 0; i < promotionsReadableArray.size(); ++i) {
                promotionMap = promotionsReadableArray.getMap(i);
                promotion = ConvertPromotion(promotionMap);
                builder.addPromotion(promotion);
            }
        }
        else {
            ReadableArray impressionsArray = map.getArray("impressions");
            ReadableMap impressionMap = impressionsArray.getMap(0);
            Impression impression = ConvertImpression(impressionMap);
            builder = new CommerceEvent.Builder(impression);

            for (int i = 0; i < impressionsArray.size(); ++i) {
                impressionMap = impressionsArray.getMap(i);
                impression = ConvertImpression(impressionMap);
                builder.addImpression(impression);
            }
        }

        return builder.build();
    }

    private static Product ConvertProduct(ReadableMap map) {
        String name = map.getString("name");
        String sku = map.getString("sku");
        double unitPrice = map.getDouble("price");
        Product.Builder builder = new Product.Builder(name, sku, unitPrice);

        if (map.hasKey("brand")) {
            String brand = map.getString("brand");
            builder.brand(brand);
        }

        if (map.hasKey("category")) {
            String category = map.getString("category");
            builder.category(category);
        }

        if (map.hasKey("couponCode")) {
            String couponCode = map.getString("couponCode");
            builder.couponCode(couponCode);
        }

        if (map.hasKey("customAttributes")) {
            ReadableMap customAttributesMap = map.getMap("customAttributes");
            Map<String, String> customAttributes = ConvertStringMap(customAttributesMap);
            builder.customAttributes(customAttributes);
        }

        if (map.hasKey("position")) {
            int position = map.getInt("position");
            builder.position(position);
        }

        if (map.hasKey("quantity")) {
            double quantity = map.getDouble("quantity");
            builder.quantity(quantity);
        }

        return builder.build();
    }

    private static Promotion ConvertPromotion(ReadableMap map) {
        Promotion promotion = new Promotion();

        if (map.hasKey("id")) {
            promotion.setId(map.getString("id"));
        }

        if (map.hasKey("name")) {
            promotion.setName(map.getString("name"));
        }

        if (map.hasKey("creative")) {
            promotion.setCreative(map.getString("creative"));
        }

        if (map.hasKey("position")) {
            promotion.setPosition(map.getString("position"));
        }

        return promotion;
    }

    private static Impression ConvertImpression(ReadableMap map) {

        String listName = map.getString("impressionListName");
        ReadableArray productsArray = map.getArray("products");
        ReadableMap productMap = productsArray.getMap(0);
        Product product = ConvertProduct(productMap);
        Impression impression = new Impression(listName, product);

        for (int i = 1; i < productsArray.size(); ++i) {
            productMap = productsArray.getMap(i);
            product = ConvertProduct(productMap);
            impression.addProduct(product);
        }

        return impression;
    }

    private static Map<String, String> ConvertStringMap(ReadableMap readableMap) {
        Map<String, String> map = null;

        if (readableMap != null) {
            map = new HashMap<String, String>();
            while (readableMap.keySetIterator().hasNextKey()) {
                String key = readableMap.keySetIterator().nextKey();
                map.put(key, readableMap.getString(key));
            }
        }

        return map;
    }

    private static MParticle.EventType ConvertEventType(int eventType) {
        switch (eventType) {
            case 1:
                return MParticle.EventType.Navigation;
            case 2:
                return MParticle.EventType.Location;
            case 3:
                return MParticle.EventType.Search;
            case 4:
                return MParticle.EventType.Transaction;
            case 5:
                return MParticle.EventType.UserContent;
            case 6:
                return MParticle.EventType.UserPreference;
            case 7:
                return MParticle.EventType.Social;
            default:
                return MParticle.EventType.Other;
        }
    }

    private static String ConvertProductActionType(int productActionType) {
        switch (productActionType) {
            case 1:
                return Product.ADD_TO_CART;
            case 2:
                return Product.REMOVE_FROM_CART;
            case 3:
                return Product.CHECKOUT;
            case 4:
                return Product.CHECKOUT_OPTION;
            case 5:
                return Product.CLICK;
            case 6:
                return Product.DETAIL;
            case 7:
                return Product.PURCHASE;
            case 8:
                return Product.REFUND;
            case 9:
                return Product.ADD_TO_WISHLIST;
            default:
                return Product.REMOVE_FROM_WISHLIST;
        }
    }

    private static String ConvertPromotionActionType(int promotionActionType) {
        switch (promotionActionType) {
            case 0:
                return Promotion.VIEW;
            default:
                return Promotion.CLICK;
        }
    }
}
