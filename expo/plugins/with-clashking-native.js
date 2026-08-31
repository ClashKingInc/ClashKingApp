'use strict';

const fs = require('node:fs');
const path = require('node:path');
const {
  AndroidConfig,
  IOSConfig,
  withAndroidManifest,
  withDangerousMod,
  withEntitlementsPlist,
  withFinalizedMod,
  withInfoPlist,
  withPodfile,
  withXcodeProject,
} = require('expo/config-plugins');
const ExpoPlist = require('@expo/plist').default;
const {
  appendUnique,
  assertExact,
  copyTreeIfChanged,
  requirePath,
  validateRelativeTarget,
  validateRequiredFiles,
} = require('./native-parity-helpers');

function loadContract(projectRoot, contractPath) {
  const resolved = requirePath(
    projectRoot,
    contractPath || './native/parity-contract.json',
    'native parity contract',
  );
  delete require.cache[resolved];
  const contract = require(resolved);
  validateLegacyWidgetContract(contract);
  return contract;
}

function validateLegacyWidgetContract(contract) {
  if (contract.ios?.rnFirebaseDependencyManager !== 'cocoapods') {
    throw new Error('ios.rnFirebaseDependencyManager must be cocoapods.');
  }
  const widget = contract.legacyWidgetStorage;
  const requiredKeys = [
    'warWidgetClans',
    'warWidgetSelectedClan',
    'warInfo',
    'warWidgetProxyUrl',
    'warWidgetApiV2Url',
    'upgradeWidgetAccounts',
    'upgradeWidgetData',
    'upgradeWidgetSelectedTag',
  ];
  if (widget?.preferencesName !== 'HomeWidgetPreferences') {
    throw new Error('legacyWidgetStorage.preferencesName must be HomeWidgetPreferences.');
  }
  for (const key of requiredKeys) {
    if (!widget.fixedKeys?.includes(key)) {
      throw new Error(`legacyWidgetStorage.fixedKeys is missing ${key}.`);
    }
  }
  for (const prefix of ['warInfo_', 'upgradeWidget_']) {
    if (!widget.dynamicPrefixes?.includes(prefix)) {
      throw new Error(`legacyWidgetStorage.dynamicPrefixes is missing ${prefix}.`);
    }
  }
  if (contract.androidPinWidgetProvider !== 'WarAppWidgetProvider') {
    throw new Error('androidPinWidgetProvider must be WarAppWidgetProvider.');
  }
  const notificationDefaults = contract.android?.notificationDefaults;
  if (
    notificationDefaults?.channelId !== 'clashking_push' ||
    notificationDefaults.iconResource !== '@drawable/notification_icon' ||
    notificationDefaults.colorResource !== '@color/notification_icon_color'
  ) {
    throw new Error(
      'android.notificationDefaults must match the shipping ClashKing notification channel, icon, and color.',
    );
  }
  const splashResources = contract.android?.splashResources;
  if (
    splashResources?.sourceRoot !== './native/android/splash' ||
    splashResources.android12ResourceName !== 'android12splash' ||
    splashResources.preAndroid12ResourceName !== 'splashscreen_logo' ||
    JSON.stringify(splashResources.requiredFiles) !== JSON.stringify(ANDROID_SPLASH_REQUIRED_FILES)
  ) {
    throw new Error(
      'android.splashResources must retain every shipping Flutter splash density and theme asset.',
    );
  }
  const widgetRefreshAction = contract.android?.widgetRefreshAction;
  if (
    widgetRefreshAction?.broadcastAction !== 'es.antonborri.home_widget.action.BACKGROUND' ||
    widgetRefreshAction.uri !== 'warWidget://refreshClicked' ||
    widgetRefreshAction.workerName !== 'CLASHKING_WIDGET_REFRESH' ||
    widgetRefreshAction.launchesActivity !== false
  ) {
    throw new Error(
      'android.widgetRefreshAction must preserve the headless Flutter widget-refresh contract.',
    );
  }
  const expectedIconOptions = [
    ['default', null, 'assets/icons/app_icon_ios_default.png'],
    ['christmas', 'AppIconChristmas', 'assets/icons/app_icon_christmas.png'],
    ['black_white', 'AppIconBlackWhite', 'assets/icons/app_icon_black_white.png'],
    ['dark_mode', 'AppIconDarkLogo', 'assets/icons/app_icon_dark_logo.png'],
  ];
  if (
    JSON.stringify(contract.alternateIcons) !==
    JSON.stringify(expectedIconOptions.slice(1).map((option) => option[1]))
  ) {
    throw new Error('alternateIcons must match the shipping Flutter alternate icon names.');
  }
  const actualIconOptions = contract.alternateIconOptions?.map((option) => [
    option.labelKey,
    option.iconName,
    option.previewAsset,
  ]);
  if (JSON.stringify(actualIconOptions) !== JSON.stringify(expectedIconOptions)) {
    throw new Error('alternateIconOptions must match the shipping Flutter AppIconService options.');
  }
  const notificationDebug = contract.notificationDebug;
  if (
    notificationDebug?.supportedPlatform !== 'ios' ||
    notificationDebug.identifierPrefix !== 'clashking-debug-' ||
    notificationDebug.triggerDelaySeconds !== 1 ||
    notificationDebug.maximumAttachments !== 2
  ) {
    throw new Error('notificationDebug must match the shipping iOS notification debug plugin.');
  }
  const audio = contract.sceneryAudio;
  if (
    JSON.stringify(audio?.usedSourceKinds) !== JSON.stringify(['network']) ||
    audio.loadMode !== 'disk' ||
    audio.volume !== 1 ||
    audio.loop !== false ||
    audio.positionIntervalMilliseconds !== 250 ||
    audio.ios?.category !== 'playback' ||
    audio.ios?.categoryOptions !== 'none' ||
    audio.ios?.expoInterruptionMode !== 'doNotMix' ||
    audio.android?.focusGain !== 'gainTransientMayDuck' ||
    audio.android?.willPauseWhenDucked !== true ||
    audio.android?.expoInterruptionMode !== 'duckOthers' ||
    audio.android?.exactInterruptionParity !== true ||
    audio.android?.exactAudioAttributesParity !== true
  ) {
    throw new Error('sceneryAudio must match the shipping Flutter audio behavior exactly.');
  }
  return contract;
}

