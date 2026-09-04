module.exports = {
  preset: 'jest-expo',
  roots: ['<rootDir>/src'],
  testMatch: ['**/?(*.)+(spec|test).[jt]s?(x)'],
  moduleNameMapper: {
    '^@clashking/api-client$': '<rootDir>/node_modules/@clashking/api-client/dist/index.js',
    '^@clashking/api-contracts$': '<rootDir>/node_modules/@clashking/api-contracts/dist/index.js',
    '^@clashking/api-contracts/expo$':
      '<rootDir>/node_modules/@clashking/api-contracts/dist/expo.js',
    '^lucide-react-native$':
      '<rootDir>/node_modules/lucide-react-native/dist/cjs/lucide-react-native.js',
  },
  transformIgnorePatterns: [
    '/node_modules/(?!(.pnpm|react-native|@react-native|@react-native-community|@clashking|effect|expo|@expo|@expo-google-fonts|react-navigation|@react-navigation|@sentry/react-native|native-base|standard-navigation|intl-messageformat|@formatjs))',
    '/node_modules/react-native-reanimated/plugin/',
    '/node_modules/@react-native/babel-preset/',
  ],
  collectCoverageFrom: ['src/**/*.{ts,tsx}', '!src/**/*.d.ts', '!src/i18n/catalogs.generated.ts'],
};
