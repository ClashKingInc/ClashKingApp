import { useEffect, useRef, useState } from 'react';
import {
  AccessibilityInfo,
  AppState,
  BackHandler,
  Pressable,
  ScrollView,
  StyleSheet,
  View,
  useWindowDimensions,
} from 'react-native';
import {
  SafeAreaProvider,
  SafeAreaView,
  initialWindowMetrics,
} from 'react-native-safe-area-context';
import { ChevronLeft } from 'lucide-react-native';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { materialBackLabel, materialContinueLabel, useI18n } from '../../i18n';
import type { MessageKey } from '../../i18n/catalogs.generated';
import { CKText, colorWithAlpha, useCKTheme } from '../../ui';
import { useCKAccessibility } from '../../ui/accessibility';
import { PagerView, type PagerViewHandle } from '../../ui/pager';
import { useAppRuntime } from '../../core/app/runtime-context';
import { openSystemNotificationSettings } from '../settings/presentation/system-notification-settings';
import { onboarding } from './onboarding-service';
import { OnboardingScene, onboardingAccents } from './onboarding-scenes';

const pages = [
  { title: 'onboardingOverviewTitle', body: 'onboardingOverviewBody' },
  { title: 'onboardingProgressTitle', body: 'onboardingStatsBody' },
  { title: 'onboardingWidgetsTitle', body: 'onboardingWidgetsBody' },
  { title: 'onboardingRemindersTitle', body: 'onboardingRemindersBody' },
] as const satisfies readonly { title: MessageKey; body: MessageKey }[];

