import type { ExpoConfig, ConfigContext } from 'expo/config';

const version = process.env.CK_APP_VERSION?.trim() || '0.4.2';
const buildNumber = process.env.CK_BUILD_NUMBER?.trim() || '25';
const updatesEnabled = process.env.CK_ENABLE_UPDATES === 'true';
const updateChannel = process.env.CK_RELEASE_TRACK?.trim() || 'production';
const updateCertificatePath = process.env.CK_UPDATES_CERTIFICATE_PATH?.trim();
const explicitRuntimeVersion = process.env.CK_RUNTIME_VERSION?.trim();

if (updatesEnabled && !updateCertificatePath) {
  throw new Error('CK_UPDATES_CERTIFICATE_PATH is required when release updates are enabled.');
}

if (!/^[1-9]\d*$/.test(buildNumber)) {
  throw new Error('CK_BUILD_NUMBER must be a positive integer string.');
}
type ClashKingExpoConfig = ExpoConfig & { newArchEnabled: boolean };

export default ({ config }: ConfigContext): ExpoConfig => {
  const clashKingConfig: ClashKingExpoConfig = {
    ...config,
    name: 'ClashKing',
    slug: 'clashking-app',
    version,
    orientation: 'portrait',
    icon: './assets/clashking/icons/icon-play-store.png',
    scheme: 'clashking',
    userInterfaceStyle: 'automatic',
    newArchEnabled: true,
    runtimeVersion: explicitRuntimeVersion || { policy: 'fingerprint' },
    updates: updatesEnabled
      ? {
          enabled: true,
          url:
            process.env.CK_UPDATES_URL?.trim() || 'https://api.clashk.ing/v2/app/updates/manifest',
          requestHeaders: { 'expo-channel-name': updateChannel },
          checkAutomatically: 'NEVER',
          fallbackToCacheTimeout: 0,
          ...(updateCertificatePath
            ? {
                codeSigningCertificate: updateCertificatePath,
                codeSigningMetadata: { keyid: 'main', alg: 'rsa-v1_5-sha256' as const },
              }
            : {}),
        }
      : { enabled: false },
    ios: {
      bundleIdentifier: 'com.clashking.apps',
      appleTeamId: 'MZYXD43RX5',
      buildNumber,
      supportsTablet: true,
      associatedDomains: ['applinks:app.clashk.ing'],
      requireFullScreen: true,
      icon: './assets/clashking/icons/app_icon_ios_default.png',
      googleServicesFile: './config/firebase/GoogleService-Info.plist',
      infoPlist: {
        CADisableMinimumFrameDurationOnPhone: true,
        ITSAppUsesNonExemptEncryption: false,
        NSPhotoLibraryUsageDescription:
          'ClashKing uses photo library access only when you choose to share generated progress images with a compatible app.',
        UIFileSharingEnabled: true,
        LSSupportsOpeningDocumentsInPlace: true,
        UISupportsDocumentBrowser: true,
        UIRequiresFullScreen: true,
        UISupportedInterfaceOrientations: ['UIInterfaceOrientationPortrait'],
        'UISupportedInterfaceOrientations~ipad': [
          'UIInterfaceOrientationPortrait',
          'UIInterfaceOrientationLandscapeLeft',
          'UIInterfaceOrientationLandscapeRight',
        ],
      },
    },
    android: {
      package: 'com.clashking.clashkingapp',
      versionCode: Number(buildNumber),
      googleServicesFile: './config/firebase/google-services.json',
      icon: './assets/clashking/icons/icon-play-store.png',
      adaptiveIcon: {
        backgroundColor: '#FFFFFF',
        foregroundImage: './public/icons/Icon-maskable-512.png',
        monochromeImage: './assets/clashking/icons/app_icon_black_white.png',
      },
      permissions: ['INTERNET', 'POST_NOTIFICATIONS'],
      intentFilters: [
        {
          action: 'VIEW',
          autoVerify: true,
          category: ['BROWSABLE', 'DEFAULT'],
          data: [
            ...[
              '/',
              '/players',
              '/clans',
              '/war',
              '/search',
              '/todo',
              '/ranked',
              '/upgrade-tracker',
              '/rankings',
              '/stats',
              '/calculators',
              '/posts',
              '/bases-armies',
              '/game-assets',
              '/achievements',
              '/accounts',
              '/subscription',
              '/settings',
            ].map((path) => ({ scheme: 'https', host: 'app.clashk.ing', path })),
            ...['/player/', '/clan/', '/war/', '/posts/', '/settings/'].map((pathPrefix) => ({
              scheme: 'https',
              host: 'app.clashk.ing',
              pathPrefix,
            })),
          ],
        },
      ],
      predictiveBackGestureEnabled: false,
    },
    web: {
      bundler: 'metro',
      output: 'static',
      name: 'ClashKing',
      shortName: 'ClashKing',
      lang: 'en',
      startUrl: '.',
      display: 'standalone',
      orientation: 'portrait-primary',
      backgroundColor: '#FFFFFF',
      themeColor: '#000000',
      barStyle: 'black',
      description:
        'ClashKing helps players and clans track wars, upgrades, rankings, and account progress.',
      preferRelatedApplications: false,
      splash: {
        backgroundColor: '#FFFFFF',
        image: './assets/clashking/icons/app_icon_light_mode.png',
        resizeMode: 'contain',
      },
    },
    plugins: [
      'expo-router',
      'expo-localization',
      'expo-image',
      '@react-native-firebase/app',
      '@react-native-firebase/messaging',
      [
        'expo-notifications',
        {
          icon: './assets/clashking/icons/ic_stat_clashking.png',
          color: '#D90709',
          defaultChannel: 'clashking_push',
        },
      ],
      [
        'expo-splash-screen',
        {
          ios: {
            backgroundColor: '#FFFFFF',
            image: './assets/clashking/icons/splashIOSlight.png',
            enableFullScreenImage_legacy: true,
            resizeMode: 'contain',
            dark: {
              backgroundColor: '#000000',
              image: './assets/clashking/icons/splashIOSdark.png',
            },
          },
          android: {
            backgroundColor: '#FFFFFF',
            image: './assets/clashking/icons/app_icon_light_mode.png',
            imageWidth: 128,
            resizeMode: 'contain',
            dark: {
              backgroundColor: '#000000',
              image: './assets/clashking/icons/app_icon_dark_mode.png',
            },
          },
        },
      ],
      [
        'expo-build-properties',
        {
          ios: {
            deploymentTarget: '17.0',
            useFrameworks: 'static',
            ccacheEnabled: true,
          },
          android: {
            minSdkVersion: 24,
            compileSdkVersion: 36,
            targetSdkVersion: 36,
            kotlinVersion: '2.1.20',
          },
        },
      ],
      ['expo-secure-store', { configureAndroidBackup: true }],
      'expo-background-task',
      'expo-sharing',
      ['react-native-share', { android: [], ios: [], enableBase64ShareAndroid: false }],
      [
        'expo-audio',
        {
          microphonePermission: false,
          recordAudioAndroid: false,
          enableBackgroundPlayback: false,
        },
      ],
      [
        './plugins/with-clashking-native',
        {
          contractPath: './native/parity-contract.json',
          stageAlternateIcons: true,
          stageIosWidgetInputs: true,
          stageAndroidWidgetInputs: true,
        },
      ],
      './plugins/with-android-release-signing',
    ],
    experiments: {
      typedRoutes: true,
      reactCompiler: true,
    },
    extra: {
      clashKing: {
        apiEnvironment: process.env.EXPO_PUBLIC_CK_API_ENV ?? 'production',
      },
    },
  };
  return clashKingConfig;
};
