module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  testMatch: ['<rootDir>/js/**/*.test.ts?(x)'],
  transform: {
    '^.+\\.tsx?$': [
      'ts-jest',
      {
        // tsconfig sets `jsx: react-native`, which leaves JSX untransformed for
        // Metro to handle. Jest has no Metro, so compile it here. `react` is a peer
        // dependency and is not installed, so use the classic runtime and let tests
        // mock `react` rather than requiring `react/jsx-runtime`.
        tsconfig: { jsx: 'react' },
      },
    ],
  },
};