const RNFIREBASE_DISABLE_SPM_ASSIGNMENT = '$RNFirebaseDisableSPM = true';

function ensureRNFirebaseCocoaPodsMode(podfile) {
  const assignmentPattern = /^\s*\$RNFirebaseDisableSPM\s*=\s*(true|false)\s*$/gm;
  const assignments = [...podfile.matchAll(assignmentPattern)];
  if (assignments.some((match) => match[1] !== 'true')) {
    throw new Error('$RNFirebaseDisableSPM must not be false in the generated Podfile.');
  }

  const targetMatch = /^target\s+['"][^'"]+['"]\s+do\s*$/m.exec(podfile);
  if (!targetMatch) {
    throw new Error('Generated Podfile has no target block for the RNFirebase CocoaPods switch.');
  }
  if (assignments.length === 1 && assignments[0].index < targetMatch.index) {
    return podfile;
  }

  const withoutAssignments = podfile.replace(assignmentPattern, '').replace(/\n{3,}/g, '\n\n');
  const insertionTarget = /^target\s+['"][^'"]+['"]\s+do\s*$/m.exec(withoutAssignments);
  if (!insertionTarget) {
    throw new Error('Generated Podfile target block disappeared while configuring RNFirebase.');
  }
  return `${withoutAssignments.slice(0, insertionTarget.index)}# RNFirebase requires CocoaPods Firebase when Expo links pods as static frameworks.\n${RNFIREBASE_DISABLE_SPM_ASSIGNMENT}\n\n${withoutAssignments.slice(insertionTarget.index)}`;
}

function withRNFirebaseCocoaPodsMode(config) {
  return withPodfile(config, (mod) => {
    mod.modResults.contents = ensureRNFirebaseCocoaPodsMode(mod.modResults.contents);
    return mod;
  });
}

function assertAndApplyIdentity(config, contract) {
  config.scheme = assertExact('expo.scheme', config.scheme, contract.urlScheme);
  config.ios = config.ios || {};
  config.android = config.android || {};
  config.ios.bundleIdentifier = assertExact(
    'expo.ios.bundleIdentifier',
    config.ios.bundleIdentifier,
    contract.ios.bundleIdentifier,
  );
  config.ios.appleTeamId = assertExact(
    'expo.ios.appleTeamId',
    config.ios.appleTeamId,
    contract.ios.teamIdentifier,
  );
  config.android.package = assertExact(
    'expo.android.package',
    config.android.package,
    contract.android.package,
  );
  return config;
}

function configureFirebaseFiles(config, projectRoot, contract) {
  requirePath(projectRoot, contract.ios.firebaseFile, 'iOS Firebase configuration');
  requirePath(projectRoot, contract.android.firebaseFile, 'Android Firebase configuration');
  config.ios.googleServicesFile = assertExact(
    'expo.ios.googleServicesFile',
    config.ios.googleServicesFile,
    contract.ios.firebaseFile,
  );
  config.android.googleServicesFile = assertExact(
    'expo.android.googleServicesFile',
    config.android.googleServicesFile,
    contract.android.firebaseFile,
  );
  return config;
}

