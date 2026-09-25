import { useCallback, useEffect, useRef, useState, type ReactNode } from 'react';
import {
  AppState,
  Modal,
  Pressable,
  ScrollView,
  StyleSheet,
  View,
  type NativeScrollEvent,
  type NativeSyntheticEvent,
} from 'react-native';
import {
  AlarmClock,
  Bell,
  CalendarDays,
  Castle,
  ChevronDown,
  ChevronUp,
  HeartHandshake,
  Megaphone,
  Plus,
  Shield,
  Users,
  Trash2,
} from 'lucide-react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import {
  createDefaultNotificationPreferences,
  withNotificationCategory,
  type NotificationCategory,
  type NotificationPreferences,
} from '../../../core/dto/notification-preferences';
import { useI18n, type I18nValue, type MessageKey } from '../../../i18n';
import {
  CKText,
  LoadingIndicator,
  Skeleton,
  SelectionPicker,
  Surface,
  ckRadius,
  ckSpacing,
  colorWithAlpha,
  useCKTheme,
} from '../../../ui';
import type { PushNotificationSetupResult } from '../../notifications/push/contracts';
import type { NotificationSettingsPresentationService } from './contracts';
import { SettingSwitch, SettingsPage, SettingsSection, SettingsTile } from './settings-components';

const categoryRows: readonly {
  category: NotificationCategory;
  title: MessageKey;
  description: MessageKey;
  icon: (color: string) => ReactNode;
}[] = [
  {
    category: 'events',
    title: 'notifGroupEvents',
    description: 'notifEventsDescription',
    icon: (color) => <CalendarDays color={color} size={22} />,
  },
  {
    category: 'announcements',
    title: 'notifGroupAppAnnouncements',
    description: 'notifAnnouncementsDescription',
    icon: (color) => <Megaphone color={color} size={22} />,
  },
  {
    category: 'legendDefenses',
    title: 'notifGroupLegendDefenses',
    description: 'notifLegendDefensesDescription',
    icon: (color) => <Shield color={color} size={22} />,
  },
  {
    category: 'monthlySupport',
    title: 'notifGroupMonthlySupport',
    description: 'notifSupportReminderDescription',
    icon: (color) => <HeartHandshake color={color} size={22} />,
  },
];

