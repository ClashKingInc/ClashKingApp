import { useState } from 'react';
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
  allowRemember = false,
}: {
  visible: boolean;
  onCancel: () => void;
  onConfirm: (dontShowAgain: boolean) => void;
  allowRemember?: boolean;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [dontShowAgain, setDontShowAgain] = useState(false);
  const cancel = () => {
    setDontShowAgain(false);
    onCancel();
  };
  const confirm = () => {
    const remember = dontShowAgain;
    setDontShowAgain(false);
    onConfirm(remember);
  };
  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={cancel}>
      <View style={styles.overlay}>
        <Surface style={styles.dialog} accessibilityViewIsModal>
          <CKText role="titleSmall" style={{ color: theme.error, textAlign: 'center' }}>
            {t('generalWarning')}
          </CKText>
          <CKText>{t('errorExitAppToOpenClash')}</CKText>
          {allowRemember ? (
            <Pressable
              accessibilityRole="checkbox"
              accessibilityLabel={t('gameHandoffDontShowAgain')}
              accessibilityState={{ checked: dontShowAgain }}
              onPress={() => setDontShowAgain((current) => !current)}
              style={styles.rememberChoice}
            >
              <View style={[styles.checkbox, { borderColor: theme.onSurfaceVariant }]}>
                {dontShowAgain ? <CKText style={{ color: theme.onSurface }}>✓</CKText> : null}
              </View>
              <CKText>{t('gameHandoffDontShowAgain')}</CKText>
            </Pressable>
          ) : null}
          <View style={styles.actions}>
            <DialogAction label={t('generalCancel')} onPress={cancel} />
            <DialogAction label={t('generalOk')} onPress={confirm} />
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

/** Single-dismiss informational variant of the shared dialog surface. */
export function InfoDialog({
  visible,
  title,
  message,
  onClose,
}: {
  visible: boolean;
  title: string;
  message: string;
  onClose: () => void;
}) {
  const { t } = useI18n();
  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
      <View style={styles.overlay}>
        <Surface style={styles.dialog} accessibilityViewIsModal>
          <CKText role="titleSmall">{title}</CKText>
          <CKText>{message}</CKText>
          <View style={styles.actions}>
            <DialogAction label={t('generalOk')} onPress={onClose} />
          </View>
        </Surface>
      </View>
    </Modal>
  );
}

export function ConfirmationDialog({
  visible,
  title,
  message,
  confirmLabel,
  onCancel,
  onConfirm,
}: {
  visible: boolean;
  title: string;
  message: string;
  confirmLabel: string;
  onCancel: () => void;
  onConfirm: () => void;
}) {
  const { t } = useI18n();
  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onCancel}>
      <View style={styles.overlay}>
        <Surface style={styles.dialog} accessibilityViewIsModal>
          <CKText role="titleSmall">{title}</CKText>
          <CKText>{message}</CKText>
          <View style={styles.actions}>
            <DialogAction label={t('generalCancel')} onPress={onCancel} />
            <DialogAction label={confirmLabel} onPress={onConfirm} />
          </View>
        </Surface>
      </View>
    </Modal>
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
  rememberChoice: { flexDirection: 'row', alignItems: 'center', gap: 10, minHeight: 44 },
  checkbox: {
    width: 22,
    height: 22,
    borderWidth: 1.5,
    borderRadius: 5,
    alignItems: 'center',
    justifyContent: 'center',
  },
  action: {
    minWidth: 64,
    minHeight: 44,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 8,
  },
});
