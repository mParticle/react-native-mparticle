/**
 * The Rokt event emitter is an `RCTEventEmitter`, which conforms only to `RCTBridgeModule`.
 * Bridgeless does not instantiate those unless the host app enabled TurboModule interop, so
 * resolving it purely through `NativeModules` left it undefined and dropped every Rokt event
 * before it reached JS. It is now registered via codegen and must be resolved through the
 * TurboModule registry first, with a `NativeModules` fallback for the old architecture.
 */

function loadRoktEventManager(
  turboModule: unknown,
  nativeModules: Record<string, unknown>
) {
  jest.resetModules();
  jest.doMock(
    'react-native',
    () => ({
      NativeModules: nativeModules,
      TurboModuleRegistry: { get: jest.fn(() => turboModule) },
    }),
    { virtual: true }
  );
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  return require('../rokt/rokt-event-manager').RoktEventManager;
}

afterEach(() => {
  jest.resetModules();
});

describe('RoktEventManager resolution', () => {
  it('resolves through the TurboModule registry when NativeModules has no entry', () => {
    const turboModule = { addListener: jest.fn(), removeListeners: jest.fn() };

    expect(loadRoktEventManager(turboModule, {})).toBe(turboModule);
  });

  it('prefers the TurboModule registry over NativeModules', () => {
    const turboModule = { addListener: jest.fn(), removeListeners: jest.fn() };
    const legacyModule = { addListener: jest.fn() };

    expect(
      loadRoktEventManager(turboModule, { RoktEventManager: legacyModule })
    ).toBe(turboModule);
  });

  it('falls back to NativeModules on the old architecture', () => {
    const legacyModule = { addListener: jest.fn() };

    expect(loadRoktEventManager(null, { RoktEventManager: legacyModule })).toBe(
      legacyModule
    );
  });

  it('is null when neither is available, so NativeEventEmitter is not handed undefined', () => {
    expect(loadRoktEventManager(null, {})).toBeNull();
  });
});
