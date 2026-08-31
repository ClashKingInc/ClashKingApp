'use strict';

/* global __dirname */

const assert = require('node:assert/strict');
const { createHash } = require('node:crypto');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const test = require('node:test');
const {
  appendUnique,
  assertExact,
  copyFileIfChanged,
  copyRelativeFilesIfChanged,
  requirePath,
  validateRelativeTarget,
  validateRequiredFiles,
} = require('../native-parity-helpers');
const {
  android12SplashStyleXml,
  attachFileReferencesToGroup,
  copyAndroidSplashResources,
  configureAndroidNotificationMetadata,
  configureAndroidPermissions,
  configureGeneratedAndroidBuildTypePermissions,
  configureAlternateIconTarget,
  configureIosPlatformPlist,
  configureWidgetEmbedding,
  configureWidgetTarget,
  ensureRNFirebaseCocoaPodsMode,
  removeUnscopedAndroidScheme,
  upsertAndroidComponent,
  validateAlternateIconCatalog,
  validateLegacyWidgetContract,
} = require('../with-clashking-native');

test('generated iOS capabilities retain only the shipping remote-notification mode', () => {
  const plist = {
    UIBackgroundModes: ['fetch', 'processing', 'remote-notification'],
    BGTaskSchedulerPermittedIdentifiers: ['com.expo.modules.backgroundtask.processing'],
  };
  assert.deepEqual(configureIosPlatformPlist(plist, ['remote-notification']), {
    UIBackgroundModes: ['remote-notification'],
  });
});

test('generated Android manifest blocks legacy storage and dev-overlay permissions', () => {
  const manifest = {
    'uses-permission': [
      { $: { 'android:name': 'android.permission.INTERNET' } },
      { $: { 'android:name': 'android.permission.POST_NOTIFICATIONS' } },
      { $: { 'android:name': 'android.permission.MODIFY_AUDIO_SETTINGS' } },
      { $: { 'android:name': 'android.permission.VIBRATE' } },
      { $: { 'android:name': 'android.permission.READ_EXTERNAL_STORAGE' } },
      { $: { 'android:name': 'android.permission.WRITE_EXTERNAL_STORAGE' } },
      { $: { 'android:name': 'android.permission.SYSTEM_ALERT_WINDOW' } },
    ],
  };
  configureAndroidPermissions(manifest);
  const permissions = new Map(
    manifest['uses-permission'].map((entry) => [entry.$['android:name'], entry.$]),
  );
  for (const retained of [
    'android.permission.INTERNET',
    'android.permission.POST_NOTIFICATIONS',
    'android.permission.MODIFY_AUDIO_SETTINGS',
    'android.permission.VIBRATE',
  ]) {
    assert.deepEqual(permissions.get(retained), { 'android:name': retained });
  }
  for (const blocked of [
    'android.permission.READ_EXTERNAL_STORAGE',
    'android.permission.WRITE_EXTERNAL_STORAGE',
    'android.permission.SYSTEM_ALERT_WINDOW',
  ]) {
    assert.deepEqual(permissions.get(blocked), {
      'android:name': blocked,
      'tools:node': 'remove',
    });
  }

  // The plugin must retain every Flutter deep-link host while deleting the
  // unscoped scheme that Expo derives from the top-level app scheme.

  const filters = removeUnscopedAndroidScheme(
    [
      {
        action: [{ $: { 'android:name': 'android.intent.action.MAIN' } }],
        category: [{ $: { 'android:name': 'android.intent.category.LAUNCHER' } }],
      },
      {
        action: [{ $: { 'android:name': 'android.intent.action.VIEW' } }],
        data: [
          { $: { 'android:scheme': 'clashking' } },
          { $: { 'android:scheme': 'exp+clashking-app' } },
        ],
      },
      {
        action: [{ $: { 'android:name': 'android.intent.action.VIEW' } }],
        data: [{ $: { 'android:scheme': 'clashking', 'android:host': 'player' } }],
      },
    ],
    'clashking',
  );
  assert.equal(filters.length, 2);
  assert.deepEqual(filters[1].data, [{ $: { 'android:scheme': 'exp+clashking-app' } }]);
});

test('generated Android build-type overlays cannot restore blocked permissions', async () => {
  const platformRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'clashking-android-permissions-'));
  try {
    for (const buildType of ['debug', 'debugOptimized']) {
      const manifestDirectory = path.join(platformRoot, 'app', 'src', buildType);
      fs.mkdirSync(manifestDirectory, { recursive: true });
      fs.writeFileSync(
        path.join(manifestDirectory, 'AndroidManifest.xml'),
        '<manifest xmlns:android="http://schemas.android.com/apk/res/android"><uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW"/></manifest>',
      );
    }

    await configureGeneratedAndroidBuildTypePermissions(platformRoot);

    for (const buildType of ['debug', 'debugOptimized']) {
      const manifest = await readAndroidManifestForTest(
        path.join(platformRoot, 'app', 'src', buildType, 'AndroidManifest.xml'),
      );
      const permissions = new Map(
        manifest['uses-permission'].map((entry) => [entry.$['android:name'], entry.$]),
      );
      for (const blocked of [
        'android.permission.READ_EXTERNAL_STORAGE',
        'android.permission.WRITE_EXTERNAL_STORAGE',
        'android.permission.SYSTEM_ALERT_WINDOW',
      ]) {
        assert.deepEqual(permissions.get(blocked), {
          'android:name': blocked,
          'tools:node': 'remove',
        });
      }
      assert.equal(manifest.$['xmlns:tools'], 'http://schemas.android.com/tools');
    }
  } finally {
    fs.rmSync(platformRoot, { recursive: true, force: true });
  }
});

