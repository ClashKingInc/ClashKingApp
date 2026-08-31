const { defineConfig } = require('eslint/config');
const expoConfig = require('eslint-config-expo/flat');

module.exports = defineConfig([
  expoConfig,
  {
    ignores: ['dist/**', 'coverage/**', 'ios/**', 'android/**', 'src/i18n/catalogs.generated.ts'],
  },
]);