function withClashKingInfoPlist(config, contract) {
  return withInfoPlist(config, (mod) => {
    const plist = mod.modResults;
    configureIosPlatformPlist(plist, contract.backgroundModes);

    const urlTypes = Array.isArray(plist.CFBundleURLTypes)
      ? plist.CFBundleURLTypes.filter((entry) => {
          const schemes = entry && entry.CFBundleURLSchemes;
          return !Array.isArray(schemes) || !schemes.includes(contract.urlScheme);
        })
      : [];
    urlTypes.push({
      CFBundleTypeRole: 'Editor',
      CFBundleURLSchemes: [contract.urlScheme],
    });
    plist.CFBundleURLTypes = urlTypes;

    plist.CFBundleIcons = plist.CFBundleIcons || {};
    plist.CFBundleIcons.CFBundleAlternateIcons = Object.fromEntries(
      contract.alternateIcons.map((iconName) => [
        iconName,
        { CFBundleIconFiles: [iconName], UIPrerenderedIcon: false },
      ]),
    );
    return mod;
  });
}

function configureIosPlatformPlist(plist, backgroundModes) {
  // Expo BackgroundTask is used only by the Android widget scheduler. Keep the
  // iOS shipping capabilities equal to Flutter's remote-push requirement.
  plist.UIBackgroundModes = [...backgroundModes];
  delete plist.BGTaskSchedulerPermittedIdentifiers;
  return plist;
}

function withGeneratedIosPlatformPlist(config, contract) {
  return withFinalizedMod(config, [
    'ios',
    async (mod) => {
      const infoPlistPath = IOSConfig.Paths.getInfoPlistPath(mod.modRequest.projectRoot);
      const plist = ExpoPlist.parse(await fs.promises.readFile(infoPlistPath, 'utf8'));
      configureIosPlatformPlist(plist, contract.backgroundModes);
      await fs.promises.writeFile(infoPlistPath, ExpoPlist.build(plist));
      return mod;
    },
  ]);
}

function withClashKingEntitlements(config, contract) {
  return withEntitlementsPlist(config, (mod) => {
    const entitlements = mod.modResults;
    entitlements['com.apple.security.application-groups'] = appendUnique(
      entitlements['com.apple.security.application-groups'],
      [contract.ios.appGroup],
    );
    entitlements['keychain-access-groups'] = appendUnique(entitlements['keychain-access-groups'], [
      '$(AppIdentifierPrefix)$(PRODUCT_BUNDLE_IDENTIFIER)',
      contract.ios.keychainAccessGroup,
    ]);
    return mod;
  });
}

function androidData(scheme, host, pathValue) {
  return {
    $: {
      'android:scheme': scheme,
      'android:host': host,
      ...(pathValue ? { 'android:path': pathValue } : {}),
    },
  };
}

function withClashKingAndroidLinks(config, contract) {
  return withAndroidManifest(config, (mod) => {
    const application = mod.modResults.manifest.application?.[0];
    if (!application) throw new Error('Generated AndroidManifest has no application node.');
    const activities = application.activity || [];
    const mainActivity = activities.find((activity) =>
      (activity['intent-filter'] || []).some((filter) =>
        (filter.action || []).some(
          (action) => action.$?.['android:name'] === 'android.intent.action.MAIN',
        ),
      ),
    );
    if (!mainActivity) throw new Error('Generated AndroidManifest has no launcher activity.');

    const filters = removeUnscopedAndroidScheme(
      mainActivity['intent-filter'] || [],
      contract.urlScheme,
    );
    const common = {
      action: [{ $: { 'android:name': 'android.intent.action.VIEW' } }],
      category: [
        { $: { 'android:name': 'android.intent.category.DEFAULT' } },
        { $: { 'android:name': 'android.intent.category.BROWSABLE' } },
      ],
    };
    filters.push({
      ...common,
      data: ['player', 'clan', 'war'].map((host) => androidData(contract.urlScheme, host)),
    });
    filters.push({
      ...common,
      data: [androidData(contract.urlScheme, contract.oauthHost, contract.oauthPath)],
    });
    mainActivity['intent-filter'] = filters;
    return mod;
  });
}

function removeUnscopedAndroidScheme(filters, scheme) {
  return filters.flatMap((filter) => {
    const isView = (filter.action || []).some(
      (action) => action.$?.['android:name'] === 'android.intent.action.VIEW',
    );
    if (!isView) return [filter];
    const data = (filter.data || []).filter((entry) => entry.$?.['android:scheme'] !== scheme);
    return data.length === 0 ? [] : [{ ...filter, data }];
  });
}