async function readAndroidManifestForTest(manifestPath) {
  const { AndroidConfig } = require('expo/config-plugins');
  return (await AndroidConfig.Manifest.readAndroidManifestAsync(manifestPath)).manifest;
}

test('assertExact accepts missing or exact values and rejects drift', () => {
  assert.equal(assertExact('bundle', undefined, 'com.clashking.apps'), 'com.clashking.apps');
  assert.equal(
    assertExact('bundle', 'com.clashking.apps', 'com.clashking.apps'),
    'com.clashking.apps',
  );
  assert.throws(
    () => assertExact('bundle', 'example.invalid', 'com.clashking.apps'),
    /bundle must be com\.clashking\.apps/,
  );
});

test('retained Apple team identifier is part of the app config contract', () => {
  const config = { scheme: 'clashking', ios: {}, android: {} };
  const contract = require('../../native/parity-contract.json');
  const { assertAndApplyIdentity } = require('../with-clashking-native');
  const configured = assertAndApplyIdentity(config, contract);
  assert.equal(configured.ios.appleTeamId, 'MZYXD43RX5');
  assert.throws(
    () =>
      assertAndApplyIdentity(
        {
          scheme: 'clashking',
          ios: { appleTeamId: 'WRONGTEAM' },
          android: {},
        },
        contract,
      ),
    /expo\.ios\.appleTeamId must be MZYXD43RX5/,
  );
});

test('appendUnique is stable and idempotent', () => {
  assert.deepEqual(appendUnique(['remote-notification'], ['remote-notification', 'processing']), [
    'remote-notification',
    'processing',
  ]);
});

test('RNFirebase CocoaPods switch is inserted once before every Pod target', () => {
  const original =
    "platform :ios, '17.0'\n\nprepare_react_native_project!\n\ntarget 'ClashKing' do\nend\n";
  const configured = ensureRNFirebaseCocoaPodsMode(original);
  assert.equal((configured.match(/\$RNFirebaseDisableSPM = true/g) || []).length, 1);
  assert.ok(
    configured.indexOf('$RNFirebaseDisableSPM = true') < configured.indexOf("target 'ClashKing'"),
  );
  assert.equal(ensureRNFirebaseCocoaPodsMode(configured), configured);
});

test('RNFirebase CocoaPods switch normalizes a late assignment and rejects unsafe Podfiles', () => {
  const late = "target 'ClashKing' do\nend\n$RNFirebaseDisableSPM = true\n";
  const configured = ensureRNFirebaseCocoaPodsMode(late);
  assert.ok(
    configured.indexOf('$RNFirebaseDisableSPM = true') < configured.indexOf("target 'ClashKing'"),
  );
  assert.throws(
    () =>
      ensureRNFirebaseCocoaPodsMode("$RNFirebaseDisableSPM = false\ntarget 'ClashKing' do\nend\n"),
    /must not be false/,
  );
  assert.throws(() => ensureRNFirebaseCocoaPodsMode("platform :ios, '17.0'\n"), /no target block/);
});

test('copyFileIfChanged does not rewrite identical native inputs', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'ck-native-helper-'));
  const source = path.join(root, 'source.txt');
  const destination = path.join(root, 'nested', 'destination.txt');
  fs.writeFileSync(source, 'native parity\n');
  assert.equal(copyFileIfChanged(source, destination), true);
  const firstMtime = fs.statSync(destination).mtimeMs;
  assert.equal(copyFileIfChanged(source, destination), false);
  assert.equal(fs.statSync(destination).mtimeMs, firstMtime);
});

test('native input validation fails loudly and targets cannot escape', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'ck-native-input-'));
  fs.writeFileSync(path.join(root, 'present.swift'), 'import SwiftUI\n');
  assert.equal(requirePath(root, 'present.swift'), path.join(root, 'present.swift'));
  assert.throws(
    () => validateRequiredFiles(root, ['missing.swift']),
    /Missing native parity input/,
  );
  assert.equal(validateRelativeTarget('WarWidget'), 'WarWidget');
  assert.throws(() => validateRelativeTarget('../outside'), /escapes/);
  assert.throws(() => validateRelativeTarget('/absolute'), /relative path/);
});

test('copyRelativeFilesIfChanged preserves declared relative layout', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'ck-native-tree-'));
  const source = path.join(root, 'source');
  const destination = path.join(root, 'destination');
  fs.mkdirSync(path.join(source, 'res', 'xml'), { recursive: true });
  fs.writeFileSync(path.join(source, 'res', 'xml', 'widget.xml'), '<widget />\n');
  assert.equal(copyRelativeFilesIfChanged(source, destination, ['res/xml/widget.xml']), 1);
  assert.equal(
    fs.readFileSync(path.join(destination, 'res', 'xml', 'widget.xml'), 'utf8'),
    '<widget />\n',
  );
  assert.equal(copyRelativeFilesIfChanged(source, destination, ['res/xml/widget.xml']), 0);
});

