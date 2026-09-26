import { Pressable, StyleSheet, View, useWindowDimensions } from 'react-native';
import { useI18n } from '../../i18n';
import { CKText, useCKAccessibility, useCKTheme } from '../../ui';
import { StartupBrand } from './startup-brand';

export function StartupLoadingScreen({
  update,
  onUpdateInBackground,
}: {
  update?: { downloading: boolean; progress: number };
  onUpdateInBackground?: () => void;
} = {}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const { reduceMotion } = useCKAccessibility();
  const { width } = useWindowDimensions();
  const progress =
    update && Number.isFinite(update.progress) ? Math.max(0, Math.min(1, update.progress)) : 0;
  return (
    <View style={[styles.screen, { backgroundColor: theme.surface }]} testID="startup-loading">
      <StartupBrand
        reduceMotion={reduceMotion}
        foreground={theme.onSurface}
        background={theme.surface}
        label={t('appTitle')}
        width={Math.min(width * 0.78, 330)}
      />
      {update ? (
        <View style={styles.updateControls}>
          <CKText
            muted
            style={{ textAlign: 'center', marginBottom: 16 }}
            accessibilityLiveRegion="polite"
          >
            {t(update.downloading ? 'startupDownloadingUpdate' : 'startupCheckingUpdate')}
          </CKText>
          {update.downloading ? (
            <View
              accessibilityRole="progressbar"
              accessibilityValue={{ min: 0, max: 100, now: Math.round(progress * 100) }}
              style={[styles.progressTrack, { backgroundColor: theme.primary + '33' }]}
            >
              <View
                style={{
                  height: '100%',
                  width: `${progress * 100}%`,
                  backgroundColor: theme.primary,
                  borderRadius: 3,
                }}
              />
            </View>
          ) : null}
          <Pressable
            accessibilityRole="button"
            onPress={onUpdateInBackground}
            style={styles.backgroundAction}
          >
            <CKText muted role="bodySmall">
              {t('startupUpdateInBackground')}
            </CKText>
          </Pressable>
        </View>
      ) : null}
    </View>
  );
}
const styles = StyleSheet.create({
  screen: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  updateControls: { marginTop: 48, width: '65%', maxWidth: 320, alignItems: 'center' },
  progressTrack: { height: 5, borderRadius: 3, width: '100%', overflow: 'hidden' },
  backgroundAction: { minHeight: 44, justifyContent: 'center', marginTop: 8 },
});