const BLOCKED_ANDROID_PERMISSIONS = new Set([
  'android.permission.READ_EXTERNAL_STORAGE',
  'android.permission.WRITE_EXTERNAL_STORAGE',
  'android.permission.SYSTEM_ALERT_WINDOW',
]);

function configureAndroidPermissions(manifest) {
  AndroidConfig.Permissions.addBlockedPermissions({ manifest }, [...BLOCKED_ANDROID_PERMISSIONS]);
  return manifest;
}

function withClashKingAndroidPermissions(config) {
  return AndroidConfig.Permissions.withBlockedPermissions(config, [...BLOCKED_ANDROID_PERMISSIONS]);
}

async function configureGeneratedAndroidBuildTypePermissions(platformProjectRoot) {
  const sourceRoot = path.join(platformProjectRoot, 'app', 'src');
  let configuredManifestCount = 0;
  for (const buildType of ['debug', 'debugOptimized']) {
    const manifestPath = path.join(sourceRoot, buildType, 'AndroidManifest.xml');
    if (!fs.existsSync(manifestPath)) continue;

    const androidManifest = await AndroidConfig.Manifest.readAndroidManifestAsync(manifestPath);
    androidManifest.manifest.$ = androidManifest.manifest.$ || {};
    androidManifest.manifest.$['xmlns:tools'] = 'http://schemas.android.com/tools';
    configureAndroidPermissions(androidManifest.manifest);
    await AndroidConfig.Manifest.writeAndroidManifestAsync(manifestPath, androidManifest);
    configuredManifestCount += 1;
  }

  if (configuredManifestCount === 0) {
    throw new Error('Generated Android project has no debug build-type manifest to harden.');
  }
}

function withGeneratedAndroidBuildTypePermissions(config) {
  return withFinalizedMod(config, [
    'android',
    async (mod) => {
      await configureGeneratedAndroidBuildTypePermissions(mod.modRequest.platformProjectRoot);
      return mod;
    },
  ]);
}

const ANDROID_NOTIFICATION_METADATA = {
  firebaseChannel: 'com.google.firebase.messaging.default_notification_channel_id',
  firebaseColor: 'com.google.firebase.messaging.default_notification_color',
  firebaseIcon: 'com.google.firebase.messaging.default_notification_icon',
  expoColor: 'expo.modules.notifications.default_notification_color',
  expoIcon: 'expo.modules.notifications.default_notification_icon',
};

function requireExactAndroidMetadata(application, name, attribute, expected) {
  const matches = (application['meta-data'] || []).filter(
    (entry) => entry.$?.['android:name'] === name,
  );
  if (matches.length !== 1) {
    throw new Error(
      `Generated AndroidManifest must contain exactly one ${name} meta-data entry; found ${matches.length}.`,
    );
  }
  const entry = matches[0];
  if (entry.$?.[attribute] !== expected) {
    throw new Error(
      `Generated AndroidManifest ${name} must set ${attribute} to ${expected}; found ${entry.$?.[attribute] ?? 'nothing'}.`,
    );
  }
  return entry;
}

function appendToolsReplace(entry, attribute) {
  const replacements = (entry.$['tools:replace'] || '')
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean);
  entry.$['tools:replace'] = [...new Set([...replacements, attribute])].join(',');
}

function configureAndroidNotificationMetadata(application, defaults) {
  const channel = requireExactAndroidMetadata(
    application,
    ANDROID_NOTIFICATION_METADATA.firebaseChannel,
    'android:value',
    defaults.channelId,
  );
  const color = requireExactAndroidMetadata(
    application,
    ANDROID_NOTIFICATION_METADATA.firebaseColor,
    'android:resource',
    defaults.colorResource,
  );
  requireExactAndroidMetadata(
    application,
    ANDROID_NOTIFICATION_METADATA.firebaseIcon,
    'android:resource',
    defaults.iconResource,
  );
  requireExactAndroidMetadata(
    application,
    ANDROID_NOTIFICATION_METADATA.expoColor,
    'android:resource',
    defaults.colorResource,
  );
  requireExactAndroidMetadata(
    application,
    ANDROID_NOTIFICATION_METADATA.expoIcon,
    'android:resource',
    defaults.iconResource,
  );
  appendToolsReplace(channel, 'android:value');
  appendToolsReplace(color, 'android:resource');
  return application;
}