test('retained native contract is Expo-owned and complete', () => {
  const expoRoot = path.resolve(__dirname, '../..');
  const contract = require('../../native/parity-contract.json');
  assert.match(contract.ios.widgetSourceRoot, /^\.\/native\//);
  assert.match(contract.android.widgetSourceRoot, /^\.\/native\//);
  assert.match(contract.alternateIconSourceRoot, /^\.\/native\//);
  assert.doesNotMatch(JSON.stringify(contract), /\.\.\/ios|\.\.\/android/);
  assert.equal(contract.legacyStorage.flutterSecureStorage.version, '10.3.1');
  assert.equal(contract.ios.rnFirebaseDependencyManager, 'cocoapods');
  assert.deepEqual(contract.android.notificationDefaults, {
    channelId: 'clashking_push',
    iconResource: '@drawable/notification_icon',
    colorResource: '@color/notification_icon_color',
  });
  assert.deepEqual(contract.android.splashResources, {
    sourceRoot: './native/android/splash',
    android12ResourceName: 'android12splash',
    preAndroid12ResourceName: 'splashscreen_logo',
    requiredFiles: [
      'res/drawable-mdpi/android12splash.png',
      'res/drawable-hdpi/android12splash.png',
      'res/drawable-xhdpi/android12splash.png',
      'res/drawable-xxhdpi/android12splash.png',
      'res/drawable-xxxhdpi/android12splash.png',
      'res/drawable-mdpi/splashscreen_logo.png',
      'res/drawable-hdpi/splashscreen_logo.png',
      'res/drawable-xhdpi/splashscreen_logo.png',
      'res/drawable-xxhdpi/splashscreen_logo.png',
      'res/drawable-xxxhdpi/splashscreen_logo.png',
      'res/drawable-night-mdpi/android12splash.png',
      'res/drawable-night-hdpi/android12splash.png',
      'res/drawable-night-xhdpi/android12splash.png',
      'res/drawable-night-xxhdpi/android12splash.png',
      'res/drawable-night-xxxhdpi/android12splash.png',
      'res/drawable-night-mdpi/splashscreen_logo.png',
      'res/drawable-night-hdpi/splashscreen_logo.png',
      'res/drawable-night-xhdpi/splashscreen_logo.png',
      'res/drawable-night-xxhdpi/splashscreen_logo.png',
      'res/drawable-night-xxxhdpi/splashscreen_logo.png',
      'res/values-v31/styles.xml',
      'res/values-night-v31/styles.xml',
    ],
  });
  assert.deepEqual(contract.android.widgetRefreshAction, {
    broadcastAction: 'es.antonborri.home_widget.action.BACKGROUND',
    uri: 'warWidget://refreshClicked',
    workerName: 'CLASHKING_WIDGET_REFRESH',
    launchesActivity: false,
  });
  assert.equal(contract.legacyStorage.sharedAuthSessionKey, 'shared_auth_session_v1');
  assert.equal(contract.legacyStorage.dynamicAppPreferencePattern, '^player_.*_clan_tag$');
  assert.equal(contract.legacyWidgetStorage.preferencesName, 'HomeWidgetPreferences');
  assert.deepEqual(contract.legacyWidgetStorage.dynamicPrefixes, ['warInfo_', 'upgradeWidget_']);
  assert.equal(contract.androidPinWidgetProvider, 'WarAppWidgetProvider');
  assert.deepEqual(contract.android.warWidgetConfigurationActivity, {
    name: '.WarWidgetConfigureActivity',
    theme: '@style/UpgradeWidgetConfigurationTheme',
  });
  assert.deepEqual(contract.notificationDebug, {
    supportedPlatform: 'ios',
    identifierPrefix: 'clashking-debug-',
    triggerDelaySeconds: 1,
    maximumAttachments: 2,
    sample: {
      id: 'notificationSettings',
      label: 'Notification settings',
      group: 'ClashKing',
      title: 'ClashKing notifications',
      body: 'Push notifications are configured for this device.',
      assetUrl: 'https://assets.clashk.ing/logos/crown-arrow-dark-bg/ClashKing-1.png',
    },
  });
  assert.deepEqual(contract.sceneryAudio, {
    usedSourceKinds: ['network'],
    loadMode: 'disk',
    volume: 1,
    loop: false,
    positionIntervalMilliseconds: 250,
    ios: {
      category: 'playback',
      categoryOptions: 'none',
      expoInterruptionMode: 'doNotMix',
      playsInSilentMode: true,
      backgroundPlayback: false,
    },
    android: {
      usage: 'media',
      contentType: 'music',
      focusGain: 'gainTransientMayDuck',
      willPauseWhenDucked: true,
      expoInterruptionMode: 'duckOthers',
      exactInterruptionParity: true,
      exactAudioAttributesParity: true,
    },
  });
  assert.deepEqual(
    contract.alternateIconOptions.map(({ labelKey, iconName, previewAsset }) => ({
      labelKey,
      iconName,
      previewAsset,
    })),
    [
      {
        labelKey: 'default',
        iconName: null,
        previewAsset: 'assets/icons/app_icon_ios_default.png',
      },
      {
        labelKey: 'christmas',
        iconName: 'AppIconChristmas',
        previewAsset: 'assets/icons/app_icon_christmas.png',
      },
      {
        labelKey: 'black_white',
        iconName: 'AppIconBlackWhite',
        previewAsset: 'assets/icons/app_icon_black_white.png',
      },
      {
        labelKey: 'dark_mode',
        iconName: 'AppIconDarkLogo',
        previewAsset: 'assets/icons/app_icon_dark_logo.png',
      },
    ],
  );
  assert.equal(validateLegacyWidgetContract(contract), contract);

  const iosRoot = requirePath(expoRoot, contract.ios.widgetSourceRoot);
  const androidRoot = requirePath(expoRoot, contract.android.widgetSourceRoot);
  validateRequiredFiles(iosRoot, contract.ios.widgetRequiredFiles);
  validateRequiredFiles(androidRoot, contract.android.widgetRequiredFiles);
  for (const icon of contract.alternateIcons) {
    const catalog = requirePath(
      expoRoot,
      `${contract.alternateIconSourceRoot}/${icon}.appiconset`,
      icon,
    );
    assert.ok(validateAlternateIconCatalog(catalog, icon).length > 0);
  }
});

test('Android splash resources preserve the byte-exact Flutter density and theme contract', () => {
  const expoRoot = path.resolve(__dirname, '../..');
  const contract = require('../../native/parity-contract.json');
  const platformRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'ck-android-splash-'));

  assert.equal(
    copyAndroidSplashResources(expoRoot, platformRoot, contract.android.splashResources),
    22,
  );

  const resourcesRoot = path.join(platformRoot, 'app', 'src', 'main', 'res');
  const expectedHashes = {
    'drawable-mdpi': '380778cd91a10cc445cd4caffb5ba488b616b1fe57262edc1c0f789eea174cec',
    'drawable-hdpi': '52108e61e48aad914f4d81da18ba197352f08777acdddb140af805443e29d01d',
    'drawable-xhdpi': '4823ab42bf1e8eb33a20e43e4b587868312848265e60efb8b1502b5cddddbf73',
    'drawable-xxhdpi': '6a27e656561d68043df6726c02884b546a622078b7b7978b80100724aba2e0be',
    'drawable-xxxhdpi': 'dcf2de7ec1ec721e1767bb3bbf97dc790140177fbdcdabe6d6d2af338a4db2bd',
    'drawable-night-mdpi': 'bfedb4c6041c80cebc9f76b2a84065ad292e01f0ff9346d9042accdab4dc5296',
    'drawable-night-hdpi': '2663c6f5a59aca391ec5c15f3c8461f62f3c16ae22eb9ab84c0b5bdd8add5f98',
    'drawable-night-xhdpi': '50c2ed42cf6eb69b22787f199a81052d5240431ea5844efcafec8ece5b96dd4d',
    'drawable-night-xxhdpi': '0e4b2d21c270dedd96178ad7cbe430c52b9c69f28fb8e415721a5fb7950d659f',
    'drawable-night-xxxhdpi': '83ab44d01db616fefec8e6caf40e2d0aa1ca5890474909d73a9f14a8b7b3dfc1',
  };
  for (const [qualifier, expectedHash] of Object.entries(expectedHashes)) {
    const image = fs.readFileSync(path.join(resourcesRoot, qualifier, 'android12splash.png'));
    assert.equal(createHash('sha256').update(image).digest('hex'), expectedHash);
  }
  const expectedLegacyHashes = {
    'drawable-mdpi': '995e35708deb9ce9eb6b9b57e9117b99a00b721a2cb1abe129f2338a59d44eff',
    'drawable-hdpi': '695a87a151252209715355e8578fc2833e15881fb1294addfdcb6e4f5de2dd4b',
    'drawable-xhdpi': '1c90343eb9766105596ac33b27ba0d856c710d7d8020bd46deb21f0527af151e',
    'drawable-xxhdpi': '6992f48837c4018b26c973a524bf2fb58442585cdfd8aa9f7fabd46de74cf4cc',
    'drawable-xxxhdpi': '9b9f4a6383c844d0c6e757fe0bb70cfe9c7be5a5f12278e67a9a5126eab24306',
    'drawable-night-mdpi': 'd182c7bac9123580c02477cdc53ddfb094d91164c0cfab5bf4d5927e521efddb',
    'drawable-night-hdpi': '38c718029c7558ecc741aa69bddb811e9a3b80b7fbe905c7ba01234837166c59',
    'drawable-night-xhdpi': '2276c754456699dc2be19c72a3b87f0b42253635dc6e2f60df684569f7c4e181',
    'drawable-night-xxhdpi': '5f0541cfc3fe3235ec8d8c2810c03fbcca1b535cf1a784fab48e71687744b2ee',
    'drawable-night-xxxhdpi': '78f72c253daa4a9db8783655cf977e201e8f5f7cfc2ce0dab56bde4873e18321',
  };
  for (const [qualifier, expectedHash] of Object.entries(expectedLegacyHashes)) {
    const image = fs.readFileSync(path.join(resourcesRoot, qualifier, 'splashscreen_logo.png'));
    assert.equal(createHash('sha256').update(image).digest('hex'), expectedHash);
  }

  const expectedStyle = android12SplashStyleXml('android12splash');
  assert.equal(
    fs.readFileSync(path.join(resourcesRoot, 'values-v31', 'styles.xml'), 'utf8'),
    expectedStyle,
  );
  assert.equal(
    fs.readFileSync(path.join(resourcesRoot, 'values-night-v31', 'styles.xml'), 'utf8'),
    expectedStyle,
  );
  assert.match(expectedStyle, /windowSplashScreenIconBackgroundColor/);
  assert.throws(() => android12SplashStyleXml('../outside'), /Invalid Android drawable/);
  assert.equal(
    copyAndroidSplashResources(expoRoot, platformRoot, contract.android.splashResources),
    0,
  );
});

test('alternate icon target build settings are exact and idempotent', () => {
  const configurations = {
    debug: { buildSettings: {} },
    release: { buildSettings: {} },
  };
  const project = {
    pbxXCConfigurationList: () => ({
      list: { buildConfigurations: [{ value: 'debug' }, { value: 'release' }] },
    }),
    pbxXCBuildConfigurationSection: () => configurations,
  };
  const target = { name: 'ClashKing', buildConfigurationList: 'list' };
  const icons = ['AppIconChristmas', 'AppIconBlackWhite', 'AppIconDarkLogo'];
  configureAlternateIconTarget(project, target, icons);
  configureAlternateIconTarget(project, target, icons);
  for (const configuration of Object.values(configurations)) {
    assert.equal(
      configuration.buildSettings.ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES,
      '"AppIconChristmas AppIconBlackWhite AppIconDarkLogo"',
    );
  }
});

test('alternate icon catalogs fail loudly when a referenced image is missing', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'ck-icon-catalog-'));
  fs.writeFileSync(
    path.join(root, 'Contents.json'),
    JSON.stringify({ images: [{ filename: 'missing.png' }] }),
  );
  assert.throws(
    () => validateAlternateIconCatalog(root, 'AppIconMissing'),
    /Missing AppIconMissing image missing\.png/,
  );
});

