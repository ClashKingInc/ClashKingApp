import { useState } from 'react';
import {
  Image,
  Modal,
  Platform,
  Pressable,
  ScrollView,
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
  Moon,
  Plus,
  PanelsTopLeft,
  SunMoon,
  Shield,
  Sun,
  Languages as TranslateIcon,
  UserRound,
} from 'lucide-react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { useI18n } from '../../../i18n';
import {
  CKText,
  MobileWebImage,
  Skeleton,
  Surface,
  ckRadius,
  ckSpacing,
  colorWithAlpha,
  useCKTheme,
} from '../../../ui';
import type { SettingsPresentationActions, SettingsThemeMode, SettingsUser } from './contracts';
import { ChoiceDialog, SettingsPage, SettingsSection, SettingsTile } from './settings-components';

export type SettingsAppIconChoice = {
  iconName: string;
  label: string;
  previewSource: ImageSourcePropType;
};
export type WarWidgetClanChoice = { tag: string; name: string; badgeUrl?: string | null };
export type SettingsLocaleChoice = { locale: string; label: string; flagUrl: string };

export function isDesktopSettings(platform: string, width: number): boolean {
  return platform === 'web' && width >= 900;
}

export function SettingsScreen({
  user,
  currentLocale,
  localeChoices,
  themeMode,
  notificationsEnabled,
  warWidgetsEnabled,
  alternateIconsSupported,
  selectedAppIcon = '',
  appIcons = [],
  warWidgetClans = [],
  versionLabel,
  actions,
  onPrepareWarWidget,
  onBack,
  viewportWidth,
  platform = Platform.OS,
}: {
  user: SettingsUser;
  currentLocale: string;
  localeChoices: readonly SettingsLocaleChoice[];
  themeMode: SettingsThemeMode;
  notificationsEnabled: boolean;
  warWidgetsEnabled: boolean;
  alternateIconsSupported: boolean;
  selectedAppIcon?: string;
  appIcons?: readonly SettingsAppIconChoice[];
  warWidgetClans?: readonly WarWidgetClanChoice[];
  versionLabel: string;
  actions: SettingsPresentationActions;
  onPrepareWarWidget?: (clanTag: string, requestPin: boolean) => Promise<void>;
  onBack?: () => void;
  viewportWidth?: number;
  platform?: string;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const measured = useWindowDimensions().width;
  const desktop = isDesktopSettings(platform, viewportWidth ?? measured);
  const [dialog, setDialog] = useState<'language' | 'theme' | 'icon' | 'logout' | 'widget'>();
  const [busy, setBusy] = useState(false);
  const [snackbar, setSnackbar] = useState<string>();
  const iconColor = theme.onSurface;
  const themeLabel =
    themeMode === 'system'
      ? t('settingsThemeSystem')
      : themeMode === 'light'
        ? t('settingsThemeLight')
        : t('settingsThemeDark');
  const selectedLocale =
    localeChoices.find(({ locale }) => locale === currentLocale)?.locale ??
    localeChoices.find(({ locale }) => locale.split('_', 1)[0] === currentLocale.split('_', 1)[0])
      ?.locale ??
    currentLocale;
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
      <SettingsSection title={t('settingsPreferences')}>
        <SettingsTile
          icon={<Languages color={iconColor} />}
          title={t('settingsLanguage')}
          subtitle={t('settingsSelectLanguage')}
          onPress={() => setDialog('language')}
        />
        <SettingsTile
          icon={<SunMoon color={iconColor} />}
          title={t('settingsToggleTheme')}
          trailing={themeLabel}
          onPress={() => setDialog('theme')}
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
        {notificationsEnabled ? (
          <SettingsTile
            icon={<BellRing color={iconColor} />}
            title={t('settingsNotificationsTitle')}
            subtitle={t('settingsNotificationsSubtitle')}
            onPress={() => actions.open('notifications')}
          />
        ) : null}
        {warWidgetsEnabled ? (
          <SettingsTile
            icon={<PanelsTopLeft color={iconColor} />}
            title={t('settingsAddWarWidget')}
            subtitle={
              warWidgetClans.length === 0
                ? t('settingsWarWidgetLinkClanFirst')
                : t('settingsWarWidgetClanCount', { count: warWidgetClans.length })
            }
            onPress={() => setDialog('widget')}
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
    </View>
  );
  return (
    <>
      <SettingsPage title={t('generalSettings')} onBack={onBack}>
        {body}
      </SettingsPage>
      <ChoiceDialog
        visible={dialog === 'language'}
        title={t('settingsLanguage')}
        subtitle={t('settingsSelectLanguage')}
        heightFactor={0.82}
        choices={localeChoices.map(({ locale, label, flagUrl }) => ({
          value: locale,
          label,
          icon: (
            <MobileWebImage
              imageUrl={flagUrl}
              contentFit="cover"
              errorFallback={<Languages color={theme.onSurfaceVariant} size={20} />}
              style={styles.flag}
            />
          ),
        }))}
        selected={selectedLocale}
        onSelect={(locale) => void actions.changeLocale(locale)}
        onClose={() => setDialog(undefined)}
      />
      <ChoiceDialog
        visible={dialog === 'theme'}
        title={t('settingsAppearance')}
        choices={[
          {
            value: 'system',
            label: t('settingsThemeSystem'),
            subtitle: t('settingsThemeMatchDevice'),
            icon: (
              <ChoiceIcon selected={themeMode === 'system'}>
                <SunMoon
                  color={themeMode === 'system' ? theme.primary : theme.onSurfaceVariant}
                  size={21}
                />
              </ChoiceIcon>
            ),
          },
          {
            value: 'light',
            label: t('settingsThemeLight'),
            icon: (
              <ChoiceIcon selected={themeMode === 'light'}>
                <Sun
                  color={themeMode === 'light' ? theme.primary : theme.onSurfaceVariant}
                  size={21}
                />
              </ChoiceIcon>
            ),
          },
          {
            value: 'dark',
            label: t('settingsThemeDark'),
            icon: (
              <ChoiceIcon selected={themeMode === 'dark'}>
                <Moon
                  color={themeMode === 'dark' ? theme.primary : theme.onSurfaceVariant}
                  size={21}
                />
              </ChoiceIcon>
            ),
          },
        ]}
        selected={themeMode}
        onSelect={(mode) => void actions.changeTheme(mode)}
        onClose={() => setDialog(undefined)}
      />
      <AppIconDialog
        visible={dialog === 'icon'}
        title={t('settingsAppIcon')}
        choices={appIcons}
        selected={selectedAppIcon}
        selectedLabel={t('settingsThemeSelected')}
        onSelect={(iconName) => {
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
      <WarWidgetDialog
        visible={dialog === 'widget'}
        title={t('settingsAddWarWidget')}
        subtitle={
          platform === 'ios'
            ? 'Choose a clan to cache it. After adding the widget, long press it, tap Edit Widget, then choose Clan.'
            : 'Choose a clan to cache it, then add the widget from Android.'
        }
        emptyLabel="No linked accounts are currently in a clan."
        footer={
          platform === 'ios'
            ? 'You can add more than one War Widget and set a different Clan on each one.'
            : undefined
        }
        choices={warWidgetClans}
        onPrepare={async (clan) => {
          await onPrepareWarWidget?.(clan.tag, platform === 'android');
          setSnackbar(
            platform === 'ios'
              ? `${clan.name} is ready. Edit the widget and choose it under Clan.`
              : `${clan.name} widget data is ready.`,
          );
        }}
        onError={(error) => setSnackbar(`Could not prepare widget: ${String(error)}`)}
        onClose={() => setDialog(undefined)}
      />
      {snackbar ? (
        <Pressable
          accessibilityLiveRegion="polite"
          onPress={() => setSnackbar(undefined)}
          style={[styles.snackbar, { backgroundColor: theme.surfaceContainerHighest }]}
        >
          <CKText style={{ color: theme.onSurface }}>{snackbar}</CKText>
        </Pressable>
      ) : null}
    </>
  );
}

function ChoiceIcon({ selected, children }: { selected: boolean; children: React.ReactNode }) {
  const theme = useCKTheme();
  const color = selected ? theme.primary : theme.onSurfaceVariant;
  return (
    <View
      style={[
        styles.choiceIcon,
        { backgroundColor: colorWithAlpha(color, selected ? 0.12 : 0.08) },
      ]}
    >
      {children}
    </View>
  );
}

function AppIconDialog({
  visible,
  title,
  choices,
  selected,
  selectedLabel,
  onSelect,
  onClose,
}: {
  visible: boolean;
  title: string;
  choices: readonly SettingsAppIconChoice[];
  selected: string;
  selectedLabel: string;
  onSelect: (iconName: string) => void;
  onClose: () => void;
}) {
  const theme = useCKTheme();
  return (
    <Modal transparent animationType="slide" visible={visible} onRequestClose={onClose}>
      <SafeAreaView style={styles.sheetOverlay}>
        <Pressable
          accessibilityElementsHidden
          importantForAccessibility="no-hide-descendants"
          onPress={onClose}
          style={StyleSheet.absoluteFill}
        />
        <Surface radius={ckRadius.card} style={styles.bottomSheet} accessibilityViewIsModal>
          <View style={[styles.dragHandle, { backgroundColor: theme.onSurfaceVariant }]} />
          <View style={styles.appIconSheetBody}>
            <SettingsSection title={title}>
              {choices.map((choice) => (
                <Pressable
                  accessibilityRole="radio"
                  accessibilityState={{ checked: selected === choice.iconName }}
                  key={choice.iconName || 'default'}
                  onPress={() => {
                    onClose();
                    onSelect(choice.iconName);
                  }}
                  style={({ pressed }) => [styles.appIconRow, pressed && styles.pressed]}
                >
                  <Image source={choice.previewSource} style={styles.appIconPreview} />
                  <CKText numberOfLines={1} role="bodyLarge" style={styles.appIconLabel}>
                    {choice.label}
                  </CKText>
                  {selected === choice.iconName ? (
                    <CKText muted role="bodyMedium" style={styles.appIconSelected}>
                      {selectedLabel}
                    </CKText>
                  ) : null}
                </Pressable>
              ))}
            </SettingsSection>
          </View>
        </Surface>
      </SafeAreaView>
    </Modal>
  );
}

function WarWidgetDialog({
  visible,
  title,
  subtitle,
  emptyLabel,
  footer,
  choices,
  onPrepare,
  onError,
  onClose,
}: {
  visible: boolean;
  title: string;
  subtitle: string;
  emptyLabel: string;
  footer?: string;
  choices: readonly WarWidgetClanChoice[];
  onPrepare: (clan: WarWidgetClanChoice) => Promise<void>;
  onError: (error: unknown) => void;
  onClose: () => void;
}) {
  const theme = useCKTheme();
  const [pendingTag, setPendingTag] = useState<string>();
  const prepare = async (clan: WarWidgetClanChoice) => {
    setPendingTag(clan.tag);
    try {
      await onPrepare(clan);
      onClose();
    } catch (error) {
      onError(error);
    } finally {
      setPendingTag(undefined);
    }
  };
  return (
    <Modal transparent animationType="slide" visible={visible} onRequestClose={onClose}>
      <SafeAreaView style={styles.sheetOverlay}>
        <Pressable
          accessibilityElementsHidden
          importantForAccessibility="no-hide-descendants"
          onPress={onClose}
          style={StyleSheet.absoluteFill}
        />
        <Surface radius={ckRadius.card} style={styles.bottomSheet} accessibilityViewIsModal>
          <View style={[styles.dragHandle, { backgroundColor: theme.onSurfaceVariant }]} />
          <View style={styles.widgetSheetBody}>
            <CKText role="titleLarge" style={styles.widgetTitle}>
              {title}
            </CKText>
            <CKText muted>{subtitle}</CKText>
            {choices.length === 0 ? (
              <CKText muted style={styles.widgetEmpty}>
                {emptyLabel}
              </CKText>
            ) : (
              <ScrollView style={styles.widgetList}>
                {choices.map((clan, index) => {
                  const pending = pendingTag === clan.tag;
                  return (
                    <View key={clan.tag}>
                      <Pressable
                        accessibilityRole="button"
                        disabled={pending}
                        onPress={() => void prepare(clan)}
                        style={({ pressed }) => [styles.widgetRow, pressed && styles.pressed]}
                      >
                        {clan.badgeUrl ? (
                          <MobileWebImage
                            imageUrl={clan.badgeUrl}
                            contentFit="contain"
                            errorFallback={
                              <View
                                style={[
                                  styles.widgetBadgeFallback,
                                  { backgroundColor: colorWithAlpha(theme.primary, 0.12) },
                                ]}
                              >
                                <CKText style={{ color: theme.primary }}>
                                  {clan.name[0] ?? '?'}
                                </CKText>
                              </View>
                            }
                            style={styles.widgetBadge}
                          />
                        ) : (
                          <View
                            style={[
                              styles.widgetBadgeFallback,
                              { backgroundColor: colorWithAlpha(theme.primary, 0.12) },
                            ]}
                          >
                            <CKText style={{ color: theme.primary }}>{clan.name[0] ?? '?'}</CKText>
                          </View>
                        )}
                        <View style={styles.widgetCopy}>
                          <CKText numberOfLines={1}>{clan.name}</CKText>
                          <CKText muted role="bodySmall">
                            {clan.tag}
                          </CKText>
                        </View>
                        {pending ? (
                          <Skeleton width={18} height={6} />
                        ) : (
                          <Plus color={theme.onSurface} />
                        )}
                      </Pressable>
                      {index < choices.length - 1 ? (
                        <View
                          style={[styles.widgetDivider, { backgroundColor: theme.outlineVariant }]}
                        />
                      ) : null}
                    </View>
                  );
                })}
              </ScrollView>
            )}
            {footer ? (
              <CKText muted role="bodySmall" style={styles.widgetFooter}>
                {footer}
              </CKText>
            ) : null}
          </View>
        </Surface>
      </SafeAreaView>
    </Modal>
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
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onCancel}>
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
  sheetOverlay: { flex: 1, justifyContent: 'flex-end', backgroundColor: '#00000066' },
  bottomSheet: {
    maxHeight: '82%',
    borderBottomLeftRadius: 0,
    borderBottomRightRadius: 0,
  },
  dragHandle: {
    width: 32,
    height: 4,
    borderRadius: 2,
    opacity: 0.4,
    alignSelf: 'center',
    marginTop: 8,
  },
  appIconSheetBody: { paddingHorizontal: 16, paddingTop: 8, paddingBottom: 6 },
  appIconRow: {
    height: 62,
    paddingHorizontal: 14,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  appIconPreview: { width: 36, height: 36, borderRadius: 9 },
  appIconLabel: { flex: 1, fontWeight: '500', fontSize: 17 },
  appIconSelected: { fontSize: 16 },
  widgetSheetBody: { paddingHorizontal: 16, paddingTop: 8, paddingBottom: 20 },
  widgetTitle: { fontWeight: '700', marginBottom: 6 },
  widgetEmpty: { paddingVertical: 20 },
  widgetList: { marginTop: 14, flexShrink: 1 },
  widgetRow: {
    minHeight: 58,
    paddingHorizontal: 2,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  widgetBadge: { width: 42, height: 42, resizeMode: 'contain' },
  widgetBadgeFallback: {
    width: 42,
    height: 42,
    borderRadius: 21,
    alignItems: 'center',
    justifyContent: 'center',
  },
  widgetCopy: { flex: 1 },
  widgetDivider: { height: StyleSheet.hairlineWidth, opacity: 0.32 },
  widgetFooter: { marginTop: 12 },
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
