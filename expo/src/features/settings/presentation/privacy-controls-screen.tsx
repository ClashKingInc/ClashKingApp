import { useState } from 'react';
import { Modal, Platform, Pressable, StyleSheet, View, useWindowDimensions } from 'react-native';
import { Baby, Download, Edit3, ExternalLink, Save, Shield, Trash2 } from 'lucide-react-native';

import { CKText, LoadingIndicator, Surface, ckRadius, ckSpacing, useCKTheme } from '../../../ui';
import type { PrivacyPresentationActions } from './contracts';
import { SettingsPage } from './settings-components';

const privacyCopy = {
  title: 'Privacy & data',
  policyTitle: 'Privacy policy',
  policyBody:
    'Review what ClashKing collects, why it is used, who processes it, retention rules, and how to contact us.',
  exportTitle: 'Access or export your data',
  exportBody:
    'Download a copy of account data linked to your ClashKing login, including linked Clash of Clans accounts and notification preferences.',
  correctionTitle: 'Correct or limit data',
  correctionBody:
    'Remove linked Clash of Clans accounts from account settings, disable notifications in notification settings, or contact support for correction and restriction requests.',
  deletionTitle: 'Delete your ClashKing account',
  deletionBody:
    'This starts deletion of your ClashKing account and associated app data unless ClashKing must keep limited records for security, fraud prevention, or legal obligations.',
  childrenTitle: 'Children and families',
  childrenBody:
    'ClashKing is a general-audience companion app and is not directed to children. Do not create an account if you are not old enough to consent in your country without parent or guardian approval.',
} as const;

export function privacyColumnCount(platform: string, viewportWidth: number): 1 | 2 {
  return platform === 'web' && viewportWidth >= 900 && Math.min(viewportWidth - 48, 1100) >= 780
    ? 2
    : 1;
}