test('Android component upsert is stable and idempotent', () => {
  const first = { $: { 'android:name': '.First' } };
  const original = [first, { $: { 'android:name': '.Widget' }, old: true }];
  const replacement = { $: { 'android:name': '.Widget' }, exact: true };
  assert.deepEqual(upsertAndroidComponent(original, replacement), [first, replacement]);
  assert.deepEqual(
    upsertAndroidComponent(upsertAndroidComponent(original, replacement), replacement),
    [first, replacement],
  );
});

function notificationMetadata(name, attribute, value, toolsReplace) {
  return {
    $: {
      'android:name': name,
      [attribute]: value,
      ...(toolsReplace ? { 'tools:replace': toolsReplace } : {}),
    },
  };
}

function exactNotificationApplication() {
  return {
    'meta-data': [
      notificationMetadata(
        'com.google.firebase.messaging.default_notification_channel_id',
        'android:value',
        'clashking_push',
        'android:label',
      ),
      notificationMetadata(
        'com.google.firebase.messaging.default_notification_color',
        'android:resource',
        '@color/notification_icon_color',
      ),
      notificationMetadata(
        'com.google.firebase.messaging.default_notification_icon',
        'android:resource',
        '@drawable/notification_icon',
      ),
      notificationMetadata(
        'expo.modules.notifications.default_notification_color',
        'android:resource',
        '@color/notification_icon_color',
      ),
      notificationMetadata(
        'expo.modules.notifications.default_notification_icon',
        'android:resource',
        '@drawable/notification_icon',
      ),
    ],
  };
}

