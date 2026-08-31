'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const { configureAndroidReleaseSigning } = require('../with-android-release-signing');

const fixture = `android {
    signingConfigs {
        debug {
            storeFile file('debug.keystore')
        }
    }
    buildTypes {
        debug {
            signingConfig signingConfigs.debug
        }
        release {
            signingConfig signingConfigs.debug
            minifyEnabled false
        }
    }
    packagingOptions {
    }
}`;

test('uses secret-backed release signing without changing debug signing', () => {
  const configured = configureAndroidReleaseSigning(fixture);
  assert.match(
    configured,
    /release \{\n            def keyStore = findProperty\('CK_UPLOAD_STORE_FILE'\)/,
  );
  assert.match(configured, /storePassword findProperty\('CK_UPLOAD_STORE_PASSWORD'\)/);
  assert.match(configured, /keyAlias findProperty\('CK_UPLOAD_KEY_ALIAS'\)/);
  assert.match(configured, /keyPassword findProperty\('CK_UPLOAD_KEY_PASSWORD'\)/);
  assert.match(configured, /debug \{\n            signingConfig signingConfigs\.debug/);
  assert.match(configured, /release \{\n            signingConfig signingConfigs\.release/);
});

test('is idempotent', () => {
  const configured = configureAndroidReleaseSigning(fixture);
  assert.equal(configureAndroidReleaseSigning(configured), configured);
});
