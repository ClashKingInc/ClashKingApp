import { modalOrientations } from '../../../ui/modal-orientations';
import { useState } from 'react';
import { KeyboardAvoidingView, Platform, Modal, ScrollView, StyleSheet, View } from 'react-native';
import { ExternalLink, Shield } from 'lucide-react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { ImageAssets } from '../../../core/assets/image-assets';
import { useI18n } from '../../../i18n';
import { CKText, MobileWebImage, Surface, ckRadius, ckSpacing, useCKTheme } from '../../../ui';
import { InfoTooltip } from '../../../ui/info-tooltip';
import { AuthField, PrimaryAction } from '../../auth/presentation';

export function AccountVerificationDialog(props: Parameters<typeof VerificationContent>[0]) {
  return props.visible ? <VerificationContent key={props.playerTag} {...props} /> : null;
}

function VerificationContent({
  visible,
  playerTag,
  playerName,
  townHallLevel,
  clanName,
  clanBadgeUrl,
  onVerify,
  onOpenSettings,
  onCancel,
  onVerified,
}: {
  visible: boolean;
  playerTag: string;
  playerName: string;
  townHallLevel: number;
  clanName?: string;
  clanBadgeUrl?: string;
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
    try {
      const result = await onVerify(token.trim());
      if (result.success) {
        setToken('');
        onVerified();
      } else setError(result.message ?? t('accountsErrorWrongApiToken'));
    } catch {
      setError(t('accountsErrorFailedToAdd'));
    } finally {
      setLoading(false);
    }
  };
  return (
    <Modal
      supportedOrientations={modalOrientations}
      animationType="fade"
      onRequestClose={loading ? undefined : onCancel}
      transparent
      visible={visible}
    >
      <KeyboardAvoidingView
        style={{ flex: 1 }}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        <SafeAreaView style={styles.overlay}>
          <Surface radius={ckRadius.card} style={styles.dialog} accessibilityViewIsModal>
            <ScrollView keyboardShouldPersistTaps="handled" contentContainerStyle={styles.content}>
              <Surface muted radius={ckRadius.chip} style={styles.player}>
                {townHallLevel > 0 ? (
                  <MobileWebImage
                    imageUrl={ImageAssets.townHall(townHallLevel)}
                    errorFallback={
                      <Shield color={theme.onSurfaceVariant} size={40} style={styles.townHall} />
                    }
                    style={styles.townHall}
                  />
                ) : (
                  <Shield color={theme.onSurfaceVariant} size={40} style={styles.townHall} />
                )}
                <View style={styles.playerCopy}>
                  <CKText role="titleSmall" numberOfLines={1} style={styles.strong}>
                    {playerName}
                  </CKText>
                  <CKText muted role="bodySmall">
                    {playerTag}
                  </CKText>
                </View>
                {clanName ? (
                  <View style={styles.clan}>
                    {clanBadgeUrl ? (
                      <MobileWebImage
                        imageUrl={clanBadgeUrl}
                        style={styles.clanBadge}
                        contentFit="contain"
                      />
                    ) : null}
                    <CKText
                      role="bodySmall"
                      muted
                      numberOfLines={2}
                      style={{ textAlign: 'right', flexShrink: 1 }}
                    >
                      {clanName}
                    </CKText>
                  </View>
                ) : null}
              </Surface>
              <AuthField
                appearance="glass"
                autoCapitalize="none"
                autoCorrect={false}
                onSubmitEditing={() => {
                  if (!loading) void verify();
                }}
                label={t('accountsApiToken')}
                labelAccessory={
                  <InfoTooltip
                    label={t('accountsApiToken')}
                    message={t('accountsEnterApiToken')}
                    triggerStyle={{ width: 28, height: 28 }}
                  />
                }
                value={token}
                editable={!loading}
                onChangeText={setToken}
                error={error}
              />
              <PrimaryAction
                label={t('accountsOpenMoreSettings')}
                color="#087F5B"
                foregroundColor="#FFFFFF"
                disabled={loading}
                leading={<ExternalLink color="#FFFFFF" size={18} />}
                onPress={() => {
                  void Promise.resolve(onOpenSettings())
                    .then((opened) => {
                      if (opened === false) setError(t('accountsCouldNotOpenClash'));
                    })
                    .catch(() => setError(t('accountsCouldNotOpenClash')));
                }}
              />
              <View style={styles.actions}>
                <View style={styles.verify}>
                  <PrimaryAction
                    label={t('generalCancel')}
                    disabled={loading}
                    onPress={onCancel}
                    color={theme.surfaceContainerHighest}
                    foregroundColor={theme.onSurface}
                  />
                </View>
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
      </KeyboardAvoidingView>
    </Modal>
  );
}

const styles = StyleSheet.create({
  overlay: { flex: 1, backgroundColor: '#00000066', justifyContent: 'center', padding: 20 },
  dialog: { width: '100%', maxWidth: 560, alignSelf: 'center', maxHeight: '90%' },
  content: { padding: ckSpacing.lg, gap: ckSpacing.md },
  strong: { fontWeight: '800' },
  player: { padding: 10, flexDirection: 'row', alignItems: 'center', gap: 12 },
  townHall: { width: 56, height: 56, resizeMode: 'contain' },
  playerCopy: { flex: 1, minWidth: 0 },
  clan: { maxWidth: '42%', flexDirection: 'row', alignItems: 'center', gap: 6 },
  clanBadge: { width: 26, height: 30 },
  actions: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  verify: { flex: 1 },
});
