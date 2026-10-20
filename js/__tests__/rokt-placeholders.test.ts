/**
 * `selectPlacements` accepts only placeholder names (`['Location1']`). The legacy map of name
 * to `findNodeHandle` react tag is rejected in JS with an error log, so every platform behaves
 * the same: the placement is requested without embedded views.
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
  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('passes placeholder names through unchanged', () => {
    const names = ['Location1', 'Location2'];
    expect(toNativePlaceholders(names)).toBe(names);
  });

  it('passes undefined through for overlay placements', () => {
    expect(toNativePlaceholders(undefined)).toBeUndefined();
  });

  it('rejects the legacy map of name to react tag with an error log', () => {
    const error = jest
      .spyOn(console, 'error')
      .mockImplementation(() => undefined);
    const legacy = { Location1: 42 } as unknown as string[];

    expect(toNativePlaceholders(legacy)).toBeUndefined();
    expect(error).toHaveBeenCalledTimes(1);
    expect(error.mock.calls[0][0]).toContain(
      'array of RoktLayoutView placeholderNames'
    );
  });
});
