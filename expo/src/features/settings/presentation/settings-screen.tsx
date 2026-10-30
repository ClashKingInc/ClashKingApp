import { useAdaptiveLayout } from '../../../ui/adaptive-layout';
import { modalOrientations } from '../../../ui/modal-orientations';
import { useState } from 'react';
import {
  Image,
  Modal,
  Platform,
  Pressable,
  StyleSheet,
  View,
  useWindowDimensions,
  type ImageSourcePropType,
} from 'react-native';
import {
  AtSign,
  BellRing,
  FileText,
  Gamepad2,
  Info,
  ImageIcon,
  Languages,
  LogOut,
  MessageSquareText,
  SunMoon,
  Shield,
  Languages as TranslateIcon,
  UserRound,
} from 'lucide-react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { useI18n, toIntlLocale } from '../../../i18n';
import { CKText, MobileWebImage, Surface, ckRadius, ckSpacing, useCKTheme } from '../../../ui';
import type { SettingsPresentationActions, SettingsThemeMode, SettingsUser } from './contracts';
import {
  SettingsPage,
  SettingsSection,
  SettingsTile,
  SettingsChoiceTile,
  SettingsColumns,
} from './settings-components';
import { SelectionPickerModal } from '../../../ui/selection-picker';

export type SettingsAppIconChoice = {
  iconName: string;
  label: string;
  previewSource: ImageSourcePropType;
};
export type SettingsLocaleChoice = { locale: string; label: string; flagUrl: string };

export function isDesktopSettings(platform: string, width: number): boolean {
  return platform === 'web' && width >= 900;
}

