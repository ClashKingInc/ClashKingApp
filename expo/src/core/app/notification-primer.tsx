import { Modal, Pressable, StyleSheet, View } from 'react-native';

import { CKText, Surface, ckRadius, ckSpacing, useCKTheme } from '../../ui';

export function NotificationPermissionPrimer({
  visible,
  onDecline,
  onAllow,
}: {
  visible: boolean;
  onDecline: () => void;
  onAllow: () => void;
}) {
  const theme = useCKTheme();
  return (
    <Modal animationType="fade" onRequestClose={onDecline} transparent visible={visible}>
      <View style={styles.backdrop}>
        <Surface accessibilityViewIsModal radius={ckRadius.card} style={styles.dialog}>
          <CKText role="sectionTitle">Enable notifications?</CKText>
          <CKText>
            ClashKing can notify you about war, CWL, account, and project updates. You can change
            this anytime in Settings &gt; Notifications.
          </CKText>
          <View style={styles.actions}>
            <Pressable accessibilityRole="button" onPress={onDecline} style={styles.action}>
              <CKText role="rowTitle" style={{ color: theme.primary }}>
                Not now
              </CKText>
            </Pressable>
            <Pressable
              accessibilityRole="button"
              onPress={onAllow}
              style={[styles.action, styles.allow, { backgroundColor: theme.primary }]}
            >
              <CKText role="rowTitle" style={{ color: theme.onPrimary }}>
                Allow
              </CKText>
            </Pressable>
          </View>
        </Surface>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  backdrop: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: ckSpacing.xl,
    backgroundColor: 'rgba(0, 0, 0, 0.48)',
  },
  dialog: { width: '100%', maxWidth: 520, padding: ckSpacing.xl, gap: ckSpacing.lg },
  actions: { flexDirection: 'row', justifyContent: 'flex-end', gap: ckSpacing.sm },
  action: {
    minHeight: 44,
    minWidth: 88,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: ckSpacing.md,
  },
  allow: { borderRadius: ckRadius.control },
});
