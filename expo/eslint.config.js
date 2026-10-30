const { defineConfig } = require('eslint/config');
const expoConfig = require('eslint-config-expo/flat');

module.exports = defineConfig([
  expoConfig,
  {
    files: ['src/**/*.tsx'],
    rules: {
      // A new RN modal must not silently restore its default portrait-only
      // controller and rotate the iPad beneath an otherwise landscape page.
      'no-restricted-syntax': ['error', {
        selector: "JSXOpeningElement[name.name='Modal']:not(:has(JSXAttribute[name.name='supportedOrientations']))",
        message: 'Use supportedOrientations={modalOrientations} to preserve iPad orientation.',
      }, {
        selector: "MemberExpression[property.name='uri'][object.type='CallExpression'][object.callee.object.name='Asset'][object.callee.property.name='fromModule']",
        message: 'Use bundledImageUrl for URL-based image controls, or pass the asset module directly to Image. Raw Asset.uri can bypass installed OTA assets.',
      }],
    },
  },
  {
    files: ['src/features/**/*.ts'],
    rules: {
      'no-restricted-syntax': ['error', {
        selector: "MemberExpression[property.name='uri'][object.type='CallExpression'][object.callee.object.name='Asset'][object.callee.property.name='fromModule']",
        message: 'Use bundledImageUrl for URL-based image controls, or pass the asset module directly to Image. Raw Asset.uri can bypass installed OTA assets.',
      }],
    },
  },
  {
    ignores: ['dist/**', 'coverage/**', 'ios/**', 'android/**', 'src/i18n/catalogs.generated.ts'],
  },
]);
