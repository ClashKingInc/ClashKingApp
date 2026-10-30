import { useAdaptiveLayout } from '../../../ui/adaptive-layout';
import { modalOrientations } from '../../../ui/modal-orientations';
import { useState } from 'react';
import { Modal, Platform, Pressable, StyleSheet, View, useWindowDimensions } from 'react-native';
import {
  Baby,
  Download,
  Edit3,
  EyeOff,
  ExternalLink,
  Save,
  Share2,
  Shield,
  Trash2,
} from 'lucide-react-native';

import { useI18n } from '../../../i18n';
import {
  CKText,
  LoadingIndicator,
  Surface,
  ckRadius,
  ckSpacing,
  colorWithAlpha,
  useCKTheme,
} from '../../../ui';
import type { PrivacyPresentationActions } from './contracts';
import { SettingsPage } from './settings-components';
import { ProfileOptionSwitch } from '../../../ui/profile-option-switch';

export function privacyColumnCount(platform: string, viewportWidth: number): 1 | 2 {
  return ['web', 'ios', 'android'].includes(platform) &&
    viewportWidth >= 900 &&
    Math.min(viewportWidth - 48, 1100) >= 780
    ? 2
    : 1;
}

export function PrivacyControlsScreen({
  actions,
  viewportWidth,
  platform = Platform.OS,
  now = () => new Date(),
  onBack,
  hideAccountsEnabled = false,
  onHideAccountsChange,
}: {
  actions: PrivacyPresentationActions;
  viewportWidth?: number;
  platform?: string;
  now?: () => Date;
  onBack?: () => void;
  hideAccountsEnabled?: boolean;
  onHideAccountsChange?: (enabled: boolean) => Promise<void>;
}) {
  const { t } = useI18n();
  const layout = useAdaptiveLayout();
  const theme = useCKTheme();
  const measured = useWindowDimensions().width;
  const width = viewportWidth ?? measured;
  const twoColumns = layout.isExpanded || privacyColumnCount(platform, width) === 2;
  const [exporting, setExporting] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [prepared, setPrepared] = useState<{ fileName: string; data: string }>();
  const [notice, setNotice] = useState<string>();
  const [confirming, setConfirming] = useState(false);
  const [savingHideAccounts, setSavingHideAccounts] = useState(false);
  const prepare = async () => {
    setExporting(true);
    try {
      const data = await actions.requestExport();
      const timestamp = now().toISOString().replaceAll(':', '-');
      setPrepared({
        fileName: `clashking-data-${timestamp}.json`,
        data: JSON.stringify(data, null, 2),
      });
      setNotice(t('settingsPrivacyExportReady'));
    } catch {
      actions.contactSupport();
      setNotice(t('settingsPrivacyExportCreateFailed'));
    } finally {
      setExporting(false);
    }
  };
  const save = async () => {
    if (!prepared) {
      setNotice(t('settingsPrivacyExportPrepareFirst'));
      return;
    }
    try {
      await actions.saveExport(prepared.fileName, prepared.data);
      setNotice(Platform.OS === 'web' ? t('settingsPrivacyExportSaved') : undefined);
    } catch {
      actions.contactSupport();
      setNotice(t('settingsPrivacyExportSaveFailed'));
    }
  };
  const remove = async () => {
    setConfirming(false);
    setDeleting(true);
    try {
      await actions.deleteAccount();
      actions.onDeleted();
    } catch {
      actions.contactSupport();
      setNotice(t('settingsPrivacyDeleteUnavailable'));
    } finally {
      setDeleting(false);
    }
  };
  const cards = [
    <PrivacyCard
      key="policy"
      icon={<Shield color={theme.primary} />}
      title={t('settingsPrivacyPolicy')}
      body={t('settingsPrivacyPolicyDescription')}
    >
      <Action
        label={t('settingsPrivacyOpenPolicy')}
        icon={<ExternalLink color={theme.primary} />}
        onPress={actions.openPrivacyPolicy}
      />
    </PrivacyCard>,
    <PrivacyCard
      key="export"
      icon={<Download color={theme.primary} />}
      title={t('settingsPrivacyExportTitle')}
      body={t('settingsPrivacyExportDescription')}
    >
      <View style={styles.actionRow}>
        <Action
          label={prepared ? t('settingsPrivacyRefreshExport') : t('settingsPrivacyPrepareExport')}
          icon={exporting ? <LoadingIndicator /> : <Download color={theme.primary} />}
          disabled={exporting}
          onPress={() => void prepare()}
        />
        {prepared ? (
          <Action
            label={Platform.OS === 'web' ? t('settingsPrivacySaveExport') : t('gameAssetsShare')}
            icon={
              Platform.OS === 'web' ? (
                <Save color={theme.primary} />
              ) : (
                <Share2 color={theme.primary} />
              )
            }
            onPress={() => void save()}
          />
        ) : null}
      </View>
    </PrivacyCard>,
    <PrivacyCard
      key="correct"
      icon={<Edit3 color={theme.primary} />}
      title={t('settingsPrivacyCorrectionTitle')}
      body={t('settingsPrivacyCorrectionDescription')}
    >
      <Action
        label={t('settingsPrivacyContactSupport')}
        icon={<Edit3 color={theme.primary} />}
        onPress={actions.contactSupport}
      />
    </PrivacyCard>,
    <PrivacyCard
      key="delete"
      destructive
      icon={<Trash2 color={theme.error} />}
      title={t('settingsPrivacyDeletionTitle')}
      body={t('settingsPrivacyDeletionDescription')}
    >
      <Action
        label={t('settingsPrivacyDeleteAccount')}
        icon={deleting ? <LoadingIndicator /> : <Trash2 color={theme.error} />}
        destructive
        disabled={deleting}
        onPress={() => setConfirming(true)}
      />
    </PrivacyCard>,
    <PrivacyCard
      key="children"
      icon={<Baby color={theme.primary} />}
      title={t('settingsPrivacyChildrenTitle')}
      body={t('settingsPrivacyChildrenDescription')}
    />,
  ];
  return (
    <>
      <SettingsPage wide={layout.isExpanded} title={t('settingsPrivacyDataTitle')} onBack={onBack}>
        <Surface
          radius={ckRadius.tile}
          style={[
            styles.preference,
            { backgroundColor: colorWithAlpha(theme.onSurface, 0.045), borderWidth: 0 },
          ]}
        >
          <ProfileOptionSwitch
            icon={<EyeOff color={theme.onSurfaceVariant} />}
            title={t('settingsHideAccounts')}
            subtitle={t('settingsHideAccountsDescription')}
            value={hideAccountsEnabled}
            enabled={!!onHideAccountsChange && !savingHideAccounts}
            loading={savingHideAccounts}
            onChange={(enabled) => {
              setSavingHideAccounts(true);
              void onHideAccountsChange?.(enabled)
                .catch(() => setNotice(t('generalError')))
                .finally(() => setSavingHideAccounts(false));
            }}
          />
        </Surface>
        {notice ? (
          <CKText accessibilityLiveRegion="polite" style={styles.notice}>
            {notice}
          </CKText>
        ) : null}
        <View style={[styles.cards, twoColumns && styles.twoColumns]}>
          {[
            ...cards.filter((card) => card.key !== 'delete'),
            ...cards.filter((card) => card.key === 'delete'),
          ].map((card) => (
            <View key={card.key} style={twoColumns ? styles.half : styles.full}>
              {card}
            </View>
          ))}
        </View>
      </SettingsPage>
      <Modal
        supportedOrientations={modalOrientations}
        visible={confirming}
        transparent
        animationType="fade"
        onRequestClose={() => setConfirming(false)}
      >
        <View style={styles.modal}>
          <Surface style={styles.dialog}>
            <CKText role="titleLarge">{t('settingsPrivacyDeleteConfirmTitle')}</CKText>
            <CKText>{t('settingsPrivacyDeleteConfirmDescription')}</CKText>
            <View style={styles.actionRow}>
              <Action label={t('generalCancel')} onPress={() => setConfirming(false)} />
              <Action
                label={t('settingsPrivacyDeleteAccount')}
                destructive
                onPress={() => void remove()}
              />
            </View>
          </Surface>
        </View>
      </Modal>
    </>
  );
}

