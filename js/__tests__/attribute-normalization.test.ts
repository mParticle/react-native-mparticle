const mockNativeModule = {
  logEvent: jest.fn(),
  logMPEvent: jest.fn(),
  logCommerceEvent: jest.fn(),
  logScreenEvent: jest.fn(),
};

jest.mock(
  'react-native',
  () => ({
    NativeModules: { RNMParticle: mockNativeModule },
    Platform: { OS: 'ios' },
    TurboModuleRegistry: {
      getEnforcing: jest.fn(() => mockNativeModule),
    },
  }),
  { virtual: true }
);

jest.mock('../rokt/rokt', () => ({
  Rokt: {},
  CacheConfig: {},
  RoktEventManager: {},
}));

jest.mock('../rokt/rokt-layout-view', () => ({
  __esModule: true,
  default: {},
}));

import {
  CommerceEvent,
  Event,
  Impression,
  Product,
  logCommerceEvent,
  logEvent,
  logMPEvent,
  logScreenEvent,
} from '../index';

describe('custom attribute normalization', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('normalizes basic event attributes without mutating the input', () => {
    const attributes = {
      coupon_code: null,
      campaign: 'summer',
      count: 2,
      active: true,
    };

    logEvent('Purchase', 4, attributes);

    expect(mockNativeModule.logEvent).toHaveBeenCalledWith('Purchase', 4, {
      coupon_code: '',
      campaign: 'summer',
      count: 2,
      active: true,
    });
    expect(mockNativeModule.logEvent.mock.calls[0][2]).not.toBe(attributes);
    expect(attributes.coupon_code).toBeNull();
  });

  it('normalizes screen event attributes without mutating the input', () => {
    const attributes = { section: null };

    logScreenEvent('Checkout', attributes, false);

    expect(mockNativeModule.logScreenEvent).toHaveBeenCalledWith(
      'Checkout',
      { section: '' },
      false
    );
    expect(mockNativeModule.logScreenEvent.mock.calls[0][1]).not.toBe(
      attributes
    );
    expect(attributes.section).toBeNull();
  });

  it('normalizes object event attributes without mutating the event', () => {
    const attributes = { coupon_code: null };
    const event = new Event()
      .setName('Purchase')
      .setType(4)
      .setInfo(attributes);

    logMPEvent(event);

    expect(mockNativeModule.logMPEvent).toHaveBeenCalledWith({
      name: 'Purchase',
      type: 4,
      info: { coupon_code: '' },
    });
    expect(mockNativeModule.logMPEvent.mock.calls[0][0]).not.toBe(event);
    expect(event.info).toBe(attributes);
    expect(attributes.coupon_code).toBeNull();
  });

  it('normalizes commerce, product, and impression attributes without mutation', () => {
    const eventAttributes = { checkout_state: null };
    const productAttributes = { coupon_code: null, featured: true };
    const impressionAttributes = { placement: null };
    const product = new Product('Shirt', 'shirt-1', 25).setCustomAttributes(
      productAttributes
    );
    const impressionProduct = new Product(
      'Shoes',
      'shoes-1',
      50
    ).setCustomAttributes(impressionAttributes);
    const impression = new Impression('recommended', [impressionProduct]);
    const event = CommerceEvent.createProductActionEvent(1, [product])
      .setImpressions([impression])
      .setCustomAttributes(eventAttributes);

    logCommerceEvent(event);

    const normalizedEvent = mockNativeModule.logCommerceEvent.mock.calls[0][0];
    expect(normalizedEvent.customAttributes).toEqual({ checkout_state: '' });
    expect(normalizedEvent.products[0].customAttributes).toEqual({
      coupon_code: '',
      featured: true,
    });
    expect(normalizedEvent.impressions[0].products[0].customAttributes).toEqual(
      { placement: '' }
    );
    expect(normalizedEvent).not.toBe(event);
    expect(normalizedEvent.products[0]).not.toBe(product);
    expect(normalizedEvent.impressions[0]).not.toBe(impression);
    expect(normalizedEvent.impressions[0].products[0]).not.toBe(
      impressionProduct
    );
    expect(event.customAttributes).toBe(eventAttributes);
    expect(product.customAttributes).toBe(productAttributes);
    expect(impressionProduct.customAttributes).toBe(impressionAttributes);
    expect(eventAttributes.checkout_state).toBeNull();
    expect(productAttributes.coupon_code).toBeNull();
    expect(impressionAttributes.placement).toBeNull();
  });

  it('treats null attribute containers as omitted without throwing', () => {
    const event = new Event().setName('Purchase').setType(4);
    (event as unknown as { info: unknown }).info = null;

    const product = new Product('Shirt', 'shirt-1', 25);
    (product as unknown as { customAttributes: unknown }).customAttributes =
      null;

    const commerceEvent = CommerceEvent.createProductActionEvent(1, [product]);
    const mutableCommerceEvent = commerceEvent as unknown as {
      customAttributes: unknown;
      impressions: unknown;
    };
    mutableCommerceEvent.customAttributes = null;
    mutableCommerceEvent.impressions = null;

    expect(() => logMPEvent(event)).not.toThrow();
    expect(() => logCommerceEvent(commerceEvent)).not.toThrow();

    expect(mockNativeModule.logMPEvent.mock.calls[0][0].info).toBeUndefined();
    const normalizedCommerce =
      mockNativeModule.logCommerceEvent.mock.calls[0][0];
    expect(normalizedCommerce.customAttributes).toBeUndefined();
    expect(normalizedCommerce.impressions).toBeUndefined();
    expect(normalizedCommerce.products[0].customAttributes).toBeUndefined();
  });
});
