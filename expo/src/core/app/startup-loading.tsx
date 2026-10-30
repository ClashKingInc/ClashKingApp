import { createContext, useContext, useEffect, useState, useSyncExternalStore, type ReactNode } from 'react';
import { Pressable, StyleSheet, View, useWindowDimensions } from 'react-native';
import { SafeAreaInsetsContext } from 'react-native-safe-area-context';
import { useI18n } from '../../i18n';
import { CKText, useCKAccessibility, useCKTheme } from '../../ui';
import { isResumingStartupUpdate, registerStartupCover } from './startup-update-handoff';
import { useStartupUpdate } from './startup-update-gate';
import { StartupBrand } from './startup-brand';
import { StartupHalloweenBrand } from './startup-halloween-brand';
import { useAppRuntime } from './runtime-context';
import { HALLOWEEN_ICON_NAME } from '../../features/settings/app-icons/app-icon-service';

const StartupCoveredContext = createContext(true);
export const useStartupCovered = () => useContext(StartupCoveredContext);

/** Mount Home underneath the same splash so its requests settle before it is revealed. */
export function StartupHandoff({ loading, children }: { loading: boolean; children: ReactNode }) {
  const update = useStartupUpdate();
  const covered = loading || !update.ready;
  return (
    <View style={{ flex: 1 }}>
      <View
        style={{ flex: 1 }}
        accessibilityElementsHidden={covered}
        importantForAccessibility={covered ? 'no-hide-descendants' : 'auto'}
        pointerEvents={covered ? 'none' : 'auto'}
      >
        <StartupCoveredContext.Provider value={covered}>{children}</StartupCoveredContext.Provider>
      </View>
      {covered ? (
        <View
          ref={registerStartupCover}
          collapsable={false}
          style={StyleSheet.absoluteFill}
          testID="startup-cover"
        >
          <StartupLoadingScreen
            update={update.ready ? undefined : update}
            onUpdateInBackground={update.continueInBackground}
          />
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
  const { width, height } = useWindowDimensions();
  const [footerHeight, setFooterHeight] = useState(0);
  const resumeUpdate = isResumingStartupUpdate();
  const insets = useContext(SafeAreaInsetsContext);
  const { appIcons } = useAppRuntime();
  const selectedIcon = useSyncExternalStore(
    appIcons.subscribeSelection,
    appIcons.getSelectionSnapshot,
    appIcons.getSelectionSnapshot,
  );
  const [selectionUnavailable, setSelectionUnavailable] = useState(false);
  const [statusIndex, setStatusIndex] = useState(resumeUpdate ? 0 : -1);
  useEffect(() => {
    let active = true;
    void appIcons.getAlternateIconName().catch(() => {
      if (active) setSelectionUnavailable(true);
    });
    return () => {
      active = false;
    };
  }, [appIcons]);
  useEffect(() => {
    const reveal = setTimeout(() => setStatusIndex(0), 770);
    const rotate = setInterval(() => setStatusIndex((index) => (index + 1) % 6), 3000);
    return () => {
      clearTimeout(reveal);
      clearInterval(rotate);
    };
  }, []);
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
      {selectedIcon === undefined && !selectionUnavailable ? (
        <View
          style={{
            width: Math.min(width * 0.78, 330),
            height: 134 + 24 + (Math.min(width * 0.78, 330) * 23) / 163,
          }}
        />
      ) : selectedIcon === HALLOWEEN_ICON_NAME ? (
        <StartupHalloweenBrand
          reduceMotion={reduceMotion || resumeUpdate}
          foreground={theme.onSurface}
          background={theme.surface}
          label={t('appTitle')}
          width={Math.min(width * 0.78, 330)}
        />
      ) : (
        <StartupBrand
          reduceMotion={reduceMotion || resumeUpdate}
          foreground={theme.onSurface}
          background={theme.surface}
          label={t('appTitle')}
          width={Math.min(width * 0.78, 330)}
        />
      )}
      {!update?.downloading && statusIndex >= 0 ? (
        <View
          style={[
            styles.status,
            { bottom: Math.max(height * 0.18, footerHeight + (insets?.bottom ?? 0) + 32) },
          ]}
        >
          <CKText muted accessibilityLiveRegion="polite" style={{ textAlign: 'center' }}>
            {t(messages[statusIndex]!)}
          </CKText>
        </View>
      ) : null}
      <View
        style={[styles.footer, { bottom: (insets?.bottom ?? 0) + 16 }]}
        onLayout={(event) => setFooterHeight(event.nativeEvent.layout.height)}
      >
        {update?.downloading ? (
          <View style={styles.updateControls}>
            <View
              accessibilityRole="progressbar"
              accessibilityLabel={t('startupDownloadingUpdate')}
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
        <CKText muted style={styles.disclaimerText}>
          {t('faqFanContentPolicy')}
        </CKText>
      </View>
    </View>
  );
}
const styles = StyleSheet.create({
  screen: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  status: { position: 'absolute', left: 24, right: 24 },
  updateControls: { width: '100%', maxWidth: 320, alignItems: 'center', marginBottom: 12 },
  progressTrack: { height: 5, borderRadius: 3, width: '100%', maxWidth: 320, overflow: 'hidden' },
  backgroundAction: { minHeight: 44, justifyContent: 'center', marginTop: 8 },
  footer: { position: 'absolute', left: 24, right: 24, alignItems: 'center' },
  disclaimerText: { maxWidth: 560, fontSize: 12, lineHeight: 17, textAlign: 'center' },
});
