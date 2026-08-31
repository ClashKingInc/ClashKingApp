import { useEffect, useMemo, useReducer, useState } from 'react';
import * as Clipboard from 'expo-clipboard';
import { File, Paths } from 'expo-file-system';
import * as Linking from 'expo-linking';
import * as Sharing from 'expo-sharing';
import { Platform } from 'react-native';

import { APP_FEATURE_FLAGS } from '../../../core/feature-flags/feature-flags';
import { useI18n, type SupportedLocale } from '../../../i18n';
import { ClashHandoffDialog } from '../../../ui';
import { useAppRuntime, useAppState } from '../../../core/app/runtime-context';
import { APP_ICON_OPTIONS } from '../app-icons/app-icon-service';
import { clanOptionsFromProfiles } from '../../widgets';
import type {
  ExternalSettingsActions,
  NotificationSettingsPresentationService,
  PrivacyPresentationActions,
  SettingsDestination,
  SettingsPresentationActions,
} from './contracts';
import { FaqScreen } from './faq-screen';
import { GENERATED_LICENSE_INVENTORY } from './generated-license-inventory';
import { LicensesScreen } from './licenses-screen';
import { NotificationSettingsScreen } from './notification-settings-screen';
import { PrivacyControlsScreen } from './privacy-controls-screen';
import { SETTINGS_LOCALES } from './settings-locales';
import { getVersionDeviceLabel } from './settings-runtime';
import { SettingsScreen, type SettingsAppIconChoice } from './settings-screen';
import { TranslationScreen } from './translation-screen';

type SettingsScene = 'main' | SettingsDestination | 'licenses';

const DISCORD_URL = 'https://discord.gg/clashking';
const GITHUB_URL = 'https://github.com/ClashKingInc';
const BOT_INVITE_URL =
  'https://discord.com/api/oauth2/authorize?client_id=824653933347209227&permissions=8&scope=bot%20applications.commands';
const FAN_CONTENT_URL = 'https://supercell.com/en/fan-content-policy/';
const PATREON_URL = 'https://www.patreon.com/clashking?utm_campaign=creatorshare_creator';
const CROWDIN_URL = 'https://crowdin.com/project/clashkingapp';
const CROWDIN_INVITE_URL =
  'https://crowdin.com/project/clashkingapp/invite?h=87a407268713f1cb79724a2e0c00a5d52098842';
const PRIVACY_URL = 'https://clashk.ing/privacy';
const SUPPORT_EMAIL_URL = 'mailto:devs@clashk.ing?subject=App%20Inquiry';
const PRIVACY_EMAIL_URL =
  'mailto:devs@clashk.ing?subject=ClashKing%20privacy%20request&body=Hello%20ClashKing%20team%2C%0A%0AI%20want%20to%20exercise%20a%20privacy%20right%20for%20my%20account.%20Please%20help%20me%20with%3A%0A%0A-%20Access%2Fexport%0A-%20Correction%0A-%20Deletion%0A-%20Consent%20withdrawal%0A-%20Other%3A%0A%0AAccount%20email%20or%20Discord%20username%3A%0A%0AThank%20you.';