export function SettingsScreen({
  user,
  currentLocale,
  localeChoices,
  themeMode,
  systemLanguage = false,
  notificationsEnabled,
  alternateIconsSupported,
  selectedAppIcon = '',
  appIcons = [],
  imageCacheBytes = 0,
  versionLabel,
  actions,
  onBack,
  viewportWidth,
  platform = Platform.OS,
}: {
  user: SettingsUser;
  currentLocale: string;
  localeChoices: readonly SettingsLocaleChoice[];
  themeMode: SettingsThemeMode;
  systemLanguage?: boolean;
  notificationsEnabled: boolean;
  alternateIconsSupported: boolean;
  selectedAppIcon?: string;
  appIcons?: readonly SettingsAppIconChoice[];
  imageCacheBytes?: number;
  versionLabel: string;
  actions: SettingsPresentationActions;
  onBack?: () => void;
  viewportWidth?: number;
  platform?: string;
}) {
  const { t, isRtl } = useI18n();
  const theme = useCKTheme();
  const layout = useAdaptiveLayout();
  const insets = useSafeAreaInsets();
  const measured = useWindowDimensions().width;
  const desktop = isDesktopSettings(platform, viewportWidth ?? measured);
  const [dialog, setDialog] = useState<'language' | 'icon' | 'logout'>();
  const [busy, setBusy] = useState(false);
  const [snackbar, setSnackbar] = useState<string>();
  const iconColor = theme.onSurface;
  const selectedLocale = systemLanguage
    ? 'system'
    : (localeChoices.find(({ locale }) => locale === currentLocale)?.locale ??
      localeChoices.find(({ locale }) => locale.split('_', 1)[0] === currentLocale.split('_', 1)[0])
        ?.locale ??
      currentLocale);
  const versionAvailable =
    versionLabel !== t('generalLoading') && versionLabel !== t('errorLoadingVersion');
  const body = (
    <View style={[styles.body, desktop && styles.desktop]}>
      <View style={styles.profile}>
        <View style={[styles.avatar, { backgroundColor: theme.surfaceContainerHighest }]}>
          {user.avatarUrl ? (
            <MobileWebImage
              imageUrl={user.avatarUrl}
              contentFit="cover"
              errorFallback={<UserRound color={theme.onSurfaceVariant} size={30} />}
              style={styles.avatar}
            />
          ) : (
            <UserRound color={theme.onSurfaceVariant} size={30} />
          )}
        </View>
        <CKText role="titleLarge" numberOfLines={1} style={styles.strong}>
          {user.username}
        </CKText>
      </View>
      <SettingsColumns>
        <>
          <SettingsSection title={t('settingsPreferences')}>
            <SettingsTile
              icon={<Languages color={iconColor} />}
              title={t('settingsLanguage')}
              subtitle={t('settingsSelectLanguage')}
              onPress={() => setDialog('language')}
            />
            <SettingsChoiceTile<SettingsThemeMode>
              icon={<SunMoon color={iconColor} />}
              title={t('settingsToggleTheme')}
              value={themeMode}
              options={[
                { value: 'light', label: t('settingsThemeLight') },
                { value: 'dark', label: t('settingsThemeDark') },
                { value: 'system', label: t('settingsThemeSystem') },
              ]}
              isRtl={isRtl}
              onChange={(mode) =>
                void actions
                  .changeTheme(mode)
                  .catch((error: unknown) =>
                    setSnackbar(error instanceof Error ? error.message : String(error)),
                  )
              }
            />
            {alternateIconsSupported ? (
              <SettingsTile
                icon={<ImageIcon color={iconColor} />}
                title={t('settingsAppIcon')}
                trailing={
                  busy
                    ? t('settingsChanging')
                    : (appIcons.find((item) => item.iconName === selectedAppIcon)?.label ??
                      t('settingsAppIcon'))
                }
                disabled={busy}
                onPress={() => setDialog('icon')}
              />
            ) : null}
            {platform !== 'web' && notificationsEnabled ? (
              <SettingsTile
                icon={<BellRing color={iconColor} />}
                title={t('settingsNotificationsTitle')}
                subtitle={t('settingsNotificationsSubtitle')}
                onPress={() => actions.open('notifications')}
              />
            ) : null}
          </SettingsSection>
          <SettingsSection title={t('settingsSupport')}>
            <SettingsTile
              icon={<MessageSquareText color={iconColor} />}
              title={t('faqTitle')}
              subtitle={t('faqSubtitle')}
              onPress={() => actions.open('faq')}
            />
            <SettingsTile
              icon={<TranslateIcon color={iconColor} />}
              title={t('translationHelpUsTranslate')}
              onPress={() => actions.open('translation')}
            />
            <SettingsTile
              icon={<Gamepad2 color={iconColor} />}
              title={t('faqJoinDiscord')}
              onPress={actions.openDiscord}
            />
          </SettingsSection>
        </>
        <>
          <SettingsSection title={t('settingsAbout')}>
            <SettingsTile
              icon={<FileText color={iconColor} />}
              title={t('settingsLicenses')}
              subtitle={t('settingsLicensesSubtitle')}
              onPress={actions.showLicenses}
            />
            <SettingsTile
              icon={<Shield color={iconColor} />}
              title={t('settingsPrivacyPolicy')}
              subtitle={t('settingsPrivacyPolicySubtitle')}
              onPress={() => actions.open('privacy')}
            />
            <SettingsTile
              icon={<Info color={iconColor} />}
              title={t('versionDevice')}
              subtitle={versionLabel}
              showChevron={false}
              onPress={
                versionAvailable
                  ? () => {
                      actions.copyVersion(versionLabel);
                      setSnackbar(t('generalCopiedToClipboard'));
                    }
                  : undefined
              }
            />
            {actions.clearImageCache ? (
              <SettingsTile
                icon={<ImageIcon color={iconColor} />}
                title={t('settingsClearImageCache')}
                trailing={`${new Intl.NumberFormat(toIntlLocale(currentLocale), { maximumFractionDigits: 1 }).format(imageCacheBytes / (1024 * 1024))} MB`}
                disabled={busy}
                onPress={() => {
                  setBusy(true);
                  void actions.clearImageCache!()
                    .then(() => setSnackbar(t('settingsImageCacheCleared')))
                    .catch(() => setSnackbar(t('settingsImageCacheClearFailed')))
                    .finally(() => setBusy(false));
                }}
              />
            ) : null}
          </SettingsSection>
          <SettingsSection title={t('settingsAccount')}>
            <SettingsTile
              icon={<AtSign color={iconColor} />}
              title={user.email ?? user.username}
              subtitle={user.email ? t('authEmail') : t('settingsSignedIn')}
              showChevron={false}
            />
            <SettingsTile
              icon={<LogOut color={theme.error} />}
              title={t('authLogout')}
              destructive
              onPress={() => setDialog('logout')}
            />
          </SettingsSection>
        </>
      </SettingsColumns>
    </View>
  );
  return (
    <>
      <SettingsPage title={t('generalSettings')} onBack={onBack} wide>
        {body}
      </SettingsPage>
      <SelectionPickerModal
        visible={dialog === 'language'}
        title={t('settingsLanguage')}
        options={[
          {
            key: 'system',
            label: t('settingsThemeSystem'),
            icon: <Languages color={theme.onSurfaceVariant} size={20} />,
          },
          ...localeChoices.map(({ locale, label, flagUrl }) => ({
            key: locale,
            label,
            icon: (
              <MobileWebImage
                imageUrl={flagUrl}
                contentFit="cover"
                errorFallback={<Languages color={theme.onSurfaceVariant} size={20} />}
                style={styles.flag}
              />
            ),
          })),
        ]}
        selectedKey={selectedLocale}
        onSelect={(locale) => {
          setDialog(undefined);
          void actions
            .changeLocale(locale)
            .catch((error: unknown) =>
              setSnackbar(error instanceof Error ? error.message : String(error)),
            );
        }}
        onClose={() => setDialog(undefined)}
      />
      <SelectionPickerModal
        visible={dialog === 'icon'}
        title={t('settingsAppIcon')}
        options={appIcons.map((choice) => ({
          key: choice.iconName,
          label: choice.label,
          icon: <Image source={choice.previewSource} style={styles.appIconPreview} />,
        }))}
        selectedKey={selectedAppIcon}
        onSelect={(iconName) => {
          setDialog(undefined);
          if (iconName === selectedAppIcon) return;
          setBusy(true);
          void actions
            .changeAppIcon?.(iconName || null)
            .catch((error: unknown) =>
              setSnackbar(error instanceof Error ? error.message : String(error)),
            )
            .finally(() => setBusy(false));
        }}
        onClose={() => setDialog(undefined)}
      />
      <ConfirmLogout
        visible={dialog === 'logout'}
        onCancel={() => setDialog(undefined)}
        onConfirm={() => {
          setDialog(undefined);
          void actions.logout();
        }}
        title={t('generalWarning')}
        body={t('authConfirmLogout')}
        cancel={t('generalCancel')}
        confirm={t('generalOk')}
      />
      {snackbar ? (
        <Pressable
          accessibilityLiveRegion="polite"
          onPress={() => setSnackbar(undefined)}
          style={[
            styles.snackbar,
            { backgroundColor: theme.surfaceContainerHighest },
            (layout.isDuo || layout.isTablet) && {
              left: insets.left + 16,
              right: insets.right + 16,
              bottom: insets.bottom + 16,
            },
          ]}
        >
          <CKText style={{ color: theme.onSurface }}>{snackbar}</CKText>
        </Pressable>
      ) : null}
    </>
  );
}

