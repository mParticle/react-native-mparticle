/**
 * `selectPlacements` accepts placeholder names (`['Location1']`) or the legacy map of
 * name to `findNodeHandle` react tag. The native spec only knows the map shape, so the
 * name form is sent with invalid React tag zero, which native resolves by `placeholderName`.
 */
jest.mock(
  'react-native',
  () => ({
    NativeModules: {},
    Platform: { OS: 'ios' },
    TurboModuleRegistry: { get: jest.fn(() => null) },
  }),
  { virtual: true }
);

import { toNativePlaceholders } from '../rokt/rokt';

describe('toNativePlaceholders', () => {
  it('maps placeholder names to zero for name-based resolution', () => {
    expect(toNativePlaceholders(['Location1', 'Location2'])).toEqual({
      Location1: 0,
      Location2: 0,
    });
  });

  it('preserves legacy react tags and normalizes null entries', () => {
    const legacy = { Location1: 42, Location2: null };
    expect(toNativePlaceholders(legacy)).toEqual({
      Location1: 42,
      Location2: 0,
    });
  });

  it('passes undefined through for overlay placements', () => {
    expect(toNativePlaceholders(undefined)).toBeUndefined();
  });
});