function withAndroidNotificationMetadata(config, contract) {
  return withFinalizedMod(config, [
    'android',
    async (mod) => {
      const manifestPath = path.join(
        mod.modRequest.platformProjectRoot,
        'app',
        'src',
        'main',
        'AndroidManifest.xml',
      );
      const androidManifest = await AndroidConfig.Manifest.readAndroidManifestAsync(manifestPath);
      const manifest = androidManifest.manifest;
      const application = manifest.application?.[0];
      if (!application) throw new Error('Generated AndroidManifest has no application node.');
      if (!manifest.$?.['xmlns:tools']) {
        throw new Error('Generated AndroidManifest must declare the tools namespace.');
      }
      configureAndroidNotificationMetadata(application, contract.android.notificationDefaults);
      await AndroidConfig.Manifest.writeAndroidManifestAsync(manifestPath, androidManifest);
      return mod;
    },
  ]);
}

function upsertAndroidComponent(components, component) {
  const name = component.$['android:name'];
  return [...(components || []).filter((entry) => entry.$?.['android:name'] !== name), component];
}

function withAndroidWidgetComponents(config, contract) {
  return withAndroidManifest(config, (mod) => {
    const application = mod.modResults.manifest.application?.[0];
    if (!application) throw new Error('Generated AndroidManifest has no application node.');

    for (const receiver of contract.android.widgetReceivers) {
      const component = {
        $: {
          'android:name': receiver.name,
          'android:exported': 'true',
          ...(receiver.label ? { 'android:label': receiver.label } : {}),
        },
        'intent-filter': [
          {
            action: [{ $: { 'android:name': 'android.appwidget.action.APPWIDGET_UPDATE' } }],
          },
        ],
        'meta-data': [
          {
            $: {
              'android:name': 'android.appwidget.provider',
              'android:resource': receiver.providerResource,
            },
          },
        ],
      };
      application.receiver = upsertAndroidComponent(application.receiver, component);
    }

    for (const activity of [
      contract.android.widgetConfigurationActivity,
      contract.android.warWidgetConfigurationActivity,
    ]) {
      application.activity = upsertAndroidComponent(application.activity, {
        $: {
          'android:name': activity.name,
          'android:exported': 'true',
          'android:theme': activity.theme,
        },
        'intent-filter': [
          {
            action: [{ $: { 'android:name': 'android.appwidget.action.APPWIDGET_CONFIGURE' } }],
          },
        ],
      });
    }
    application.receiver = upsertAndroidComponent(application.receiver, {
      $: {
        'android:name': 'com.clashking.nativebridge.ClashKingWidgetActionReceiver',
        'android:exported': 'false',
      },
      'intent-filter': [
        {
          action: [
            {
              $: { 'android:name': 'es.antonborri.home_widget.action.BACKGROUND' },
            },
          ],
        },
      ],
    });
    return mod;
  });
}

function unquote(value) {
  return typeof value === 'string' ? value.replace(/^"(.*)"$/, '$1') : value;
}

function findTargetByName(project, targetName) {
  return Object.entries(project.pbxNativeTargetSection()).find(
    ([key, target]) => !key.endsWith('_comment') && unquote(target.name) === targetName,
  );
}

function targetBuildConfigurations(project, target) {
  const configurationList = project.pbxXCConfigurationList()[target.buildConfigurationList];
  if (!configurationList) {
    throw new Error(`Missing Xcode configuration list for ${unquote(target.name)}.`);
  }
  const configurations = project.pbxXCBuildConfigurationSection();
  return configurationList.buildConfigurations.map(({ value }) => configurations[value]);
}

function configureWidgetTarget(project, target, contract, version = {}) {
  for (const configuration of targetBuildConfigurations(project, target)) {
    Object.assign(configuration.buildSettings, {
      APPLICATION_EXTENSION_API_ONLY: 'YES',
      CODE_SIGN_ENTITLEMENTS: '"WarWidget/WarWidget.entitlements"',
      CODE_SIGN_STYLE: 'Automatic',
      DEVELOPMENT_TEAM: contract.ios.teamIdentifier,
      GENERATE_INFOPLIST_FILE: 'NO',
      INFOPLIST_FILE: '"WarWidget/Info.plist"',
      IPHONEOS_DEPLOYMENT_TARGET: `"${contract.ios.deploymentTarget}"`,
      CURRENT_PROJECT_VERSION: `"${version.buildNumber || '1'}"`,
      MARKETING_VERSION: `"${version.marketingVersion || '1.0'}"`,
      PRODUCT_BUNDLE_IDENTIFIER: `"${contract.ios.widgetBundleIdentifier}"`,
      PRODUCT_NAME: '"$(TARGET_NAME)"',
      REACT_NATIVE_PATH: '"$(SRCROOT)/../node_modules/react-native"',
      SKIP_INSTALL: 'YES',
      SWIFT_VERSION: '5.0',
      TARGETED_DEVICE_FAMILY: '"1,2"',
    });
  }
}

