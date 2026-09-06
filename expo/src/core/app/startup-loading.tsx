import { useEffect, useMemo, useRef, useState } from 'react';
import {
  Animated,
  Easing,
  Platform,
  Pressable,
  StyleSheet,
  View,
  useWindowDimensions,
} from 'react-native';

import { useI18n, type MessageKey } from '../../i18n';
import { CKText, MobileWebImage, useCKAccessibility, useCKTheme, useCKThemeMode } from '../../ui';
import { ImageAssets } from '../assets/image-assets';

const loadingMessageKeys = [
  'loadingVillages',
  'loadingClanData',
  'loadingWarStats',
  'loadingLegendsData',
  'loadingCapitalRaids',
  'loadingAlmostReady',
] as const satisfies readonly MessageKey[];

const STARTUP_MESSAGE_HOLD_MS = 800;
const STARTUP_MESSAGE_FADE_MS = 200;

export function StartupLoadingScreen({
  update,
  onUpdateInBackground,
}: {
  update?: { downloading: boolean; progress: number };
  onUpdateInBackground?: () => void;
} = {}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const mode = useCKThemeMode();
  const { reduceMotion } = useCKAccessibility();
  const { width } = useWindowDimensions();
  const desktop = Platform.OS === 'web' && width >= 900;
  const [messageIndex, setMessageIndex] = useState(0);
  const [opacity] = useState(() => new Animated.Value(0));
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    opacity.stopAnimation();
    if (reduceMotion) {
      opacity.setValue(1);
      return undefined;
    }
    opacity.setValue(0);
    let active = true;
    let nextIndex = 0;
    const schedule = () => {
      timer.current = setTimeout(() => {
        Animated.timing(opacity, {
          toValue: 0,
          duration: STARTUP_MESSAGE_FADE_MS,
          easing: Easing.inOut(Easing.ease),
          useNativeDriver: true,
        }).start(({ finished }) => {
          if (!active || !finished) return;
          nextIndex = Math.min(nextIndex + 1, loadingMessageKeys.length - 1);
          setMessageIndex(nextIndex);
          Animated.timing(opacity, {
            toValue: 1,
            duration: STARTUP_MESSAGE_FADE_MS,
            easing: Easing.inOut(Easing.ease),
            useNativeDriver: true,
          }).start(({ finished: fadedIn }) => {
            if (active && fadedIn && nextIndex < loadingMessageKeys.length - 1) schedule();
          });
        });
      }, STARTUP_MESSAGE_HOLD_MS);
    };
    Animated.timing(opacity, {
      toValue: 1,
      duration: STARTUP_MESSAGE_FADE_MS,
      easing: Easing.inOut(Easing.ease),
      useNativeDriver: true,
    }).start();
    schedule();
    return () => {
      active = false;
      if (timer.current !== null) clearTimeout(timer.current);
      opacity.stopAnimation();
    };
  }, [opacity, reduceMotion]);

  const dimensions = useMemo(
    () => ({
      logo: desktop ? 56 : 80,
      wordmark: desktop ? Math.min(width, 260) : width * 0.82,
      wordmarkGap: desktop ? 16 : 30,
      loadingGap: desktop ? 72 : 200,
      dotHeight: desktop ? 6 : 8,
    }),
    [desktop, width],
  );

  return (
    <View style={[styles.screen, { backgroundColor: theme.surface }]} testID="startup-loading">
      <MobileWebImage
        accessibilityIgnoresInvertColors
        imageUrl={mode === 'dark' ? ImageAssets.darkModeLogo : ImageAssets.lightModeLogo}
        errorFallback={<CKText>{t('appTitle')}</CKText>}
        style={{ width: dimensions.logo, height: dimensions.logo, borderRadius: 16 }}
        testID="startup-mark"
      />
      <MobileWebImage
        accessibilityIgnoresInvertColors
        contentFit="contain"
        imageUrl={mode === 'dark' ? ImageAssets.darkModeTextLogo : ImageAssets.lightModeTextLogo}
        errorFallback={<CKText role="screenTitle">{t('appTitle')}</CKText>}
        style={[styles.wordmark, { width: dimensions.wordmark, marginTop: dimensions.wordmarkGap }]}
        testID="startup-wordmark"
      />
      <Animated.Text
        style={[
          styles.message,
          {
            color: theme.onSurfaceVariant,
            marginTop: dimensions.loadingGap,
            opacity: update || reduceMotion ? 1 : opacity,
          },
        ]}
      >
        {update
          ? t(update.downloading ? 'startupDownloadingUpdate' : 'startupCheckingUpdate')
          : t(loadingMessageKeys[messageIndex]!)}
      </Animated.Text>
      {update ? (
        <View style={styles.updateControls}>
          <View
            accessibilityRole="progressbar"
            accessibilityValue={{
              min: 0,
              max: 100,
              now: Math.round(Math.max(0, Math.min(1, update.progress)) * 100),
            }}
            style={[styles.progressTrack, { backgroundColor: `${theme.primary}33` }]}
          >
            <View
              style={{
                height: '100%',
                width: `${Math.max(0, Math.min(1, update.progress)) * 100}%`,
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
      ) : (
        <View style={styles.steps}>
          {loadingMessageKeys.map((key, index) => {
            const active = index <= messageIndex;
            return (
              <View
                accessibilityElementsHidden
                importantForAccessibility="no"
                key={key}
                style={{
                  width: active ? (desktop ? 18 : 20) : dimensions.dotHeight,
                  height: dimensions.dotHeight,
                  marginHorizontal: 4,
                  borderRadius: dimensions.dotHeight / 2,
                  backgroundColor: active ? theme.primary : `${theme.primary}4D`,
                }}
              />
            );
          })}
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  wordmark: { aspectRatio: 3806 / 558 },
  message: { fontFamily: 'ClashKing', fontSize: 16, fontWeight: '500', textAlign: 'center' },
  steps: { flexDirection: 'row', alignItems: 'center', marginTop: 20 },
  updateControls: { marginTop: 20, width: '65%', maxWidth: 320, alignItems: 'center' },
  progressTrack: { height: 5, borderRadius: 3, width: '100%', overflow: 'hidden' },
  backgroundAction: { minHeight: 44, justifyContent: 'center', marginTop: 8 },
});