test('Android notification metadata merge fix is exact and idempotent', () => {
  const application = exactNotificationApplication();
  const defaults = {
    channelId: 'clashking_push',
    iconResource: '@drawable/notification_icon',
    colorResource: '@color/notification_icon_color',
  };
  configureAndroidNotificationMetadata(application, defaults);
  const once = JSON.stringify(application);
  configureAndroidNotificationMetadata(application, defaults);
  assert.equal(JSON.stringify(application), once);
  assert.equal(application['meta-data'][0].$['tools:replace'], 'android:label,android:value');
  assert.equal(application['meta-data'][1].$['tools:replace'], 'android:resource');
  assert.equal(application['meta-data'][2].$['tools:replace'], undefined);
});

test('Android notification metadata merge fix fails loudly on missing, duplicate, or drift', () => {
  const defaults = {
    channelId: 'clashking_push',
    iconResource: '@drawable/notification_icon',
    colorResource: '@color/notification_icon_color',
  };
  const missing = exactNotificationApplication();
  missing['meta-data'].shift();
  assert.throws(
    () => configureAndroidNotificationMetadata(missing, defaults),
    /exactly one .*default_notification_channel_id.*found 0/,
  );

  const duplicate = exactNotificationApplication();
  duplicate['meta-data'].push({ ...duplicate['meta-data'][0] });
  assert.throws(
    () => configureAndroidNotificationMetadata(duplicate, defaults),
    /exactly one .*default_notification_channel_id.*found 2/,
  );

  const drifted = exactNotificationApplication();
  drifted['meta-data'][1].$['android:resource'] = '@color/white';
  assert.throws(
    () => configureAndroidNotificationMetadata(drifted, defaults),
    /default_notification_color must set android:resource to @color\/notification_icon_color/,
  );
});

test('widget target receives exact identity and host version settings', () => {
  const configurations = {
    debug: { buildSettings: {} },
    release: { buildSettings: {} },
  };
  const project = {
    pbxXCConfigurationList: () => ({
      list: { buildConfigurations: [{ value: 'debug' }, { value: 'release' }] },
    }),
    pbxXCBuildConfigurationSection: () => configurations,
  };
  const target = { name: '"WarWidgetExtension"', buildConfigurationList: 'list' };
  configureWidgetTarget(
    project,
    target,
    {
      ios: {
        deploymentTarget: '17.0',
        teamIdentifier: 'MZYXD43RX5',
        widgetBundleIdentifier: 'com.clashking.apps.warwidget',
      },
    },
    { buildNumber: '25', marketingVersion: '0.3.5' },
  );
  for (const configuration of Object.values(configurations)) {
    assert.equal(configuration.buildSettings.CURRENT_PROJECT_VERSION, '"25"');
    assert.equal(configuration.buildSettings.MARKETING_VERSION, '"0.3.5"');
    assert.equal(
      configuration.buildSettings.PRODUCT_BUNDLE_IDENTIFIER,
      '"com.clashking.apps.warwidget"',
    );
    assert.equal(
      configuration.buildSettings.REACT_NATIVE_PATH,
      '"$(SRCROOT)/../node_modules/react-native"',
    );
  }
});

