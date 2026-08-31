import { useState } from 'react';
import { Image, Modal, Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { ChevronRight, X } from 'lucide-react-native';

import { useI18n } from '../../../i18n';
import { CKText, Surface, ckSpacing, useCKTheme } from '../../../ui';
import { SettingsPage } from './settings-components';

export interface LicensePackageSummary {
  readonly packages: readonly string[];
  readonly license: string;
  readonly text: string;
}

export function LicensesScreen({
  applicationName,
  applicationVersion,
  packages,
  onBack,
}: {
  applicationName: string;
  applicationVersion: string;
  packages: readonly LicensePackageSummary[];
  onBack: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [selected, setSelected] = useState<LicensePackageSummary>();
  return (
    <SettingsPage title={t('settingsLicenses')} onBack={onBack}>
      <View style={styles.application}>
        <Image
          source={require('../../../../assets/clashking/icons/app_icon_ios_default.png')}
          style={styles.icon}
        />
        <CKText role="titleLarge" style={styles.strong}>
          {applicationName}
        </CKText>
        <CKText muted>{applicationVersion}</CKText>
        <CKText muted>© {new Date().getFullYear()} ClashKing</CKText>
      </View>
      <Surface style={styles.list}>
        {packages.map((entry, index) => (
          <View key={`${entry.packages[0]}:${entry.license}`}>
            <Pressable
              accessibilityRole="button"
              onPress={() => setSelected(entry)}
              style={({ pressed }) => [styles.row, pressed && styles.pressed]}
            >
              <View style={styles.copy}>
                <CKText numberOfLines={1} style={styles.strong}>
                  {entry.packages.join(', ')}
                </CKText>
                <CKText muted role="bodySmall">
                  {entry.license}
                </CKText>
              </View>
              <ChevronRight color={theme.onSurfaceVariant} size={22} />
            </Pressable>
            {index < packages.length - 1 ? (
              <View style={[styles.divider, { backgroundColor: theme.outlineVariant }]} />
            ) : null}
          </View>
        ))}
      </Surface>
      <Modal
        animationType="slide"
        onRequestClose={() => setSelected(undefined)}
        presentationStyle="pageSheet"
        visible={selected !== undefined}
      >
        <View style={[styles.licensePage, { backgroundColor: theme.surface }]}>
          <View style={styles.licenseHeader}>
            <View style={styles.copy}>
              <CKText role="titleMedium" numberOfLines={2} style={styles.strong}>
                {selected?.packages.join(', ')}
              </CKText>
              <CKText muted>{selected?.license}</CKText>
            </View>
            <Pressable
              accessibilityLabel={t('generalCancel')}
              accessibilityRole="button"
              onPress={() => setSelected(undefined)}
              style={styles.close}
            >
              <X color={theme.onSurface} />
            </Pressable>
          </View>
          <ScrollView contentContainerStyle={styles.licenseText}>
            <CKText selectable role="bodySmall">
              {selected?.text}
            </CKText>
          </ScrollView>
        </View>
      </Modal>
    </SettingsPage>
  );
}

const styles = StyleSheet.create({
  application: { alignItems: 'center', gap: 4, marginBottom: ckSpacing.xl },
  icon: { width: 48, height: 48, borderRadius: 11, marginBottom: 4 },
  strong: { fontWeight: '700' },
  list: { marginBottom: ckSpacing.xl },
  row: {
    minHeight: 62,
    paddingHorizontal: 16,
    paddingVertical: 10,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  copy: { flex: 1, gap: 2 },
  divider: { height: StyleSheet.hairlineWidth, marginLeft: 16, opacity: 0.32 },
  pressed: { opacity: 0.72 },
  licensePage: { flex: 1 },
  licenseHeader: {
    minHeight: 64,
    paddingHorizontal: ckSpacing.lg,
    paddingVertical: ckSpacing.md,
    flexDirection: 'row',
    alignItems: 'center',
    gap: ckSpacing.md,
  },
  close: { padding: ckSpacing.sm },
  licenseText: { paddingHorizontal: ckSpacing.lg, paddingBottom: ckSpacing.xxl },
});
