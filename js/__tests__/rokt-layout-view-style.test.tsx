/**
 * `RoktLayoutView` sizes its native view from the height the Rokt SDK measures and
 * pushes back to JS. If the style also sets `flex: 1`, that expands to
 * `flexBasis: 0%`, which takes precedence over `height` on the parent's main axis —
 * so inside any auto-height column parent the layout collapses to 0 and the
 * placement is never visible, even though it selected successfully and reported a
 * height. Guard both platform implementations against that regression.
 */
const mockAddListener = jest.fn(() => ({ remove: jest.fn() }));

// `react` and `react-native` are peer dependencies and are not installed here, so
// stub the pieces these components touch. `createElement` just records what the
// component asked for, which is all the assertions below need.
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
    // Pass styles through unchanged so the test can read the resolved values.
    StyleSheet: { create: (styles: unknown) => styles },
    NativeModules: { RoktEventManager: {} },
    NativeEventEmitter: jest.fn(() => ({ addListener: mockAddListener })),
    requireNativeComponent: jest.fn(() => 'RoktLegacyLayout'),
    TurboModuleRegistry: { getEnforcing: jest.fn(() => ({})) },
  }),
  { virtual: true }
);

jest.mock(
  '../codegenSpecs/rokt/RoktLayoutNativeComponent',
  () => ({ __esModule: true, default: 'RoktNativeLayout' }),
  { virtual: true }
);

import { RoktLayoutView as IosLayoutView } from '../rokt/rokt-layout-view.ios';
import { RoktLayoutView as AndroidLayoutView } from '../rokt/rokt-layout-view.android';

type LayoutViewCtor = typeof IosLayoutView | typeof AndroidLayoutView;

/** Renders the component and flattens the style array it hands the native view. */
function resolvedStyle(Ctor: LayoutViewCtor, height: number) {
  const instance = new Ctor({ placeholderName: 'Location1' });
  // The measured height normally arrives via a native event; set it directly so the
  // test does not depend on the platform-specific event plumbing.
  instance.state = { ...instance.state, height };
  const element = instance.render() as React.ReactElement<{ style: object[] }>;
  return Object.assign({}, ...element.props.style) as Record<string, unknown>;
}

describe.each([
  ['ios', IosLayoutView],
  ['android', AndroidLayoutView],
])('RoktLayoutView (%s) style', (_platform, Ctor) => {
  it('applies the measured height', () => {
    expect(resolvedStyle(Ctor, 530)).toMatchObject({ height: 530 });
  });

  it('does not set flex, which would override the height and collapse the view', () => {
    const style = resolvedStyle(Ctor, 530);
    expect(style.flex).toBeUndefined();
    expect(style.flexBasis).toBeUndefined();
    expect(style.flexGrow).toBeUndefined();
  });

  it('stretches to the full available width', () => {
    expect(resolvedStyle(Ctor, 530)).toMatchObject({ alignSelf: 'stretch' });
  });
});