test('widget extension is embedded in and required by the application target', () => {
  const application = {
    productType: '"com.apple.product-type.application"',
    buildPhases: [{ value: 'copy', comment: 'Copy Files' }],
    dependencies: [],
  };
  const widget = {
    name: '"WarWidgetExtension"',
    productReference: 'widget-product',
  };
  const objects = {
    PBXNativeTarget: { app: application, widget },
    PBXBuildFile: { embedded: { fileRef: 'widget-product' } },
    PBXCopyFilesBuildPhase: {
      copy: { name: '"Copy Files"', dstSubfolderSpec: 13, files: [{ value: 'embedded' }] },
      copy_comment: 'Copy Files',
    },
  };
  let dependencyAdds = 0;
  const project = {
    hash: { project: { objects } },
    pbxNativeTargetSection: () => objects.PBXNativeTarget,
    pbxBuildFileSection: () => objects.PBXBuildFile,
    addTargetDependency: (applicationTargetUuid, widgetTargetUuids) => {
      dependencyAdds += 1;
      assert.equal(applicationTargetUuid, 'app');
      assert.deepEqual(widgetTargetUuids, ['widget']);
      objects.PBXTargetDependency.dependency = { target: 'widget' };
      application.dependencies.push({ value: 'dependency' });
    },
  };

  configureWidgetEmbedding(project, 'widget', widget);
  configureWidgetEmbedding(project, 'widget', widget);

  assert.equal(dependencyAdds, 1);
  assert.equal(objects.PBXCopyFilesBuildPhase.copy.name, '"Embed App Extensions"');
  assert.equal(objects.PBXCopyFilesBuildPhase.copy_comment, 'Embed App Extensions');
  assert.equal(application.buildPhases[0].comment, 'Embed App Extensions');
});

test('widget source and privacy references have a stable parent group', () => {
  const mainGroup = { children: [] };
  const project = {
    getPBXGroupByKey: (key) => (key === 'main' ? mainGroup : undefined),
    pbxFileReferenceSection: () => ({
      swift: { path: 'WarWidget/WarWidget.swift' },
      swift_comment: 'WarWidget.swift',
      privacy: { path: 'WarWidget/PrivacyInfo.xcprivacy' },
      privacy_comment: 'PrivacyInfo.xcprivacy',
    }),
  };
  const paths = ['WarWidget/WarWidget.swift', 'WarWidget/PrivacyInfo.xcprivacy'];

  attachFileReferencesToGroup(project, paths, 'main');
  attachFileReferencesToGroup(project, paths, 'main');

  assert.deepEqual(mainGroup.children, [
    { value: 'swift', comment: 'WarWidget.swift' },
    { value: 'privacy', comment: 'PrivacyInfo.xcprivacy' },
  ]);
});

test('native bridge exposes dynamic legacy-storage enumeration on both platforms', () => {
  const expoRoot = path.resolve(__dirname, '../..');
  const sources = [
    'modules/clashking-native/types.ts',
    'modules/clashking-native/ios/ClashKingNativeModule.swift',
    'modules/clashking-native/android/src/main/java/com/clashking/nativebridge/ClashKingNativeModule.kt',
  ].map((relativePath) => fs.readFileSync(path.join(expoRoot, relativePath), 'utf8'));
  for (const source of sources) {
    assert.match(source, /readAllLegacyFlutterSecureValues/);
    assert.match(source, /readAllLegacyFlutterPreferences/);
    assert.match(source, /readLegacyWidgetValues/);
    assert.match(source, /requestPinWarWidget/);
  }
});

test('native app icon bridge keeps exact iOS allowlist and Android unsupported behavior', () => {
  const expoRoot = path.resolve(__dirname, '../..');
  const swift = fs.readFileSync(
    path.join(expoRoot, 'modules/clashking-native/ios/ClashKingNativeModule.swift'),
    'utf8',
  );
  const kotlin = fs.readFileSync(
    path.join(
      expoRoot,
      'modules/clashking-native/android/src/main/java/com/clashking/nativebridge/ClashKingNativeModule.kt',
    ),
    'utf8',
  );
  for (const icon of ['AppIconChristmas', 'AppIconBlackWhite', 'AppIconDarkLogo']) {
    assert.match(swift, new RegExp(`"${icon}"`));
  }
  assert.match(swift, /UIApplication\.shared\.supportsAlternateIcons/);
  assert.match(swift, /UIApplication\.shared\.setAlternateIconName/);
  assert.match(kotlin, /AsyncFunction\("supportsAlternateIcons"\) \{ false \}/);
  assert.match(kotlin, /AsyncFunction\("getAlternateIconName"\) \{ null as String\? \}/);
});

