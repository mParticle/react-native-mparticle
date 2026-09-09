/**
 * `RoktEventManager` resolves to `null` when neither the TurboModule registry nor
 * `NativeModules` has it -- e.g. bridgeless with TurboModule interop disabled and no
 * old-architecture fallback registered. RN's real `NativeEventEmitter` throws an
 * invariant in its constructor on iOS when handed a null module, so this mock
 * reproduces that behavior and pins that mounting `RoktLayoutView` must not hit it.
 */
jest.mock(
  'react',
  () => {
    class Component<P, S> {
      props: P;
      state!: S;
      constructor(props: P) {
        this.props = props;
      }
      setState(partial: Partial<S>) {
        this.state = { ...this.state, ...partial };
      }
    }
    const createElement = (
      type: unknown,
      props: Record<string, unknown> | null
    ) => ({ type, props: props ?? {} });
    return { __esModule: true, default: { createElement }, Component };
  },
  { virtual: true }
);

jest.mock(
  'react-native',
  () => ({
    StyleSheet: { create: (styles: unknown) => styles },
    NativeModules: {},
    // Mirrors RN's real iOS behavior: constructing with a null module throws.
    NativeEventEmitter: jest.fn((nativeModule: unknown) => {
      if (nativeModule == null) {
        throw new Error(
          '`new NativeEventEmitter()` requires a non-null argument.'
        );
      }
      return { addListener: jest.fn(() => ({ remove: jest.fn() })) };
    }),
    requireNativeComponent: jest.fn(() => 'RoktLegacyLayout'),
    TurboModuleRegistry: { get: jest.fn(() => null), getEnforcing: jest.fn() },
  }),
  { virtual: true }
);

jest.mock(
  '../codegenSpecs/rokt/RoktLayoutNativeComponent',
  () => ({ __esModule: true, default: 'RoktNativeLayout' }),
  { virtual: true }
);

import { RoktLayoutView } from '../rokt/rokt-layout-view.ios';

describe('RoktLayoutView (ios) when RoktEventManager is unavailable', () => {
  it('does not throw while mounting', () => {
    expect(
      () => new RoktLayoutView({ placeholderName: 'Location1' })
    ).not.toThrow();
  });

  it('still renders the native component', () => {
    const instance = new RoktLayoutView({ placeholderName: 'Location1' });
    const element = instance.render() as React.ReactElement;
    expect(element.type).toBe('RoktLegacyLayout');
  });

  it('unmounts cleanly with the no-op subscription', () => {
    const instance = new RoktLayoutView({ placeholderName: 'Location1' });
    expect(() => instance.componentWillUnmount()).not.toThrow();
  });
});
