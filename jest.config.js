module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  testMatch: [
    '<rootDir>/js/**/*.test.ts?(x)',
    '<rootDir>/plugin/**/*.test.ts?(x)',
  ],
};