export function PrivacyControlsScreen({
  actions,
  viewportWidth,
  platform = Platform.OS,
  now = () => new Date(),
  onBack,
}: {
  actions: PrivacyPresentationActions;
  viewportWidth?: number;
  platform?: string;
  now?: () => Date;
  onBack?: () => void;
}) {
  const theme = useCKTheme();
  const measured = useWindowDimensions().width;
  const width = viewportWidth ?? measured;
  const twoColumns = privacyColumnCount(platform, width) === 2;
  const [exporting, setExporting] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [prepared, setPrepared] = useState<{ fileName: string; data: string }>();
  const [notice, setNotice] = useState<string>();
  const [confirming, setConfirming] = useState(false);
  const prepare = async () => {
    setExporting(true);
    try {
      const data = await actions.requestExport();
      const timestamp = now().toISOString().replaceAll(':', '-');
      setPrepared({
        fileName: `clashking-data-${timestamp}.json`,
        data: JSON.stringify(data, null, 2),
      });
      setNotice('Your data export is ready to save.');
    } catch {
      actions.contactSupport();
      setNotice('The data export could not be created. A privacy email has been prepared instead.');
    } finally {
      setExporting(false);
    }
  };
  const save = async () => {
    if (!prepared) {
      setNotice('Prepare your export before saving it.');
      return;
    }
    try {
      await actions.saveExport(prepared.fileName, prepared.data);
      setNotice('Your data export has been saved.');
    } catch {
      actions.contactSupport();
      setNotice('The data export could not be saved. A privacy email has been prepared instead.');
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
      setNotice(
        'The deletion endpoint is not available in this build. A privacy email has been prepared instead.',
      );
    } finally {
      setDeleting(false);
    }
  };
  const cards = [
    <PrivacyCard
      key="policy"
      icon={<Shield color={theme.primary} />}
      title={privacyCopy.policyTitle}
      body={privacyCopy.policyBody}
    >
      <Action
        label="Open policy"
        icon={<ExternalLink color={theme.primary} />}
        onPress={actions.openPrivacyPolicy}
      />
    </PrivacyCard>,
    <PrivacyCard
      key="export"
      icon={<Download color={theme.primary} />}
      title={privacyCopy.exportTitle}
      body={privacyCopy.exportBody}
    >
      <View style={styles.actionRow}>
        <Action
          label={prepared ? 'Refresh export' : 'Prepare export'}
          icon={exporting ? <LoadingIndicator /> : <Download color={theme.primary} />}
          disabled={exporting}
          onPress={() => void prepare()}
        />
        {prepared ? (
          <Action
            label="Save export"
            icon={<Save color={theme.primary} />}
            onPress={() => void save()}
          />
        ) : null}
      </View>
    </PrivacyCard>,
    <PrivacyCard
      key="correct"
      icon={<Edit3 color={theme.primary} />}
      title={privacyCopy.correctionTitle}
      body={privacyCopy.correctionBody}
    >
      <Action
        label="Contact support"
        icon={<Edit3 color={theme.primary} />}
        onPress={actions.contactSupport}
      />
    </PrivacyCard>,
    <PrivacyCard
      key="delete"
      icon={<Trash2 color={theme.error} />}
      title={privacyCopy.deletionTitle}
      body={privacyCopy.deletionBody}
    >
      <Action
        label="Delete account"
        icon={deleting ? <LoadingIndicator /> : <Trash2 color={theme.onError} />}
        destructive
        disabled={deleting}
        onPress={() => setConfirming(true)}
      />
    </PrivacyCard>,
    <PrivacyCard
      key="children"
      icon={<Baby color={theme.primary} />}
      title={privacyCopy.childrenTitle}
      body={privacyCopy.childrenBody}
    />,
  ];
  return (
    <>
      <SettingsPage title={privacyCopy.title} onBack={onBack}>
        {notice ? (
          <CKText accessibilityLiveRegion="polite" style={styles.notice}>
            {notice}
          </CKText>
        ) : null}
        <View style={[styles.cards, twoColumns && styles.twoColumns]}>
          {cards.map((card) => (
            <View key={card.key} style={twoColumns ? styles.half : styles.full}>
              {card}
            </View>
          ))}
        </View>
      </SettingsPage>
      <Modal
        visible={confirming}
        transparent
        animationType="fade"
        onRequestClose={() => setConfirming(false)}
      >
        <View style={styles.modal}>
          <Surface style={styles.dialog}>
            <CKText role="titleLarge">Delete account?</CKText>
            <CKText>
              This request is permanent after processing. You may lose linked accounts, notification
              settings, saved preferences, and authentication methods.
            </CKText>
            <View style={styles.actionRow}>
              <Action label="Cancel" onPress={() => setConfirming(false)} />
              <Action label="Delete account" destructive onPress={() => void remove()} />
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
}: {
  icon: React.ReactNode;
  title: string;
  body: string;
  children?: React.ReactNode;
}) {
  return (
    <Surface radius={ckRadius.card} style={styles.card}>
      <View style={styles.cardTitle}>
        {icon}
        <CKText role="titleMedium" style={styles.strong}>
          {title}
        </CKText>
      </View>
      <CKText muted>{body}</CKText>
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
        { backgroundColor: destructive ? theme.error : theme.surfaceContainerHighest },
        disabled && styles.disabled,
        pressed && styles.pressed,
      ]}
    >
      {icon}
      <CKText style={{ color: destructive ? theme.onError : theme.onSurface, fontWeight: '700' }}>
        {label}
      </CKText>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  cards: { gap: 12 },
  twoColumns: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 16,
    maxWidth: 1100,
    alignSelf: 'center',
  },
  full: { width: '100%' },
  half: { width: '48%' },
  card: { padding: ckSpacing.lg, gap: 10 },
  cardTitle: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  strong: { fontWeight: '700' },
  actionRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 10 },
  action: {
    minHeight: 44,
    borderRadius: ckRadius.control,
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