function ConfirmLogout({
  visible,
  title,
  body,
  cancel,
  confirm,
  onCancel,
  onConfirm,
}: {
  visible: boolean;
  title: string;
  body: string;
  cancel: string;
  confirm: string;
  onCancel: () => void;
  onConfirm: () => void;
}) {
  const theme = useCKTheme();
  return (
    <Modal
      supportedOrientations={modalOrientations}
      visible={visible}
      transparent
      animationType="fade"
      onRequestClose={onCancel}
    >
      <View style={styles.modal}>
        <Surface style={styles.confirm}>
          <CKText role="titleLarge">{title}</CKText>
          <CKText>{body}</CKText>
          <View style={styles.actions}>
            <Pressable accessibilityRole="button" onPress={onCancel} style={styles.dialogAction}>
              <CKText role="bodyMedium">{cancel}</CKText>
            </Pressable>
            <Pressable accessibilityRole="button" onPress={onConfirm} style={styles.dialogAction}>
              <CKText role="bodyMedium" style={{ color: theme.primary }}>
                {confirm}
              </CKText>
            </Pressable>
          </View>
        </Surface>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  body: { width: '100%' },
  desktop: { maxWidth: 760, alignSelf: 'center' },
  profile: { alignItems: 'center', gap: 8, marginBottom: 14 },
  avatar: {
    width: 68,
    height: 68,
    borderRadius: 34,
    alignItems: 'center',
    justifyContent: 'center',
  },
  strong: { fontWeight: '700' },
  pressed: { opacity: 0.72 },
  flag: { width: 34, height: 34, borderRadius: 17 },
  choiceIcon: {
    width: 34,
    height: 34,
    borderRadius: ckRadius.control,
    alignItems: 'center',
    justifyContent: 'center',
  },
  appIconPreview: { width: 36, height: 36, borderRadius: 9 },
  snackbar: {
    position: 'absolute',
    left: 16,
    right: 16,
    bottom: 16,
    minHeight: 48,
    borderRadius: 4,
    paddingHorizontal: 16,
    paddingVertical: 12,
    justifyContent: 'center',
    zIndex: 100,
  },
  modal: { flex: 1, justifyContent: 'center', backgroundColor: '#00000066', padding: 24 },
  confirm: {
    padding: ckSpacing.lg,
    gap: ckSpacing.lg,
    maxWidth: 520,
    width: '100%',
    alignSelf: 'center',
  },
  actions: { flexDirection: 'row', justifyContent: 'flex-end' },
  dialogAction: {
    minWidth: 64,
    minHeight: 44,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 8,
  },
});
