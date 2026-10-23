import { useContext, useEffect, useState, type ReactNode } from 'react';
import { Pressable, StyleSheet, View, useWindowDimensions } from 'react-native';
import { SafeAreaInsetsContext } from 'react-native-safe-area-context';
import { useI18n } from '../../i18n';
import { CKText, useCKAccessibility, useCKTheme } from '../../ui';
import { StartupBrand } from './startup-brand';

/** Mount Home underneath the same splash so its requests settle before it is revealed. */
export function StartupHandoff({ loading, children }: { loading: boolean; children: ReactNode }) {
  return (
    <View style={{ flex: 1 }}>
      <View
        style={{ flex: 1 }}
        accessibilityElementsHidden={loading}
        importantForAccessibility={loading ? 'no-hide-descendants' : 'auto'}
        pointerEvents={loading ? 'none' : 'auto'}
      >
        {children}
      </View>
      {loading ? (
        <View style={StyleSheet.absoluteFill} testID="startup-cover">
          <StartupLoadingScreen />
        </View>
      ) : null}
    </View>
  );
}

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
  const insets = useContext(SafeAreaInsetsContext);
  const [statusIndex, setStatusIndex] = useState(-1);
  useEffect(() => {
    if (update) return;
    const reveal = setTimeout(() => setStatusIndex(0), 770);
    const rotate = setInterval(() => setStatusIndex((index) => (index + 1) % 6), 3000);
    return () => {
      clearTimeout(reveal);
      clearInterval(rotate);
    };
  }, [update]);
  const messages = [
    'loadingVillages',
    'loadingClanData',
    'loadingWarStats',
    'loadingLegendsData',
    'loadingCapitalRaids',
    'loadingAlmostReady',
  ] as const;
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
      {!update && statusIndex >= 0 ? (
        <View style={styles.status}>
          <CKText muted accessibilityLiveRegion="polite" style={{ textAlign: 'center' }}>
            {t(messages[statusIndex]!)}
          </CKText>
        </View>
      ) : null}
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
      {/* Keep the existing translated unofficiality notice visible immediately,
          including the update-check splash; it must not wait for loading tips. */}
      <View style={[styles.disclaimer, { bottom: (insets?.bottom ?? 0) + 16 }]}>
        <CKText muted style={styles.disclaimerText}>
          {t('faqFanContentPolicy')}
        </CKText>
      </View>
    </View>
  );
}
const styles = StyleSheet.create({
  screen: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  status: { position: 'absolute', bottom: '18%', left: 24, right: 24 },
  updateControls: { marginTop: 48, width: '65%', maxWidth: 320, alignItems: 'center' },
  progressTrack: { height: 5, borderRadius: 3, width: '100%', overflow: 'hidden' },
  backgroundAction: { minHeight: 44, justifyContent: 'center', marginTop: 8 },
  disclaimer: { position: 'absolute', left: 24, right: 24, alignItems: 'center' },
  disclaimerText: { maxWidth: 560, fontSize: 12, lineHeight: 17, textAlign: 'center' },
});
