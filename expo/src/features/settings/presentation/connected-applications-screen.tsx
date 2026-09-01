import { useEffect, useState } from 'react';
import { Modal, Pressable, RefreshControl, StyleSheet, View } from 'react-native';
import { Cable, Unplug } from 'lucide-react-native';

import { useI18n } from '../../../i18n';
import {
  CKText,
  EmptyState,
  ErrorState,
  LoadingIndicator,
  Snackbar,
  Surface,
  ckRadius,
  ckSpacing,
  colorWithAlpha,
  useCKTheme,
} from '../../../ui';
import type { ConnectedApplicationGrantItem, ConnectedApplicationsServiceContract } from '../data';
import { SettingsPage, SettingsSection } from './settings-components';

export function ConnectedApplicationsScreen({
  service,
  onBack,
}: {
  service: ConnectedApplicationsServiceContract;
  onBack: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [items, setItems] = useState<readonly ConnectedApplicationGrantItem[] | null>(null);
  const [loading, setLoading] = useState(true);
  const [loadFailed, setLoadFailed] = useState(false);
  const [refreshing, setRefreshing] = useState(false);
  const [confirming, setConfirming] = useState<ConnectedApplicationGrantItem>();
  const [revokingId, setRevokingId] = useState<string>();
  const [notice, setNotice] = useState<string>();

  useEffect(() => {
    let active = true;
    void service
      .load()
      .then((loaded) => {
        if (active) setItems(loaded);
      })
      .catch(() => {
        if (active) setLoadFailed(true);
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
  }, [service]);

  const load = async (refresh = false) => {
    if (refresh) setRefreshing(true);
    else setLoading(true);
    setLoadFailed(false);
    try {
      setItems(await service.load());
    } catch {
      if (items === null) setLoadFailed(true);
      else setNotice(t('connectedAppsLoadErrorTitle'));
    } finally {
      if (refresh) setRefreshing(false);
      else setLoading(false);
    }
  };

  const revoke = async (item: ConnectedApplicationGrantItem) => {
    const applicationId = item.application.id;
    if (revokingId !== undefined) return;
    setRevokingId(applicationId);
    try {
      await service.revoke(applicationId);
      setItems(
        (current) => current?.filter(({ application }) => application.id !== applicationId) ?? [],
      );
      setNotice(t('connectedAppsDisconnected', { name: item.application.name }));
    } catch {
      setNotice(t('connectedAppsDisconnectFailed', { name: item.application.name }));
    } finally {
      setConfirming(undefined);
      setRevokingId(undefined);
    }
  };

  let content: React.ReactNode;
  if (loading && items === null && !loadFailed) {
    content = <LoadingIndicator label={t('generalLoading')} />;
  } else if (loadFailed) {
    content = (
      <ErrorState
        actionLabel={t('generalRetry')}
        body={t('generalTryAgain')}
        icon={<Cable color={theme.error} />}
        onAction={() => void load()}
        title={t('connectedAppsLoadErrorTitle')}
      />
    );
  } else if (items?.length === 0) {
    content = (
      <EmptyState
        body={t('connectedAppsEmptyBody')}
        icon={<Cable color={theme.onSurfaceVariant} />}
        title={t('connectedAppsEmptyTitle')}
      />
    );
  } else {
    content = (
      <SettingsSection title={t('connectedAppsActiveConnections')}>
        {items?.map((item) => (
          <ConnectedApplicationRow
            item={item}
            key={item.application.id}
            revoking={revokingId === item.application.id}
            onDisconnect={() => setConfirming(item)}
          />
        ))}
      </SettingsSection>
    );
  }

  return (
    <>
      <SettingsPage
        onBack={onBack}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            tintColor={theme.primary}
            onRefresh={() => void load(true)}
          />
        }
        title={t('settingsConnectedAppsTitle')}
      >
        <View style={styles.content}>{content}</View>
      </SettingsPage>
      <DisconnectDialog
        item={confirming}
        busy={confirming?.application.id === revokingId}
        onCancel={() => {
          if (revokingId === undefined) setConfirming(undefined);
        }}
        onConfirm={() => {
          if (confirming) void revoke(confirming);
        }}
      />
      <Snackbar message={notice} onDismiss={() => setNotice(undefined)} />
    </>
  );
}

function ConnectedApplicationRow({
  item,
  revoking,
  onDisconnect,
}: {
  item: ConnectedApplicationGrantItem;
  revoking: boolean;
  onDisconnect: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const allAccounts = item.grant.accessMode === 'all_current_and_future';
  return (
    <View style={styles.row}>
      <View
        style={[styles.applicationIcon, { backgroundColor: colorWithAlpha(theme.primary, 0.12) }]}
      >
        <Cable color={theme.primary} size={22} />
      </View>
      <View style={styles.copy}>
        <CKText role="bodyLarge" numberOfLines={1} style={styles.name}>
          {item.application.name}
        </CKText>
        {item.application.developerName ? (
          <CKText muted role="bodySmall" numberOfLines={1}>
            {item.application.developerName}
          </CKText>
        ) : null}
        <CKText muted role="bodySmall" style={styles.accessSummary}>
          {allAccounts
            ? t('connectedAppsAccessAll')
            : t('connectedAppsAccessSelected', {
                count: item.grant.selectedPlayerTags.length,
              })}
        </CKText>
        {!allAccounts && item.grant.selectedPlayerTags.length > 0 ? (
          <CKText muted role="labelMedium" numberOfLines={2} style={styles.tags}>
            {item.grant.selectedPlayerTags.join(', ')}
          </CKText>
        ) : null}
      </View>
      <Pressable
        accessibilityRole="button"
        accessibilityState={{ disabled: revoking }}
        disabled={revoking}
        onPress={onDisconnect}
        style={({ pressed }) => [
          styles.disconnect,
          revoking && styles.disabled,
          pressed && styles.pressed,
        ]}
      >
        {revoking ? <LoadingIndicator /> : <Unplug color={theme.error} size={18} />}
        <CKText role="labelLarge" style={{ color: theme.error }}>
          {t('connectedAppsDisconnect')}
        </CKText>
      </Pressable>
    </View>
  );
}

function DisconnectDialog({
  item,
  busy,
  onCancel,
  onConfirm,
}: {
  item?: ConnectedApplicationGrantItem;
  busy: boolean;
  onCancel: () => void;
  onConfirm: () => void;
}) {
  const { t } = useI18n();
  return (
    <Modal visible={item !== undefined} transparent animationType="fade" onRequestClose={onCancel}>
      <View style={styles.modal} accessibilityViewIsModal>
        <Surface radius={ckRadius.card} style={styles.dialog}>
          <CKText role="titleLarge">{t('connectedAppsDisconnectConfirmTitle')}</CKText>
          <CKText>
            {t('connectedAppsDisconnectConfirmBody', { name: item?.application.name ?? '' })}
          </CKText>
          <View style={styles.dialogActions}>
            <DialogAction disabled={busy} label={t('generalCancel')} onPress={onCancel} />
            <DialogAction
              destructive
              disabled={busy}
              label={t('connectedAppsDisconnect')}
              loading={busy}
              onPress={onConfirm}
            />
          </View>
        </Surface>
      </View>
    </Modal>
  );
}

function DialogAction({
  label,
  destructive = false,
  disabled = false,
  loading = false,
  onPress,
}: {
  label: string;
  destructive?: boolean;
  disabled?: boolean;
  loading?: boolean;
  onPress: () => void;
}) {
  const theme = useCKTheme();
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ disabled }}
      disabled={disabled}
      onPress={onPress}
      style={({ pressed }) => [
        styles.dialogAction,
        disabled && styles.disabled,
        pressed && styles.pressed,
      ]}
    >
      {loading ? <LoadingIndicator /> : null}
      <CKText style={{ color: destructive ? theme.error : theme.onSurface }}>{label}</CKText>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  content: { minHeight: 180, justifyContent: 'center' },
  row: {
    minHeight: 112,
    paddingHorizontal: 14,
    paddingVertical: 12,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  applicationIcon: {
    width: 38,
    height: 38,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  copy: { flex: 1, gap: 2 },
  name: { fontWeight: '700' },
  accessSummary: { marginTop: 4 },
  tags: { marginTop: 2 },
  disconnect: { minHeight: 42, alignItems: 'center', justifyContent: 'center', gap: 2 },
  modal: { flex: 1, justifyContent: 'center', padding: 24, backgroundColor: '#00000066' },
  dialog: { width: '100%', maxWidth: 520, alignSelf: 'center', padding: ckSpacing.lg, gap: 16 },
  dialogActions: { flexDirection: 'row', justifyContent: 'flex-end', gap: 10 },
  dialogAction: {
    minHeight: 42,
    paddingHorizontal: 12,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
  },
  disabled: { opacity: 0.45 },
  pressed: { opacity: 0.72 },
});