test('native notification debug bridge preserves rich attachment and scheduling contract', () => {
  const expoRoot = path.resolve(__dirname, '../..');
  const typescript = fs.readFileSync(
    path.join(expoRoot, 'modules/clashking-native/types.ts'),
    'utf8',
  );
  const swift = fs.readFileSync(
    path.join(expoRoot, 'modules/clashking-native/ios/ClashKingNativeModule.swift'),
    'utf8',
  );
  const kotlin = fs.readFileSync(
    path.join(
      expoRoot,
      'modules/clashking-native/android/src/main/java/com/clashking/nativebridge/ClashKingNativeModule.kt',
    ),
    'utf8',
  );
  for (const source of [typescript, swift, kotlin]) {
    assert.match(source, /showDebugNotification/);
  }
  assert.match(swift, /requestAuthorization\(options: \[\.alert, \.badge, \.sound\]\)/);
  assert.match(swift, /urls\.prefix\(2\)/);
  assert.match(swift, /UNTimeIntervalNotificationTrigger\(timeInterval: 1, repeats: false\)/);
  assert.match(swift, /identifier: "clashking-debug-/);
  assert.match(swift, /"attachmentCount": content\.attachments\.count/);
  assert.match(swift, /code: "permission_failed"/);
  assert.match(swift, /code: "permission_denied"/);
  assert.match(swift, /code: "schedule_failed"/);
  assert.match(kotlin, /only supported by the ClashKing iOS build/);
});

test('legacy widget migration contract fails loudly on key or pin-provider drift', () => {
  const contract = require('../../native/parity-contract.json');
  assert.throws(
    () =>
      validateLegacyWidgetContract({
        ...contract,
        legacyWidgetStorage: {
          ...contract.legacyWidgetStorage,
          fixedKeys: contract.legacyWidgetStorage.fixedKeys.filter(
            (key) => key !== 'warWidgetClans',
          ),
        },
      }),
    /fixedKeys is missing warWidgetClans/,
  );
  assert.throws(
    () =>
      validateLegacyWidgetContract({
        ...contract,
        androidPinWidgetProvider: 'WrongProvider',
      }),
    /androidPinWidgetProvider must be WarAppWidgetProvider/,
  );
});

test('native widget migration is non-destructive and pinning checks platform support', () => {
  const expoRoot = path.resolve(__dirname, '../..');
  const swift = fs.readFileSync(
    path.join(expoRoot, 'modules/clashking-native/ios/ClashKingNativeModule.swift'),
    'utf8',
  );
  const kotlin = fs.readFileSync(
    path.join(
      expoRoot,
      'modules/clashking-native/android/src/main/java/com/clashking/nativebridge/ClashKingNativeModule.kt',
    ),
    'utf8',
  );
  for (const source of [swift, kotlin]) {
    assert.match(source, /warWidgetClans/);
    assert.match(source, /warInfo_/);
    assert.match(source, /upgradeWidget_/);
    assert.doesNotMatch(source, /readLegacyWidgetValues[\s\S]{0,800}(removeObject|\.remove\()/);
  }
  assert.match(swift, /UserDefaults\(suiteName: appGroupIdentifier\)/);
  assert.match(swift, /"supported": false, "requested": false/);
  assert.match(kotlin, /Build\.VERSION\.SDK_INT < Build\.VERSION_CODES\.O/);
  assert.match(kotlin, /isRequestPinAppWidgetSupported/);
  assert.match(kotlin, /requestPinAppWidget\(provider, null, null\)/);
  assert.match(kotlin, /WarAppWidgetProvider/);
});

test('native widget lifecycle and refresh action preserve headless Flutter behavior', () => {
  const expoRoot = path.resolve(__dirname, '../..');
  const swift = fs.readFileSync(
    path.join(expoRoot, 'modules/clashking-native/ios/ClashKingNativeModule.swift'),
    'utf8',
  );
  const receiver = fs.readFileSync(
    path.join(
      expoRoot,
      'modules/clashking-native/android/src/main/java/com/clashking/nativebridge/ClashKingWidgetActionReceiver.kt',
    ),
    'utf8',
  );
  assert.match(swift, /OnAppEntersForeground[\s\S]*WidgetCenter\.shared\.reloadAllTimelines\(\)/);
  assert.match(swift, /OnAppEntersBackground[\s\S]*WidgetCenter\.shared\.reloadAllTimelines\(\)/);
  assert.match(receiver, /OneTimeWorkRequestBuilder<BackgroundTaskWork>/);
  assert.match(receiver, /putString\("appScopeKey", context\.packageName\)/);
  assert.match(receiver, /CLASHKING_WIDGET_REFRESH/);
  assert.doesNotMatch(receiver, /startActivity|getLaunchIntentForPackage/);
});

test('Android war widget mirrors the iOS matchup hierarchy', () => {
  const expoRoot = path.resolve(__dirname, '../..');
  const androidRoot = path.join(expoRoot, 'native/android/app/src/main');
  const kotlin = fs.readFileSync(
    path.join(androidRoot, 'kotlin/com/clashking/clashkingapp/WarAppWidgetProvider.kt'),
    'utf8',
  );
  const layout = fs.readFileSync(path.join(androidRoot, 'res/layout/widget_layout.xml'), 'utf8');
  const background = fs.readFileSync(
    path.join(androidRoot, 'res/drawable/war_widget_background.xml'),
    'utf8',
  );
  const lightColors = fs.readFileSync(
    path.join(androidRoot, 'res/values/widget_colors.xml'),
    'utf8',
  );
  const darkColors = fs.readFileSync(
    path.join(androidRoot, 'res/values-night/widget_colors.xml'),
    'utf8',
  );
  const provider = fs.readFileSync(path.join(androidRoot, 'res/xml/widget_provider.xml'), 'utf8');
  const configuration = fs.readFileSync(
    path.join(androidRoot, 'kotlin/com/clashking/clashkingapp/WarWidgetConfigureActivity.kt'),
    'utf8',
  );
  const selectionStore = fs.readFileSync(
    path.join(androidRoot, 'kotlin/com/clashking/clashkingapp/WarWidgetSelectionStore.kt'),
    'utf8',
  );

  assert.match(layout, /@drawable\/war_widget_background/);
  assert.match(layout, /@\+id\/clan_flag/);
  assert.match(layout, /@\+id\/text_score/);
  assert.match(layout, /@\+id\/text_state/);
  assert.match(layout, /@\+id\/opponent_flag/);
  assert.doesNotMatch(layout, /text_update_time|refresh_icon|clan_attacks|opponent_attacks/);
  assert.match(background, /@color\/war_widget_background/);
  assert.match(background, /@color\/war_widget_border/);
  assert.match(lightColors, /war_widget_background/);
  assert.match(lightColors, /#FAF7F7F9/);
  assert.match(darkColors, /war_widget_background/);
  assert.match(darkColors, /#F9070708/);
  assert.match(provider, /android:previewLayout="@layout\/widget_layout"/);
  assert.match(
    provider,
    /android:configure="com\.clashking\.clashkingapp\.WarWidgetConfigureActivity"/,
  );
  assert.match(provider, /android:widgetFeatures="reconfigurable"/);
  assert.doesNotMatch(provider, /android:previewImage/);
  assert.match(configuration, /getString\("warWidgetClans"/);
  assert.match(configuration, /WarWidgetSelectionStore\.saveSelectedTag/);
  assert.match(selectionStore, /SELECTED_TAG_PREFIX = "selectedTag_"/);
  assert.match(selectionStore, /"\$SELECTED_TAG_PREFIX\$appWidgetId"/);
  assert.match(kotlin, /WarWidgetSelectionStore\.selectedTag\(context, appWidgetId\)/);
  assert.match(kotlin, /"warInfo_\$\{WarWidgetSelectionStore\.normalizeTag\(it\)\}"/);
  assert.match(kotlin, /getString\("warWidgetSelectedClan", null\)/);
  assert.match(
    kotlin,
    /selectedDefaultTag == WarWidgetSelectionStore\.normalizeTag\(selectedTag\)/,
  );
  assert.match(kotlin, /WarWidgetSelectionStore\.delete\(context, appWidgetIds\)/);
  assert.match(kotlin, /val score = normalizedScore\(warInfo\)/);
  assert.match(
    kotlin,
    /val status = displayText\(warInfo, context\.getString\(R\.string\.war_widget_status\)\)/,
  );
  assert.match(kotlin, /if \(score\.length >= 7\) 24f else 28f/);
  assert.doesNotMatch(kotlin, /applyColorTheme|setBackgroundColor|text_update_time|refresh_icon/);
});

test('Android upgrade widget follows the system night mode palette', () => {
  const expoRoot = path.resolve(__dirname, '../..');
  const androidRoot = path.join(expoRoot, 'native/android/app/src/main');
  const darkColors = fs.readFileSync(
    path.join(androidRoot, 'res/values-night/widget_colors.xml'),
    'utf8',
  );

  for (const color of [
    'widget_background',
    'widget_text',
    'widget_text_secondary',
    'widget_surface',
    'widget_config_surface',
    'widget_config_selected_surface',
    'widget_config_border',
    'widget_accent',
    'widget_boost_orange_surface',
    'widget_boost_purple_surface',
    'widget_boost_pink_surface',
    'widget_warning_surface',
    'widget_warning_text',
    'widget_status_idle',
    'widget_status_maxed',
  ]) {
    assert.match(darkColors, new RegExp(`<color name="${color}">`));
  }
  assert.match(darkColors, /<color name="widget_background">#F9070708<\/color>/);
  assert.match(darkColors, /<color name="widget_surface">#FF18181B<\/color>/);
  assert.match(darkColors, /<color name="widget_text">#FFFFFFFF<\/color>/);
});

test('native scenery audio bridge preserves exact Flutter session, focus, cache, and cadence', () => {
  const expoRoot = path.resolve(__dirname, '../..');
  const swift = fs.readFileSync(
    path.join(expoRoot, 'modules/clashking-native/ios/ClashKingNativeModule.swift'),
    'utf8',
  );
  const kotlin = fs.readFileSync(
    path.join(
      expoRoot,
      'modules/clashking-native/android/src/main/java/com/clashking/nativebridge/ClashKingNativeModule.kt',
    ),
    'utf8',
  );
  assert.match(swift, /setCategory\(\.playback, mode: \.default, options: \[\]\)/);
  assert.match(swift, /appendingPathComponent\("scenery-audio"/);
  assert.match(swift, /CMTime\(value: 1, timescale: 4\)/);
  assert.match(swift, /player\.volume = 1/);
  assert.match(swift, /player\.actionAtItemEnd = \.pause/);
  assert.match(kotlin, /AudioAttributes\.USAGE_MEDIA/);
  assert.match(kotlin, /AudioAttributes\.CONTENT_TYPE_MUSIC/);
  assert.match(kotlin, /AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK/);
  assert.match(kotlin, /setWillPauseWhenDucked\(true\)/);
  assert.match(kotlin, /AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK[\s\S]{0,300}player\?\.pause\(\)/);
  assert.match(kotlin, /File\(context\.cacheDir, "scenery-audio"\)/);
  assert.match(kotlin, /handler\.postDelayed\(this, 250L\)/);
  assert.match(kotlin, /isLooping = false/);
  assert.match(kotlin, /setVolume\(1f, 1f\)/);
});