export function SettingsRoot({ onClose }: { onClose: () => void }) {
  const runtime = useAppRuntime();
  const appState = useAppState();
  const { t, locale } = useI18n();
  const [domainRevision, refreshDomainState] = useReducer((value: number) => value + 1, 0);
  const [scene, setScene] = useState<SettingsScene>('main');
  const [versionLabel, setVersionLabel] = useState(t('generalLoading'));
  const [alternateIconsSupported, setAlternateIconsSupported] = useState(false);
  const [selectedAppIcon, setSelectedAppIcon] = useState<string>('');
  const [clashHandoffUrl, setClashHandoffUrl] = useState<string>();

  useEffect(() => {
    const unsubscribePlayers = runtime.players.subscribe(refreshDomainState);
    const unsubscribeBookmarks = runtime.bookmarks.subscribe(refreshDomainState);
    return () => {
      unsubscribePlayers();
      unsubscribeBookmarks();
    };
  }, [runtime]);

  useEffect(() => {
    let active = true;
    void getVersionDeviceLabel()
      .then((label) => {
        if (active) setVersionLabel(label);
      })
      .catch(() => {
        if (active) setVersionLabel(t('errorLoadingVersion'));
      });
    return () => {
      active = false;
    };
  }, [t]);

  useEffect(() => {
    let active = true;
    void runtime.appIcons.supportsAlternateIcons().then(async (supported) => {
      const iconName = supported ? await runtime.appIcons.getAlternateIconName() : null;
      if (!active) return;
      setAlternateIconsSupported(supported);
      setSelectedAppIcon(iconName ?? '');
    });
    return () => {
      active = false;
    };
  }, [runtime]);

  const widgetClans = useMemo(() => {
    void domainRevision;
    return clanOptionsFromProfiles(runtime.players.profiles, runtime.bookmarks.clans);
  }, [domainRevision, runtime]);
  useEffect(() => {
    if (!appState.isFeatureEnabled(APP_FEATURE_FLAGS.warWidgets) || widgetClans.length === 0)
      return;
    void runtime.warWidgets.cacheClanOptions(widgetClans).catch(() => undefined);
  }, [appState, runtime, widgetClans]);

  const notificationService = useMemo<NotificationSettingsPresentationService>(
    () => ({
      loadLocal: () => runtime.notificationPreferences.loadLocal(),
      load: () => runtime.notificationPreferences.load(),
      save: (settings) => runtime.notificationPreferences.save(settings),
      lastPushResult: () => runtime.push.lastResult,
      initializePush: () => runtime.push.initialize(),
      requestPermissionAndRegister: () => runtime.push.requestPermissionAndRegister(),
      tokenPreview: () => runtime.push.tokenPreview(),
      ...(runtime.notificationSettingsDebug
        ? { sendTestNotification: runtime.notificationSettingsDebug.service.sendTestNotification }
        : undefined),
    }),
    [runtime],
  );

  const faqActions = useMemo<ExternalSettingsActions>(
    () => ({
      openCrowdin: () => void openExternal(CROWDIN_URL),
      openDiscord: () => void openExternal(DISCORD_URL),
      openGitHub: () => void openExternal(GITHUB_URL),
      inviteBot: () => void openExternal(BOT_INVITE_URL),
      openFanContentPolicy: () => void openExternal(FAN_CONTENT_URL),
      openPatreon: () => void openExternal(PATREON_URL),
      useCreatorCode: () => {
        const language = locale.split('_', 1)[0]!.toLowerCase();
        setClashHandoffUrl(
          `https://link.clashofclans.com/${language}?action=SupportCreator&id=Clashking`,
        );
      },
      sendEmail: () => openExternal(SUPPORT_EMAIL_URL),
      copySupportEmail: async () => {
        await Clipboard.setStringAsync('devs@clashk.ing');
      },
      openPrivacy: () => setScene('privacy'),
    }),
    [locale],
  );
  const privacyActions = useMemo<PrivacyPresentationActions>(
    () => ({
      requestExport: () => runtime.auth.requestDataExport(),
      saveExport: savePrivacyExport,
      deleteAccount: async () => {
        runtime.players.clearRankedLeagueCache();
        await runtime.auth.deleteAccount();
      },
      openPrivacyPolicy: () => void openExternal(PRIVACY_URL),
      contactSupport: () => void openExternal(PRIVACY_EMAIL_URL),
      onDeleted: () => undefined,
    }),
    [runtime],
  );

  if (scene === 'notifications') {
    return (
      <NotificationSettingsScreen
        debugEnabled={runtime.notificationSettingsDebug !== null}
        onBack={() => setScene('main')}
        service={notificationService}
      />
    );
  }
  if (scene === 'faq') {
    return <FaqScreen actions={faqActions} onBack={() => setScene('main')} />;
  }
  if (scene === 'translation') {
    return (
      <TranslationScreen
        actions={{
          openCrowdin: () => void openExternal(CROWDIN_INVITE_URL),
          openDiscord: () => void openExternal(DISCORD_URL),
        }}
        onBack={() => setScene('main')}
      />
    );
  }
  if (scene === 'privacy') {
    return <PrivacyControlsScreen actions={privacyActions} onBack={() => setScene('main')} />;
  }
  if (scene === 'licenses') {
    return (
      <LicensesScreen
        applicationName={t('appTitle')}
        applicationVersion={versionLabel.split('\n', 1)[0] ?? versionLabel}
        onBack={() => setScene('main')}
        packages={GENERATED_LICENSE_INVENTORY}
      />
    );
  }

  const settingsActions: SettingsPresentationActions = {
    changeLocale: (nextLocale) =>
      runtime.appState.getState().changeLanguage(nextLocale as SupportedLocale),
    changeTheme: (mode) => runtime.appState.getState().setThemePreference(mode),
    changeAppIcon: async (iconName) => {
      await runtime.appIcons.setAlternateIconName(iconName);
      setSelectedAppIcon(iconName ?? '');
    },
    open: setScene,
    openDiscord: () => void openExternal(DISCORD_URL),
    showLicenses: () => setScene('licenses'),
    copyVersion: (value) => void Clipboard.setStringAsync(value),
    logout: async () => {
      runtime.players.clearRankedLeagueCache();
      await runtime.auth.signOut();
    },
  };
  const appIcons: readonly SettingsAppIconChoice[] = APP_ICON_OPTIONS.map((option) => ({
    iconName: option.iconName ?? '',
    label:
      option.labelKey === 'default'
        ? t('appIconDefault')
        : option.labelKey === 'christmas'
          ? t('appIconChristmas')
          : option.labelKey === 'black_white'
            ? t('appIconBlackWhite')
            : t('appIconDarkMode'),
    previewSource: appIconPreview(option.iconName),
  }));

  return (
    <>
      <SettingsScreen
        actions={settingsActions}
        alternateIconsSupported={alternateIconsSupported}
        appIcons={appIcons}
        currentLocale={locale}
        localeChoices={SETTINGS_LOCALES}
        notificationsEnabled={appState.isFeatureEnabled(APP_FEATURE_FLAGS.notifications)}
        onBack={onClose}
        onPrepareWarWidget={async (clanTag, requestPin) => {
          await runtime.warWidgets.prepareClanWidgets(widgetClans, clanTag);
          if (requestPin) await runtime.warWidgets.requestPinnedWarWidget();
        }}
        platform={Platform.OS}
        selectedAppIcon={selectedAppIcon}
        themeMode={appState.themePreference}
        user={runtime.auth.state.currentUser!}
        versionLabel={versionLabel}
        warWidgetClans={widgetClans}
        warWidgetsEnabled={appState.isFeatureEnabled(APP_FEATURE_FLAGS.warWidgets)}
      />
      <ClashHandoffDialog
        onCancel={() => setClashHandoffUrl(undefined)}
        onConfirm={() => {
          const url = clashHandoffUrl;
          setClashHandoffUrl(undefined);
          if (url) void openExternal(url);
        }}
        visible={clashHandoffUrl !== undefined}
      />
    </>
  );
}