// The overview and notification step share art, but accounts must be reviewed
// between them. Keep this opaque layer mounted while Home prepares behind it.
export function OnboardingScreen({
  stage,
  onAccounts,
  onComplete,
}: {
  stage: 'overview' | 'notifications';
  onAccounts: () => void;
  onComplete: () => void;
}) {
  const visible = true;
  const displayedPages = stage === 'overview' ? pages.slice(0, 3) : pages.slice(3);
  const pageOffset = stage === 'overview' ? 0 : 3;
  const runtime = useAppRuntime();
  const { t, locale, isRtl } = useI18n();
  const theme = useCKTheme();
  const { reduceMotion } = useCKAccessibility();
  const { width } = useWindowDimensions();
  const pager = useRef<PagerViewHandle>(null);
  const finishing = useRef(false);
  const [page, setPage] = useState(0);
  const [busy, setBusy] = useState(false);
  const [failed, setFailed] = useState<MessageKey | null>(null);
  const [permissionDenied, setPermissionDenied] = useState(false);
  const [foreground, setForeground] = useState(AppState.currentState === 'active');
  useEffect(() => {
    const listener = AppState.addEventListener('change', (next) =>
      setForeground(next === 'active'),
    );
    return () => listener.remove();
  }, []);
  const finish = async (skip = false) => {
    if (finishing.current) return;
    finishing.current = true;
    setBusy(true);
    setFailed(null);
    try {
      await onboarding.finish(skip ? 'skipped' : 'completed');
      onComplete();
    } catch {
      setFailed('generalError');
    } finally {
      finishing.current = false;
      setBusy(false);
    }
  };
  const enableNotifications = async () => {
    if (finishing.current) return;
    finishing.current = true;
    setBusy(true);
    setFailed(null);
    try {
      if (permissionDenied) {
        await openSystemNotificationSettings();
        return;
      }
      // Request the system prompt from this explicit action. Registration does
      // not choose accounts or opt the user into war/upgrade reminder types.
      const result = await runtime.push.requestPermissionAndRegister();
      if (result.state === 'ready') {
        await onboarding.finish();
        onComplete();
      } else if (result.state === 'permissionDenied') {
        // iOS will not repeat a denied prompt. Offer Settings only after the
        // user makes another explicit choice; Not now always remains available.
        setPermissionDenied(true);
        setFailed('notifPushPermissionDenied');
      } else {
        const errors = {
          notConfigured: 'notifPushNotConfigured',
          tokenUnavailable: 'notifPushTokenUnavailable',
          permissionRequired: 'notifPushPermissionRequired',
          unsupported: 'notifPushUnsupported',
          initializing: 'notifPushInitializing',
        } as const;
        setFailed(errors[result.state]);
      }
    } catch {
      setFailed('generalError');
    } finally {
      finishing.current = false;
      setBusy(false);
    }
  };
  const select = (next: number) => {
    if (busy) return;
    if (reduceMotion) pager.current?.setPageWithoutAnimation(next);
    else pager.current?.setPage(next);
  };
  const finalPage = stage === 'notifications';
  useEffect(() => {
    const back = BackHandler.addEventListener('hardwareBackPress', () => {
      if (busy) return true;
      if (finalPage) onAccounts();
      else if (page > 0) {
        if (reduceMotion) pager.current?.setPageWithoutAnimation(page - 1);
        else pager.current?.setPage(page - 1);
      }
      return true;
    });
    return () => back.remove();
  }, [busy, finalPage, onAccounts, page, reduceMotion]);
  const supportsPush =
    runtime.appState.getState().isFeatureEnabled('notifications') &&
    runtime.push.supportsPushNotifications;
  const sceneWidth = Math.min(width, 480);
  return (
    <View style={[StyleSheet.absoluteFill, { backgroundColor: theme.background, zIndex: 20 }]}>
      <GestureHandlerRootView style={{ flex: 1 }}>
        <SafeAreaProvider initialMetrics={initialWindowMetrics}>
          <SafeAreaView
            style={[styles.root, { backgroundColor: theme.background }]}
            edges={['top', 'bottom', 'left', 'right']}
          >
            <View style={styles.top}>
              <Pressable
                disabled={(page === 0 && !finalPage) || busy}
                onPress={() => (finalPage ? onAccounts() : select(page - 1))}
                accessibilityRole="button"
                accessibilityLabel={materialBackLabel(locale)}
                style={[styles.back, { opacity: page === 0 && !finalPage ? 0 : 1 }]}
              >
                <ChevronLeft
                  color={theme.onSurface}
                  size={24}
                  style={isRtl ? { transform: [{ scaleX: -1 }] } : undefined}
                />
              </Pressable>
              <View style={styles.progress} accessible={false}>
                {pages.map((_, index) => (
                  <View
                    key={index}
                    style={[
                      styles.progressPart,
                      {
                        width: index === page + pageOffset ? 25 : 7,
                        backgroundColor:
                          index === page + pageOffset
                            ? onboardingAccents[page + pageOffset]
                            : colorWithAlpha(theme.onSurface, 0.17),
                      },
                    ]}
                  />
                ))}
              </View>
              <View style={styles.skip} />
            </View>
            <PagerView
              ref={pager}
              testID="onboarding-pager"
              style={{ flex: 1 }}
              initialPage={0}
              layoutDirection={isRtl ? 'rtl' : 'ltr'}
              overdrag={false}
              scrollEnabled={!busy}
              onPageSelected={(event) => {
                const next = event.nativeEvent.position;
                setPage(next);
                if (visible)
                  AccessibilityInfo.announceForAccessibility(t(displayedPages[next]!.title));
              }}
            >
              {displayedPages.map((item, index) => (
                <View
                  key={item.title}
                  collapsable={false}
                  style={{ flex: 1 }}
                  accessibilityElementsHidden={page !== index}
                  importantForAccessibility={page === index ? 'auto' : 'no-hide-descendants'}
                >
                  <ScrollView
                    bounces={false}
                    showsVerticalScrollIndicator={false}
                    contentContainerStyle={styles.scroll}
                  >
                    <OnboardingScene
                      index={index + pageOffset}
                      width={sceneWidth}
                      active={visible && foreground && page === index}
                      reduceMotion={reduceMotion}
                    />
                    <View style={styles.copy}>
                      <CKText
                        role="screenTitle"
                        skeleton={false}
                        style={[styles.title, { writingDirection: isRtl ? 'rtl' : 'ltr' }]}
                      >
                        {t(item.title)}
                      </CKText>
                      <CKText role="bodyLarge" muted skeleton={false} style={styles.body}>
                        {t(item.body)}
                      </CKText>
                    </View>
                    {index > 0 ? (
                      <CKText role="labelMedium" muted skeleton={false} style={styles.preview}>
                        {t('statsPreview')}
                      </CKText>
                    ) : null}
                  </ScrollView>
                </View>
              ))}
            </PagerView>
            <View style={styles.footer}>
              {failed ? (
                <CKText
                  accessibilityLiveRegion="polite"
                  muted
                  skeleton={false}
                  style={styles.error}
                >
                  {t(failed)}
                </CKText>
              ) : null}
              <Pressable
                testID="onboarding-next"
                disabled={busy}
                onPress={() =>
                  finalPage
                    ? supportsPush
                      ? void enableNotifications()
                      : void finish()
                    : page === 2
                      ? onAccounts()
                      : select(page + 1)
                }
                accessibilityRole="button"
                accessibilityState={{ disabled: busy, busy }}
                style={({ pressed }) => [
                  styles.primary,
                  { backgroundColor: theme.primary, opacity: busy ? 0.6 : pressed ? 0.85 : 1 },
                ]}
              >
                <CKText
                  role="bodyLarge"
                  skeleton={false}
                  style={{ color: theme.onPrimary, fontWeight: '700' }}
                >
                  {finalPage
                    ? supportsPush
                      ? t(permissionDenied ? 'notifSystemSettings' : 'onboardingSetupNotifications')
                      : t('homeDone')
                    : materialContinueLabel(locale)}
                </CKText>
              </Pressable>
              {finalPage ? (
                <Pressable
                  disabled={busy}
                  onPress={() => void finish(false)}
                  accessibilityRole="button"
                  style={styles.secondary}
                >
                  <CKText role="bodyMedium" muted skeleton={false}>
                    {t('notificationPrimerNotNow')}
                  </CKText>
                </Pressable>
              ) : (
                <View style={styles.secondary} />
              )}
            </View>
          </SafeAreaView>
        </SafeAreaProvider>
      </GestureHandlerRootView>
    </View>
  );
}
const styles = StyleSheet.create({
  root: { flex: 1 },
  top: {
    flexDirection: 'row',
    alignItems: 'center',
    height: 54,
    paddingHorizontal: 15,
    justifyContent: 'space-between',
  },
  back: { width: 70, height: 44, justifyContent: 'center', alignItems: 'flex-start' },
  skip: { minHeight: 44, minWidth: 70, alignItems: 'flex-end', justifyContent: 'center' },
  progress: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  progressPart: { height: 7, borderRadius: 5 },
  scroll: { flexGrow: 1, justifyContent: 'center', alignItems: 'center', paddingBottom: 8 },
  copy: { width: '100%', maxWidth: 448, paddingHorizontal: 29, marginTop: 12, gap: 15 },
  title: { fontSize: 34, lineHeight: 40, fontWeight: '700' },
  body: { fontSize: 16, lineHeight: 25 },
  preview: { marginTop: 18, opacity: 0.6 },
  footer: {
    paddingHorizontal: 27,
    paddingTop: 12,
    paddingBottom: 3,
    width: '100%',
    maxWidth: 488,
    alignSelf: 'center',
  },
  primary: {
    minHeight: 55,
    paddingHorizontal: 16,
    paddingVertical: 14,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 19,
  },
  secondary: { minHeight: 42, justifyContent: 'center', alignItems: 'center' },
  error: { textAlign: 'center', marginBottom: 8 },
});
