import 'react-native';
import React from 'react';
import Index from '../index.js';

// Note: test renderer must be required after react-native.
import renderer from 'react-test-renderer';

// Use fake timers to avoid async issues
jest.useFakeTimers();

it('renders correctly', () => {
  const tree = renderer.create(
    <Index />
  );

  // Clean up any timers that might be running
  jest.runOnlyPendingTimers();
  jest.clearAllTimers();

  expect(tree.toJSON()).toBeTruthy();
});