function configureWidgetEmbedding(project, widgetTargetUuid, widgetTarget) {
  const applicationTargetEntry = Object.entries(project.pbxNativeTargetSection()).find(
    ([key, target]) =>
      !key.endsWith('_comment') &&
      unquote(target.productType) === 'com.apple.product-type.application',
  );
  if (!applicationTargetEntry)
    throw new Error('Generated Xcode project has no application target.');

  const [applicationTargetUuid, applicationTarget] = applicationTargetEntry;
  const objects = project.hash.project.objects;
  objects.PBXTargetDependency ||= {};
  objects.PBXContainerItemProxy ||= {};
  applicationTarget.dependencies ||= [];

  const dependencySection = objects.PBXTargetDependency;
  const hasDependency = applicationTarget.dependencies.some(
    ({ value }) => dependencySection[value]?.target === widgetTargetUuid,
  );
  if (!hasDependency) project.addTargetDependency(applicationTargetUuid, [widgetTargetUuid]);

  const buildFiles = project.pbxBuildFileSection();
  const copyFilesPhases = objects.PBXCopyFilesBuildPhase || {};
  const embeddedPhaseEntry = (applicationTarget.buildPhases || [])
    .map((phaseReference) => [phaseReference, copyFilesPhases[phaseReference.value]])
    .find(([, phase]) =>
      phase?.files?.some(
        ({ value }) => buildFiles[value]?.fileRef === widgetTarget.productReference,
      ),
    );

  if (!embeddedPhaseEntry) {
    project.addBuildPhase(
      [`${unquote(widgetTarget.name)}.appex`],
      'PBXCopyFilesBuildPhase',
      'Embed App Extensions',
      applicationTargetUuid,
      'app_extension',
    );
    return;
  }

  const [phaseReference, embeddedPhase] = embeddedPhaseEntry;
  embeddedPhase.name = '"Embed App Extensions"';
  copyFilesPhases[`${phaseReference.value}_comment`] = 'Embed App Extensions';
  phaseReference.comment = 'Embed App Extensions';
}

function attachFileReferencesToGroup(project, filePaths, groupKey) {
  const group = project.getPBXGroupByKey(groupKey);
  if (!group?.children) throw new Error('Generated Xcode project has no main file group.');

  const fileReferences = project.pbxFileReferenceSection();
  for (const filePath of filePaths) {
    const reference = Object.entries(fileReferences).find(
      ([key, value]) => !key.endsWith('_comment') && unquote(value.path) === filePath,
    );
    if (!reference) throw new Error(`Generated Xcode project is missing ${filePath}.`);

    const [referenceKey] = reference;
    if (!group.children.some((child) => child.value === referenceKey)) {
      group.children.push({ value: referenceKey, comment: path.basename(filePath) });
    }
  }
}

function configureAlternateIconTarget(project, target, iconNames) {
  const setting = `"${iconNames.join(' ')}"`;
  for (const configuration of targetBuildConfigurations(project, target)) {
    configuration.buildSettings.ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES = setting;
  }
}

function withAlternateIconBuildSettings(config, contract) {
  return withXcodeProject(config, (mod) => {
    const targetEntry = Object.entries(mod.modResults.pbxNativeTargetSection()).find(
      ([key, target]) =>
        !key.endsWith('_comment') &&
        unquote(target.productType) === 'com.apple.product-type.application',
    );
    if (!targetEntry) throw new Error('Generated Xcode project has no application target.');
    configureAlternateIconTarget(mod.modResults, targetEntry[1], contract.alternateIcons);
    return mod;
  });
}

function validateAlternateIconCatalog(source, iconName) {
  const manifestPath = requirePath(source, 'Contents.json', `${iconName} Contents.json`);
  let manifest;
  try {
    manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  } catch (error) {
    throw new Error(`Invalid alternate icon manifest for ${iconName}: ${error.message}`);
  }
  const filenames = (manifest.images || [])
    .map((image) => image.filename)
    .filter((filename) => typeof filename === 'string' && filename.length > 0);
  if (filenames.length === 0) throw new Error(`Alternate icon ${iconName} has no image files.`);
  for (const filename of filenames) requirePath(source, filename, `${iconName} image ${filename}`);
  return filenames;
}