function PrivacyCard({
  icon,
  title,
  body,
  children,
  destructive = false,
}: {
  icon: React.ReactNode;
  title: string;
  body: string;
  children?: React.ReactNode;
  destructive?: boolean;
}) {
  const theme = useCKTheme();
  return (
    <Surface
      radius={ckRadius.tile}
      style={[
        styles.card,
        {
          backgroundColor: colorWithAlpha(
            destructive ? theme.error : theme.onSurface,
            destructive ? 0.055 : 0.035,
          ),
          borderWidth: 0,
        },
      ]}
    >
      <View style={styles.cardTitle}>
        <View
          style={[
            styles.iconBadge,
            { backgroundColor: colorWithAlpha(destructive ? theme.error : theme.primary, 0.1) },
          ]}
        >
          {icon}
        </View>
        <CKText
          role="titleSmall"
          style={[styles.strong, { flex: 1, color: destructive ? theme.error : theme.onSurface }]}
        >
          {title}
        </CKText>
      </View>
      <CKText role="bodyMedium" muted style={{ lineHeight: 21 }}>
        {body}
      </CKText>
      {children}
    </Surface>
  );
}
function Action({
  label,
  icon,
  onPress,
  destructive = false,
  disabled = false,
}: {
  label: string;
  icon?: React.ReactNode;
  onPress: () => void;
  destructive?: boolean;
  disabled?: boolean;
}) {
  const theme = useCKTheme();
  return (
    <Pressable
      accessibilityRole="button"
      disabled={disabled}
      onPress={onPress}
      style={({ pressed }) => [
        styles.action,
        {
          backgroundColor: colorWithAlpha(
            destructive ? theme.error : theme.onSurface,
            destructive ? 0.12 : 0.075,
          ),
        },
        disabled && styles.disabled,
        pressed && styles.pressed,
      ]}
    >
      {icon}
      <CKText
        role="rowTitle"
        style={{ color: destructive ? theme.error : theme.onSurface, flexShrink: 1 }}
      >
        {label}
      </CKText>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  cards: { gap: 12 },
  preference: { padding: 10, marginBottom: 16 },
  iconBadge: {
    width: 42,
    height: 42,
    borderRadius: 14,
    alignItems: 'center',
    justifyContent: 'center',
  },
  twoColumns: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 16,
    maxWidth: 1100,
    alignSelf: 'center',
  },
  full: { width: '100%' },
  half: { width: '48.5%' },
  card: { padding: 18, gap: 14 },
  cardTitle: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  strong: { fontWeight: '700' },
  actionRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 10 },
  action: {
    minHeight: 44,
    borderRadius: ckRadius.pill,
    paddingHorizontal: 14,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
  },
  notice: { marginBottom: 12 },
  modal: { flex: 1, justifyContent: 'center', padding: 24, backgroundColor: '#00000066' },
  dialog: {
    padding: ckSpacing.lg,
    gap: ckSpacing.lg,
    maxWidth: 520,
    width: '100%',
    alignSelf: 'center',
  },
  disabled: { opacity: 0.45 },
  pressed: { opacity: 0.72 },
});
