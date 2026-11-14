import { useState } from 'react';
import { Linking, Modal, Pressable, StyleSheet, View } from 'react-native';
import { ExternalLink, Gamepad2, ShoppingBag, X } from 'lucide-react-native';

import { ImageAssets } from '../../../core/assets/image-assets';
import { supportCreatorUrl } from '../../../core/app/runtime-effects';
import { materialCloseLabel, useI18n } from '../../../i18n';
import {
  CKText,
  DialogFrame,
  MobileWebImage,
  PressableSurface,
  ckRadius,
  ckSpacing,
  colorWithAlpha,
  useCKAccessibility,
  useCKTheme,
  useCKThemeMode,
} from '../../../ui';
import { modalOrientations } from '../../../ui/modal-orientations';

export function CreatorCodeDialog({ visible, onClose }: { visible: boolean; onClose: () => void }) {
  const { t, locale, isRtl } = useI18n();
  const theme = useCKTheme();
  const mode = useCKThemeMode();
  const { reduceMotion } = useCKAccessibility();
  const [opening, setOpening] = useState(false);
  const [failed, setFailed] = useState(false);
  const close = () => {
    setFailed(false);
    onClose();
  };
  const open = async (url: string) => {
    if (opening) return;
    setOpening(true);
    setFailed(false);
    try {
      await Linking.openURL(url);
      onClose();
    } catch {
      setFailed(true);
    } finally {
      setOpening(false);
    }
  };
  const destinations = [
    { label: t('homeCreatorCodeInGame'), url: supportCreatorUrl(locale), Icon: Gamepad2 },
    {
      label: t('homeCreatorCodeInStore'),
      url: 'https://store.supercell.com/en/clashofclans?boost=clashking',
      Icon: ShoppingBag,
    },
  ];
  return (
    <Modal
      supportedOrientations={modalOrientations}
      visible={visible}
      transparent
      animationType={reduceMotion ? 'none' : 'fade'}
      onRequestClose={close}
    >
      <DialogFrame scrollable>
        <View onAccessibilityEscape={close} style={styles.content} testID="creator-code-dialog">
          <View style={[styles.header, isRtl && styles.rowRtl]}>
            <MobileWebImage
              imageUrl={mode === 'dark' ? ImageAssets.darkModeLogo : ImageAssets.lightModeLogo}
              style={styles.logo}
            />
            <View style={styles.heading}>
              <CKText role="titleSmall" accessibilityRole="header">
                {t('todoUseCodeClashKing')}
              </CKText>
              <CKText role="bodySmall" muted>
                {t('gameCreatorCodeDescription')}
              </CKText>
            </View>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={materialCloseLabel(locale)}
              onPress={close}
              style={styles.close}
            >
              <X size={20} color={theme.onSurfaceVariant} />
            </Pressable>
          </View>
          <View style={styles.destinations}>
            {destinations.map(({ label, url, Icon }) => (
              <PressableSurface
                key={url}
                accessibilityRole="link"
                accessibilityLabel={label}
                accessibilityState={{ disabled: opening, busy: opening }}
                disabled={opening}
                onPress={() => void open(url)}
                style={[
                  styles.destination,
                  { backgroundColor: colorWithAlpha(theme.surfaceContainerHighest, 0.45) },
                  opening && { opacity: 0.6 },
                  isRtl && styles.rowRtl,
                ]}
              >
                <View
                  style={[styles.icon, { backgroundColor: colorWithAlpha(theme.primary, 0.12) }]}
                >
                  <Icon size={22} color={theme.primary} />
                </View>
                <CKText role="bodyMedium" style={styles.destinationLabel}>
                  {label}
                </CKText>
                <ExternalLink size={18} color={theme.onSurfaceVariant} />
              </PressableSurface>
            ))}
          </View>
          {failed ? (
            <CKText role="bodySmall" accessibilityRole="alert" style={{ color: theme.error }}>
              {t('homeCreatorCodeOpenFailed')}
            </CKText>
          ) : null}
        </View>
      </DialogFrame>
    </Modal>
  );
}

const styles = StyleSheet.create({
  content: { gap: ckSpacing.xl },
  header: { flexDirection: 'row', alignItems: 'center', gap: ckSpacing.md },
  heading: { flex: 1, gap: ckSpacing.xs },
  logo: { width: 44, height: 44 },
  close: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  destinations: { gap: ckSpacing.sm },
  destination: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: ckSpacing.md,
    padding: ckSpacing.md,
    borderRadius: ckRadius.control,
    borderWidth: 0,
  },
  icon: {
    width: 40,
    height: 40,
    borderRadius: ckRadius.control,
    alignItems: 'center',
    justifyContent: 'center',
  },
  destinationLabel: { flex: 1, fontWeight: '600' },
  rowRtl: { flexDirection: 'row-reverse' },
});