function withIosWidgetTarget(config, contract) {
  const version = {
    buildNumber: config.ios?.buildNumber,
    marketingVersion: config.version,
  };
  return withXcodeProject(config, (mod) => {
    const project = mod.modResults;
    const existing = findTargetByName(project, contract.ios.widgetTargetName);
    if (existing) {
      const [targetUuid, target] = existing;
      const bundleIdentifiers = new Set(
        targetBuildConfigurations(project, target).map((configuration) =>
          unquote(configuration.buildSettings.PRODUCT_BUNDLE_IDENTIFIER),
        ),
      );
      if (
        bundleIdentifiers.size !== 1 ||
        !bundleIdentifiers.has(contract.ios.widgetBundleIdentifier)
      ) {
        throw new Error(
          `Xcode target ${contract.ios.widgetTargetName} exists with a different bundle identifier. Run a clean prebuild.`,
        );
      }
      configureWidgetTarget(project, target, contract, version);
      configureWidgetEmbedding(project, targetUuid, target);
      return mod;
    }

    const target = project.addTarget(
      contract.ios.widgetTargetName,
      'app_extension',
      'WarWidget',
      contract.ios.widgetBundleIdentifier,
    );
    project.addBuildPhase(
      ['WarWidget/WarWidget.swift'],
      'PBXSourcesBuildPhase',
      'Sources',
      target.uuid,
      'app_extension',
    );
    project.addBuildPhase(
      ['WarWidget/PrivacyInfo.xcprivacy'],
      'PBXResourcesBuildPhase',
      'Resources',
      target.uuid,
      'app_extension',
    );
    project.addBuildPhase(
      [],
      'PBXFrameworksBuildPhase',
      'Frameworks',
      target.uuid,
      'app_extension',
    );
    attachFileReferencesToGroup(
      project,
      ['WarWidget/WarWidget.swift', 'WarWidget/PrivacyInfo.xcprivacy'],
      project.getFirstProject().firstProject.mainGroup,
    );
    configureWidgetTarget(project, target.pbxNativeTarget, contract, version);
    configureWidgetEmbedding(project, target.uuid, target.pbxNativeTarget);
    return mod;
  });
}

function withAlternateIconAssets(config, projectRoot, contract) {
  return withDangerousMod(config, [
    'ios',
    async (mod) => {
      const sourceCatalog = requirePath(
        projectRoot,
        contract.alternateIconSourceRoot,
        'alternate icon source catalog',
      );
      const destinationCatalog = path.join(
        mod.modRequest.platformProjectRoot,
        mod.modRequest.projectName,
        'Images.xcassets',
      );
      for (const iconName of contract.alternateIcons) {
        const directoryName = `${iconName}.appiconset`;
        const source = requirePath(sourceCatalog, directoryName, `alternate icon ${iconName}`);
        validateAlternateIconCatalog(source, iconName);
        copyTreeIfChanged(source, path.join(destinationCatalog, directoryName));
      }
      return mod;
    },
  ]);
}

const ANDROID_SPLASH_REQUIRED_FILES = [
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
];

function android12SplashStyleXml(resourceName) {
  if (!/^[a-z][a-z0-9_]*$/.test(resourceName)) {
    throw new Error(`Invalid Android drawable resource name: ${resourceName}`);
  }
  return `<?xml version="1.0" encoding="utf-8"?>
<resources>
  <style name="Theme.App.SplashScreen" parent="Theme.SplashScreen">
    <item name="windowSplashScreenBackground">@color/splashscreen_background</item>
    <item name="windowSplashScreenAnimatedIcon">@drawable/${resourceName}</item>
    <item name="windowSplashScreenIconBackgroundColor">@color/splashscreen_background</item>
    <item name="postSplashScreenTheme">@style/AppTheme</item>
  </style>
</resources>
`;
}

function copyAndroidSplashResources(projectRoot, platformProjectRoot, splash) {
  const source = requirePath(projectRoot, splash.sourceRoot, 'Android splash source root');
  validateRequiredFiles(source, splash.requiredFiles);
  const expectedStyle = android12SplashStyleXml(splash.android12ResourceName);
  for (const relativePath of ['res/values-v31/styles.xml', 'res/values-night-v31/styles.xml']) {
    if (fs.readFileSync(path.join(source, relativePath), 'utf8') !== expectedStyle) {
      throw new Error(`Android 12 splash style drifted: ${relativePath}`);
    }
  }
  return copyTreeIfChanged(source, path.join(platformProjectRoot, 'app', 'src', 'main'));
}

function withAndroidSplashResources(config, projectRoot, contract) {
  return withFinalizedMod(config, [
    'android',
    async (mod) => {
      copyAndroidSplashResources(
        projectRoot,
        mod.modRequest.platformProjectRoot,
        contract.android.splashResources,
      );
      return mod;
    },
  ]);
}

