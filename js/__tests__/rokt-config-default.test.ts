/**
 * On iOS New Architecture an omitted optional `roktConfig` reaches native as a null C++
 * reference and crashes on first access, so the wrapper sends `{}` instead. Native treats an
 * empty config exactly like no config. Android takes a nullable map and is left unchanged.
 */

function loadRokt(os: 'ios' | 'android') {
  const nativeRokt = {
    selectPlacements: jest.fn(),
    selectShoppableAds: jest.fn(),
  };
  jest.resetModules();
  jest.doMock(
    'react-native',
    () => ({
      NativeModules: { RNMPRokt: nativeRokt },
      Platform: { OS: os },
      TurboModuleRegistry: { get: jest.fn(() => null) },
    }),
    { virtual: true }
  );
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const { Rokt } = require('../rokt/rokt');
  return { Rokt, nativeRokt };
}

afterEach(() => {
  jest.resetModules();
});

describe('roktConfig default', () => {
  it('sends an empty config on iOS when roktConfig is omitted', async () => {
    const { Rokt, nativeRokt } = loadRokt('ios');

    await Rokt.selectPlacements('checkout', { email: 'a@b.c' });
    await Rokt.selectShoppableAds('checkout', { email: 'a@b.c' });

    expect(nativeRokt.selectPlacements.mock.calls[0][3]).toEqual({});
    expect(nativeRokt.selectShoppableAds.mock.calls[0][2]).toEqual({});
  });

  it('passes a provided config through by reference', async () => {
    const { Rokt, nativeRokt } = loadRokt('ios');
    const config = Rokt.createRoktConfig('dark');

    await Rokt.selectPlacements('checkout', {}, undefined, config);
    await Rokt.selectShoppableAds('checkout', {}, config);

    expect(nativeRokt.selectPlacements.mock.calls[0][3]).toBe(config);
    expect(nativeRokt.selectShoppableAds.mock.calls[0][2]).toBe(config);
  });

  it('keeps sending undefined on Android', async () => {
    const { Rokt, nativeRokt } = loadRokt('android');

    await Rokt.selectPlacements('checkout', {});
    await Rokt.selectShoppableAds('checkout', {});

    expect(nativeRokt.selectPlacements.mock.calls[0][3]).toBeUndefined();
    expect(nativeRokt.selectShoppableAds.mock.calls[0][2]).toBeUndefined();
  });
});
