import { Modal, Pressable, StyleSheet, View } from 'react-native';

import { useI18n } from '../i18n';
import { CKText } from './text';
import { Surface } from './surfaces';
import { ckSpacing } from './tokens';
import { useCKTheme } from './theme';

export function ClashHandoffDialog({
  visible,
  onCancel,
  onConfirm,
}: {
  visible: boolean;
  onCancel: () => void;
  onConfirm: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onCancel}>
      <View style={styles.overlay}>
        <Surface style={styles.dialog} accessibilityViewIsModal>
          <CKText role="titleSmall" style={{ color: theme.error, textAlign: 'center' }}>
            {t('generalWarning')}
          </CKText>
          <CKText>{t('errorExitAppToOpenClash')}</CKText>
          <View style={styles.actions}>
            <DialogAction label={t('generalCancel')} onPress={onCancel} />
            <DialogAction label={t('generalOk')} onPress={onConfirm} />
          </View>
        </Surface>
      </View>
    </Modal>
  );
}

function DialogAction({ label, onPress }: { label: string; onPress: () => void }) {
  return (
    <Pressable accessibilityRole="button" onPress={onPress} style={styles.action}>
      <CKText role="bodyMedium">{label}</CKText>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  overlay: { flex: 1, justifyContent: 'center', backgroundColor: '#00000066', padding: 24 },
  dialog: {
    padding: ckSpacing.lg,
    gap: ckSpacing.lg,
    width: '100%',
    maxWidth: 520,
    alignSelf: 'center',
  },
  actions: { flexDirection: 'row', justifyContent: 'flex-end' },
  action: {
    minWidth: 64,
    minHeight: 44,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 8,
  },
});