function appIconPreview(iconName: string | null) {
  if (iconName === 'AppIconChristmas') {
    return require('../../../../assets/clashking/icons/app_icon_christmas.png');
  }
  if (iconName === 'AppIconBlackWhite') {
    return require('../../../../assets/clashking/icons/app_icon_black_white.png');
  }
  if (iconName === 'AppIconDarkLogo') {
    return require('../../../../assets/clashking/icons/app_icon_dark_logo.png');
  }
  return require('../../../../assets/clashking/icons/app_icon_ios_default.png');
}

async function openExternal(url: string): Promise<boolean> {
  try {
    await Linking.openURL(url);
    return true;
  } catch {
    // Flutter treats settings handoffs as best effort except where the screen
    // provides a dedicated fallback itself.
    return false;
  }
}

async function savePrivacyExport(fileName: string, data: string): Promise<void> {
  if (Platform.OS === 'web') {
    const url = URL.createObjectURL(new Blob([data], { type: 'application/json' }));
    const link = document.createElement('a');
    link.href = url;
    link.download = fileName;
    link.click();
    URL.revokeObjectURL(url);
    return;
  }
  const file = new File(Paths.cache, fileName);
  file.create({ overwrite: true, intermediates: true });
  file.write(data);
  if (!(await Sharing.isAvailableAsync())) throw new Error('Sharing is unavailable.');
  await Sharing.shareAsync(file.uri, { mimeType: 'application/json', dialogTitle: fileName });
}