export function NotificationSettingsScreen({
  service,
  debugEnabled = false,
  onManagePlayers,
  onBack,
}: {
  service: NotificationSettingsPresentationService;
  debugEnabled?: boolean;
  onManagePlayers?: () => void;
  onBack?: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [settings, setSettings] = useState<NotificationPreferences>();
  const [push, setPush] = useState<PushNotificationSetupResult | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [configuringPush, setConfiguringPush] = useState(false);
  const [sendingSample, setSendingSample] = useState(false);
  const [sampleId, setSampleId] = useState(service.testNotificationTypes?.[0]?.id ?? '');
  const [snackbar, setSnackbar] = useState<string>();
  const savingRef = useRef(false);
  const configuringRef = useRef(false);

  const initialize = useCallback(async () => {
    let local: NotificationPreferences;
    try {
      local = await service.loadLocal();
    } catch {
      local = createDefaultNotificationPreferences();
    }
    setSettings(local);
    try {
      local = await service.load();
      setSettings(local);
    } catch {
      // The local V2 snapshot is the offline fallback, matching Flutter.
    }
    try {
      setPush(await service.initializePush());
    } catch {
      setPush({ state: 'notConfigured' });
    } finally {
      setLoading(false);
    }
  }, [service]);

  useEffect(() => {
    // Mounting this route is the external event that starts preference hydration.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    void initialize();
  }, [initialize]);

  useEffect(() => {
    const subscription = AppState.addEventListener('change', (state) => {
      if (state === 'active' && !savingRef.current) void initialize();
    });
    return () => subscription.remove();
  }, [initialize]);

  const save = async (next: NotificationPreferences, rollback = settings) => {
    if (savingRef.current || !rollback) return;
    savingRef.current = true;
    setSettings(next);
    setSaving(true);
    try {
      setSettings(await service.save(next));
    } catch {
      setSettings(rollback);
      setSnackbar(t('notifSettingsSaveFailed'));
    } finally {
      savingRef.current = false;
      setSaving(false);
    }
  };

  if (loading || !settings)
    return (
      <SettingsPage title={t('settingsNotificationsTitle')} onBack={onBack}>
        <View accessibilityLabel={t('generalLoading')} style={styles.loadingSkeletons}>
          {Array.from({ length: 4 }, (_, index) => (
            <Skeleton key={index} height={88} radius={18} />
          ))}
        </View>
      </SettingsPage>
    );

  const openSystemSettings = async () => {
    if (savingRef.current || configuringRef.current) return;
    configuringRef.current = true;
    setConfiguringPush(true);
    try {
      if (push?.state === 'permissionRequired') {
        const result = await service.enablePush();
        setPush(result);
        if (result.state !== 'ready') setSnackbar(pushFallback(t, result));
      } else {
        await service.openSystemSettings();
      }
    } catch {
      setSnackbar(t('notifSystemSettingsFailed'));
    } finally {
      configuringRef.current = false;
      setConfiguringPush(false);
    }
  };

  const sendSample = async () => {
    if (!service.sendTestNotification || sendingSample) return;
    setSendingSample(true);
    try {
      const title = await service.sendTestNotification(sampleId);
      setSnackbar(t('notifScheduledMessage', { title }));
    } catch (error) {
      setSnackbar(String(error));
    } finally {
      setSendingSample(false);
    }
  };

  const busy = saving || configuringPush;
  return (
    <View style={styles.screen}>
      <SettingsPage title={t('settingsNotificationsTitle')} onBack={onBack}>
        <SettingsSection title={t('notifSystemNotifications')}>
          <SettingsTile
            icon={<Bell color={theme.onSurface} size={22} />}
            title={
              push?.state === 'permissionRequired'
                ? t('notifReceiveNotifications')
                : t('notifSystemSettings')
            }
            subtitle={t('notifSystemSettingsDescription')}
            subtitleNumberOfLines={3}
            disabled={busy}
            onPress={() => void openSystemSettings()}
          />
        </SettingsSection>
        <>
          <SettingsSection title={t('playersLinked')}>
            <SettingsTile
              icon={<Users color={theme.onSurface} size={22} />}
              title={t('searchTabPlayers')}
              subtitle={t('notifManagePlayersDescription')}
              subtitleNumberOfLines={3}
              onPress={onManagePlayers}
            />
          </SettingsSection>
          <SettingsSection title={t('notifChooseAlerts')}>
            {categoryRows.map((row) => (
              <ToggleRow
                key={row.category}
                icon={row.icon(theme.onSurface)}
                title={t(row.title)}
                description={t(row.description)}
                value={settings[row.category]}
                disabled={busy}
                onChange={(value) =>
                  void save(withNotificationCategory(settings, row.category, value))
                }
              />
            ))}
          </SettingsSection>
          <SettingsSection title={t('notifCustomReminders')}>
            <ReminderRow
              icon={<AlarmClock color={theme.onSurface} size={22} />}
              title={t('notifGroupWarReminders')}
              description={t('notifWarRemindersDescription')}
              enabled={settings.warReminders}
              disabled={busy}
              values={settings.reminderTimings}
              maxHours={47}
              onToggle={(value) =>
                void save(withNotificationCategory(settings, 'warReminders', value))
              }
              onValues={(values) => void save({ ...settings, reminderTimings: values })}
            />
            <ReminderRow
              icon={<Castle color={theme.onSurface} size={22} />}
              title={t('notifGroupRaidReminders')}
              description={t('notifRaidRemindersDescription')}
              enabled={settings.raidReminders}
              disabled={busy}
              values={settings.raidReminderTimings}
              maxHours={72}
              onToggle={(value) =>
                void save(withNotificationCategory(settings, 'raidReminders', value))
              }
              onValues={(values) => void save({ ...settings, raidReminderTimings: values })}
            />
          </SettingsSection>
        </>
        {debugEnabled && service.sendTestNotification ? (
          <SettingsSection title={t('notifTestNotification')}>
            <View style={styles.debugWrap}>
              <SelectionPicker
                options={(service.testNotificationTypes ?? []).map(({ id, labelKey }) => ({
                  key: id,
                  label: t(labelKey),
                }))}
                selectedKey={sampleId}
                onSelect={setSampleId}
                title={t('notifTestType')}
                accessibilityLabel={t('notifTestType')}
                fillWidth
              />
              <Pressable
                accessibilityRole="button"
                disabled={sendingSample || !sampleId}
                onPress={() => void sendSample()}
                style={[styles.debug, { backgroundColor: colorWithAlpha(theme.primary, 0.14) }]}
              >
                {sendingSample ? <LoadingIndicator /> : <Bell color={theme.primary} size={20} />}
                <CKText role="rowTitle">{t('notifSendTestNotification')}</CKText>
              </Pressable>
            </View>
          </SettingsSection>
        ) : null}
      </SettingsPage>
      <SettingsSnackbar message={snackbar} onDismiss={() => setSnackbar(undefined)} />
    </View>
  );
}

function ToggleRow({
  icon,
  title,
  description,
  value,
  disabled,
  onChange,
}: {
  icon: ReactNode;
  title: string;
  description: string;
  value: boolean;
  disabled?: boolean;
  onChange: (value: boolean) => void;
}) {
  return (
    <View style={styles.row}>
      <View style={styles.icon}>{icon}</View>
      <View style={styles.copy}>
        <CKText role="bodyLarge" style={styles.semi}>
          {title}
        </CKText>
        <CKText muted role="bodySmall">
          {description}
        </CKText>
      </View>
      <SettingSwitch value={value} disabled={disabled} onChange={onChange} />
    </View>
  );
}

function ReminderRow({
  icon,
  title,
  description,
  enabled,
  disabled,
  values,
  maxHours,
  onToggle,
  onValues,
}: {
  icon: ReactNode;
  title: string;
  description: string;
  enabled: boolean;
  disabled?: boolean;
  values: readonly number[];
  maxHours: number;
  onToggle: (value: boolean) => void;
  onValues: (values: readonly number[]) => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [expanded, setExpanded] = useState(false);
  const [picker, setPicker] = useState(false);
  return (
    <View>
      <Pressable
        accessibilityRole="button"
        accessibilityState={{ expanded: enabled && expanded, disabled }}
        disabled={disabled}
        onPress={() => enabled && setExpanded((value) => !value)}
        style={styles.row}
      >
        <View style={styles.icon}>{icon}</View>
        <View style={styles.copy}>
          <CKText role="bodyLarge" style={styles.semi}>
            {title}
          </CKText>
          <CKText muted role="bodySmall">
            {description}
          </CKText>
        </View>
        {expanded ? (
          <ChevronUp color={theme.onSurfaceVariant} />
        ) : (
          <ChevronDown color={theme.onSurfaceVariant} />
        )}
        <SettingSwitch
          value={enabled}
          disabled={disabled}
          onChange={(value) => {
            setExpanded(value);
            onToggle(value);
          }}
        />
      </Pressable>
      {enabled && expanded ? (
        <View
          style={[
            styles.timings,
            { backgroundColor: colorWithAlpha(theme.surfaceContainerHighest, 0.35) },
          ]}
        >
          {values.length > 0 ? (
            <View style={styles.chips}>
              {[...values]
                .sort((a, b) => b - a)
                .map((minutes) => (
                  <Pressable
                    key={minutes}
                    accessibilityRole="button"
                    onPress={() => onValues(values.filter((value) => value !== minutes))}
                    style={[
                      styles.chip,
                      { backgroundColor: colorWithAlpha(theme.surfaceContainerHighest, 0.72) },
                    ]}
                  >
                    <CKText>{timingLabel(t, minutes)}</CKText>
                    <Trash2 color={theme.onSurfaceVariant} size={15} />
                  </Pressable>
                ))}
            </View>
          ) : null}
          <Pressable
            accessibilityRole="button"
            disabled={values.length >= 3}
            onPress={() => setPicker(true)}
            style={[
              styles.add,
              { backgroundColor: colorWithAlpha(theme.primary, 0.14) },
              values.length >= 3 && styles.disabled,
            ]}
          >
            <Plus color={theme.primary} />
            <CKText role="rowTitle">
              {values.length >= 3 ? t('notifMaximumRemindersAdded') : t('notifAddReminder')}
            </CKText>
          </Pressable>
        </View>
      ) : null}
      {picker ? (
        <ReminderTimingSheet
          title={title}
          maxHours={maxHours}
          selectedTimings={new Set(values)}
          onClose={() => setPicker(false)}
          onSelect={(minutes) => {
            setPicker(false);
            onValues([...values, minutes].sort((a, b) => b - a));
          }}
        />
      ) : null}
    </View>
  );
}

function ReminderTimingSheet({
  title,
  maxHours,
  selectedTimings,
  onClose,
  onSelect,
}: {
  title: string;
  maxHours: number;
  selectedTimings: ReadonlySet<number>;
  onClose: () => void;
  onSelect: (minutes: number) => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [hour, setHour] = useState(1);
  const selectedMinutes = hour * 60;
  const updateHour = (event: NativeSyntheticEvent<NativeScrollEvent>) => {
    const index = Math.round(event.nativeEvent.contentOffset.y / 38);
    setHour(Math.max(1, Math.min(maxHours, index + 1)));
  };
  return (
    <Modal transparent animationType="slide" visible onRequestClose={onClose}>
      <SafeAreaView style={styles.overlay}>
        <Pressable accessibilityRole="button" onPress={onClose} style={styles.dismissArea} />
        <Surface accessibilityViewIsModal style={styles.sheet}>
          <View style={[styles.dragHandle, { backgroundColor: theme.onSurfaceVariant }]} />
          <CKText role="titleLarge" style={styles.strong}>
            {title}
          </CKText>
          <View style={styles.pickerFrame}>
            <View
              pointerEvents="none"
              style={[
                styles.pickerSelection,
                { backgroundColor: colorWithAlpha(theme.surfaceContainerHighest, 0.58) },
              ]}
            />
            <ScrollView
              bounces={false}
              contentContainerStyle={styles.pickerContent}
              decelerationRate="fast"
              onMomentumScrollEnd={updateHour}
              showsVerticalScrollIndicator={false}
              snapToInterval={38}
            >
              {Array.from({ length: maxHours }, (_, index) => (
                <View key={index + 1} style={styles.pickerItem}>
                  <CKText role="bodyLarge">
                    {index === 0
                      ? t('notifDurationOneHour')
                      : t('notifDurationHours', { count: index + 1 })}
                  </CKText>
                </View>
              ))}
            </ScrollView>
          </View>
          <Pressable
            accessibilityRole="button"
            disabled={selectedTimings.has(selectedMinutes)}
            onPress={() => onSelect(selectedMinutes)}
            style={[
              styles.sheetPrimary,
              { backgroundColor: theme.primary },
              selectedTimings.has(selectedMinutes) && styles.disabled,
            ]}
          >
            <CKText role="rowTitle" style={{ color: theme.onPrimary }}>
              {t('notifAddTiming', { timing: timingLabel(t, selectedMinutes) })}
            </CKText>
          </Pressable>
          <View style={styles.quickRow}>
            {[30, 15].map((minutes) => (
              <Pressable
                accessibilityRole="button"
                disabled={selectedTimings.has(minutes)}
                key={minutes}
                onPress={() => onSelect(minutes)}
                style={[
                  styles.quick,
                  { borderColor: theme.outlineVariant },
                  selectedTimings.has(minutes) && styles.disabled,
                ]}
              >
                <CKText role="rowTitle">{t('notifDurationMinutes', { count: minutes })}</CKText>
              </Pressable>
            ))}
          </View>
        </Surface>
      </SafeAreaView>
    </Modal>
  );
}

function SettingsSnackbar({ message, onDismiss }: { message?: string; onDismiss: () => void }) {
  const theme = useCKTheme();
  useEffect(() => {
    if (!message) return undefined;
    const timer = setTimeout(onDismiss, 4000);
    return () => clearTimeout(timer);
  }, [message, onDismiss]);
  if (!message) return null;
  return (
    <Pressable
      accessibilityLiveRegion="polite"
      accessibilityRole="alert"
      onPress={onDismiss}
      style={[styles.snackbar, { backgroundColor: theme.surfaceContainerHighest }]}
    >
      <CKText>{message}</CKText>
    </Pressable>
  );
}

export function timingLabel(t: I18nValue['t'], minutes: number): string {
  if (minutes % 60 === 0) {
    const hours = minutes / 60;
    return hours === 1
      ? t('notifTimingOneHourBefore')
      : t('notifTimingHoursBefore', { count: hours });
  }
  return t('notifTimingMinutesBefore', { count: minutes });
}

function pushFallback(t: I18nValue['t'], result: PushNotificationSetupResult): string {
  return {
    ready: t('notifPushReady'),
    permissionRequired: t('notifPushPermissionRequired'),
    permissionDenied: t('notifPushPermissionDenied'),
    notConfigured: t('notifPushNotConfigured'),
    tokenUnavailable: t('notifPushTokenUnavailable'),
    unsupported: t('notifPushUnsupported'),
    initializing: t('notifPushInitializing'),
  }[result.state];
}

const styles = StyleSheet.create({
  screen: { flex: 1 },
  loadingSkeletons: { gap: 14 },
  push: { padding: 14, flexDirection: 'row', alignItems: 'flex-start', gap: 12 },
  copy: { flex: 1, gap: 2 },
  strong: { fontWeight: '800' },
  semi: { fontWeight: '600' },
  row: {
    minHeight: 68,
    paddingHorizontal: 14,
    paddingVertical: 10,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  icon: { width: 30, alignItems: 'center' },
  timings: { paddingHorizontal: 14, paddingTop: 12, paddingBottom: 14, gap: 10 },
  chips: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  chip: {
    borderRadius: ckRadius.pill,
    paddingHorizontal: 10,
    paddingVertical: 6,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  add: {
    minHeight: 44,
    borderRadius: ckRadius.control,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: ckSpacing.sm,
  },
  disabled: { opacity: 0.46 },
  debugWrap: { padding: 12, gap: 12 },
  accountIntro: { paddingHorizontal: 14, paddingVertical: 10 },
  debug: {
    minHeight: 44,
    borderRadius: ckRadius.control,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: ckSpacing.sm,
  },
  overlay: { flex: 1, justifyContent: 'flex-end', backgroundColor: '#00000066' },
  dismissArea: { flex: 1 },
  sheet: {
    borderBottomLeftRadius: 0,
    borderBottomRightRadius: 0,
    paddingHorizontal: 16,
    paddingBottom: 20,
    gap: 12,
  },
  dragHandle: { width: 36, height: 4, borderRadius: 2, opacity: 0.55, alignSelf: 'center' },
  pickerFrame: { height: 156, overflow: 'hidden' },
  pickerContent: { paddingVertical: 59 },
  pickerSelection: {
    position: 'absolute',
    top: 59,
    left: 0,
    right: 0,
    height: 38,
    borderRadius: 8,
  },
  pickerItem: { height: 38, alignItems: 'center', justifyContent: 'center' },
  sheetPrimary: {
    minHeight: 48,
    borderRadius: ckRadius.control,
    alignItems: 'center',
    justifyContent: 'center',
  },
  quickRow: { flexDirection: 'row', gap: 10 },
  quick: {
    flex: 1,
    minHeight: 46,
    borderRadius: ckRadius.control,
    borderWidth: StyleSheet.hairlineWidth,
    alignItems: 'center',
    justifyContent: 'center',
  },
  snackbar: {
    position: 'absolute',
    left: 16,
    right: 16,
    bottom: 16,
    minHeight: 52,
    borderRadius: 4,
    justifyContent: 'center',
    paddingHorizontal: 16,
    shadowColor: '#000000',
    shadowOpacity: 0.18,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 2 },
    elevation: 4,
  },
});