function stageNativeInputs(config, projectRoot, contract, options) {
  if (options.stageIosWidgetInputs) {
    config = withDangerousMod(config, [
      'ios',
      async (mod) => {
        const source = requirePath(
          projectRoot,
          contract.ios.widgetSourceRoot,
          'iOS widget source root',
        );
        validateRequiredFiles(source, contract.ios.widgetRequiredFiles);
        const destination = validateRelativeTarget(options.iosWidgetDestination || 'WarWidget');
        copyTreeIfChanged(source, path.join(mod.modRequest.platformProjectRoot, destination));
        return mod;
      },
    ]);
    config = withIosWidgetTarget(config, contract);

    config.extra = config.extra || {};
    config.extra.eas = config.extra.eas || {};
    config.extra.eas.build = config.extra.eas.build || {};
    config.extra.eas.build.experimental = config.extra.eas.build.experimental || {};
    config.extra.eas.build.experimental.ios = config.extra.eas.build.experimental.ios || {};
    config.extra.eas.build.experimental.ios.appExtensions = [
      {
        targetName: contract.ios.widgetTargetName,
        bundleIdentifier: contract.ios.widgetBundleIdentifier,
        entitlements: {
          'com.apple.security.application-groups': [contract.ios.appGroup],
          'keychain-access-groups': [contract.ios.keychainAccessGroup],
        },
      },
    ];
  }

  if (options.stageAndroidWidgetInputs) {
    config = withAndroidWidgetComponents(config, contract);
    config = withDangerousMod(config, [
      'android',
      async (mod) => {
        const source = requirePath(
          projectRoot,
          contract.android.widgetSourceRoot,
          'Android widget source root',
        );
        validateRequiredFiles(source, contract.android.widgetRequiredFiles);
        const destination = validateRelativeTarget(
          options.androidWidgetDestination || 'app/src/main',
        );
        copyTreeIfChanged(source, path.join(mod.modRequest.platformProjectRoot, destination));
        return mod;
      },
    ]);
  }
  return config;
}

function withClashKingNative(config, options = {}) {
  const projectRoot = options.projectRoot || process.cwd();
  const contract = loadContract(projectRoot, options.contractPath);

  config = assertAndApplyIdentity(config, contract);
  config = configureFirebaseFiles(config, projectRoot, contract);
  config = withClashKingInfoPlist(config, contract);
  config = withClashKingEntitlements(config, contract);
  config = withClashKingAndroidLinks(config, contract);
  config = withClashKingAndroidPermissions(config);
  config = withGeneratedAndroidBuildTypePermissions(config);
  config = withAndroidNotificationMetadata(config, contract);
  config = withAndroidSplashResources(config, projectRoot, contract);
  config = withRNFirebaseCocoaPodsMode(config);
  config = withGeneratedIosPlatformPlist(config, contract);
  if (options.stageAlternateIcons !== false) {
    config = withAlternateIconBuildSettings(config, contract);
    config = withAlternateIconAssets(config, projectRoot, contract);
  }
  return stageNativeInputs(config, projectRoot, contract, options);
}

module.exports = withClashKingNative;
module.exports.assertAndApplyIdentity = assertAndApplyIdentity;
module.exports.configureFirebaseFiles = configureFirebaseFiles;
module.exports.upsertAndroidComponent = upsertAndroidComponent;
module.exports.findTargetByName = findTargetByName;
module.exports.configureWidgetTarget = configureWidgetTarget;
module.exports.configureWidgetEmbedding = configureWidgetEmbedding;
module.exports.attachFileReferencesToGroup = attachFileReferencesToGroup;
module.exports.configureAlternateIconTarget = configureAlternateIconTarget;
module.exports.validateAlternateIconCatalog = validateAlternateIconCatalog;
module.exports.validateLegacyWidgetContract = validateLegacyWidgetContract;
module.exports.ensureRNFirebaseCocoaPodsMode = ensureRNFirebaseCocoaPodsMode;
module.exports.configureAndroidNotificationMetadata = configureAndroidNotificationMetadata;
module.exports.configureAndroidPermissions = configureAndroidPermissions;
module.exports.configureGeneratedAndroidBuildTypePermissions =
  configureGeneratedAndroidBuildTypePermissions;
module.exports.configureIosPlatformPlist = configureIosPlatformPlist;
module.exports.removeUnscopedAndroidScheme = removeUnscopedAndroidScheme;
module.exports.android12SplashStyleXml = android12SplashStyleXml;
module.exports.copyAndroidSplashResources = copyAndroidSplashResources;
