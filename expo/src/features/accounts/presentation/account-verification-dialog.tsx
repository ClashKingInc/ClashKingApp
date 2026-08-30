import { useState } from 'react';
import { Modal, Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { ExternalLink, Shield } from 'lucide-react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { ImageAssets } from '../../../core/assets/image-assets';
import { useI18n } from '../../../i18n';
import { CKText, MobileWebImage, Surface, ckRadius, ckSpacing, useCKTheme } from '../../../ui';
import { AuthField, PrimaryAction, TextAction } from '../../auth/presentation';

export function AccountVerificationDialog({
  visible,
  playerTag,
  playerName,
  townHallLevel,
  onVerify,
  onOpenSettings,
  onCancel,
  onVerified,
}: {
  visible: boolean;
  playerTag: string;
  playerName: string;
  townHallLevel: number;
  onVerify: (token: string) => Promise<{ success: boolean; message: string | null }>;
  onOpenSettings: () => boolean | void | Promise<boolean | void>;
  onCancel: () => void;
  onVerified: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [token, setToken] = useState('');
  const [error, setError] = useState<string>();
  const [loading, setLoading] = useState(false);
  const verify = async () => {
    if (!token.trim()) {
      setError(t('accountsApiToken'));
      return;
    }
    setLoading(true);
    setError(undefined);
    const result = await onVerify(token.trim());
    setLoading(false);
    if (result.success) {
      setToken('');
      onVerified();
    } else setError(result.message ?? t('accountsErrorWrongApiToken'));
  };
  return (
    <Modal
      animationType="fade"
      onRequestClose={loading ? undefined : onCancel}
      transparent
      visible={visible}
    >
      <SafeAreaView style={styles.overlay}>
        <Surface radius={ckRadius.card} style={styles.dialog} accessibilityViewIsModal>
          <ScrollView keyboardShouldPersistTaps="handled" contentContainerStyle={styles.content}>
            <CKText role="titleMedium" style={styles.strong}>
              {t('accountVerificationTitle')}
            </CKText>
            <Surface muted radius={ckRadius.chip} style={styles.player}>
              <MobileWebImage
                imageUrl={ImageAssets.townHall(townHallLevel > 0 ? townHallLevel : 1)}
                errorFallback={
                  <Shield color={theme.onSurfaceVariant} size={40} style={styles.townHall} />
                }
                style={styles.townHall}
              />
              <View style={styles.playerCopy}>
                <CKText role="titleSmall" numberOfLines={1} style={styles.strong}>
                  {playerName}
                </CKText>
                <CKText muted role="bodySmall">
                  {playerTag}
                </CKText>
              </View>
            </Surface>
            <CKText style={styles.strong}>{t('accountsEnterApiToken')}</CKText>
            <CKText muted role="bodySmall">
              {t('accountsApiTokenLocation')}
            </CKText>
            <AuthField
              label={t('accountsApiToken')}
              value={token}
              editable={!loading}
              onChangeText={setToken}
              error={error}
            />
            <Pressable
              accessibilityRole="link"
              onPress={() => {
                void Promise.resolve(onOpenSettings())
                  .then((opened) => {
                    if (opened === false) setError(t('accountsCouldNotOpenClash'));
                  })
                  .catch(() => setError(t('accountsCouldNotOpenClash')));
              }}
              style={styles.open}
            >
              <ExternalLink color={theme.primary} size={16} />
              <CKText style={{ color: theme.primary }}>{t('accountsOpenMoreSettings')}</CKText>
            </Pressable>
            <View style={styles.actions}>
              <TextAction label={t('generalCancel')} disabled={loading} onPress={onCancel} />
              <View style={styles.verify}>
                <PrimaryAction
                  label={t('accountVerify')}
                  loading={loading}
                  onPress={() => void verify()}
                />
              </View>
            </View>
          </ScrollView>
        </Surface>
      </SafeAreaView>
    </Modal>
  );
}

const styles = StyleSheet.create({
  overlay: { flex: 1, backgroundColor: '#00000066', justifyContent: 'center', padding: 20 },
  dialog: { width: '100%', maxWidth: 560, alignSelf: 'center', maxHeight: '90%' },
  content: { padding: ckSpacing.lg, gap: ckSpacing.md },
  strong: { fontWeight: '800' },
  player: { padding: 10, flexDirection: 'row', alignItems: 'center', gap: 12 },
  townHall: { width: 48, height: 48, resizeMode: 'contain' },
  playerCopy: { flex: 1 },
  open: {
    minHeight: 44,
    borderWidth: StyleSheet.hairlineWidth,
    borderRadius: ckRadius.control,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
  },
  actions: { flexDirection: 'row', justifyContent: 'flex-end', alignItems: 'center', gap: 8 },
  verify: { minWidth: 112 },
});
