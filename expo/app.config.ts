import type { ExpoConfig, ConfigContext } from 'expo/config';

const version = process.env.CK_APP_VERSION?.trim() || '0.3.5';
const buildNumber = process.env.CK_BUILD_NUMBER?.trim() || '25';

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
    runtimeVersion: { policy: 'fingerprint' },
    updates: { enabled: false },
    ios: {
      bundleIdentifier: 'com.clashking.apps',
      appleTeamId: 'MZYXD43RX5',
      buildNumber,
      supportsTablet: true,
      requireFullScreen: true,
      icon: './assets/clashking/icons/app_icon_ios_default.png',
      googleServicesFile: './config/firebase/GoogleService-Info.plist',
      infoPlist: {
        CADisableMinimumFrameDurationOnPhone: true,
        NSPhotoLibraryUsageDescription:
          'ClashKing uses photo library access only when you choose to share generated progress images with a compatible app.',
        UIFileSharingEnabled: true,
        LSSupportsOpeningDocumentsInPlace: true,
        UISupportsDocumentBrowser: true,
        UIRequiresFullScreen: true,
        UISupportedInterfaceOrientations: ['UIInterfaceOrientationPortrait'],
        'UISupportedInterfaceOrientations~ipad': ['UIInterfaceOrientationPortrait'],
      },
    },
    android: {
      package: 'com.clashking.clashkingapp',
      versionCode: Number(buildNumber),
      googleServicesFile: './config/firebase/google-services.json',
      icon: './assets/clashking/icons/icon-play-store.png',
      adaptiveIcon: {
        backgroundColor: '#000000',
        foregroundImage: './assets/clashking/icons/icon-play-store.png',
        monochromeImage: './assets/clashking/icons/app_icon_black_white.png',
      },
      permissions: ['INTERNET', 'POST_NOTIFICATIONS'],
      predictiveBackGestureEnabled: false,
    },
    web: {
      bundler: 'metro',
      output: 'static',
      name: 'clashkingapp',
      shortName: 'clashkingapp',
      lang: 'en',
      startUrl: '.',
      display: 'standalone',
      orientation: 'portrait-primary',
      backgroundColor: '#0175C2',
      themeColor: '#0175C2',
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
