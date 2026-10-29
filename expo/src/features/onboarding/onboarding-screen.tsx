import { useEffect, useRef, useState, useSyncExternalStore } from 'react';
import {
  AccessibilityInfo,
  Animated,
  AppState,
  Image,
  Modal,
  Pressable,
  ScrollView,
  StyleSheet,
  View,
  useWindowDimensions,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Bell, Check, ChevronLeft, Users, Shield } from 'lucide-react-native';
import { materialBackLabel, materialContinueLabel, useI18n } from '../../i18n';
import type { MessageKey } from '../../i18n/catalogs.generated';
import { CKText, ckRadius, ckSpacing, colorWithAlpha, useCKTheme } from '../../ui';
import { useCKAccessibility } from '../../ui/accessibility';
import { modalOrientations } from '../../ui/modal-orientations';
import { PagerView, type PagerViewHandle } from '../../ui/pager';
import { useStartupCovered } from '../../core/app/startup-loading';
import { useAppRuntime } from '../../core/app/runtime-context';
import { onboarding } from './onboarding-service';

const pages = [
  {
    title: 'onboardingOverviewTitle',
    body: 'onboardingOverviewBody',
    art: require('../../../assets/clashking/icons/startup-crown.png'),
  },
  {
    title: 'onboardingProgressTitle',
    body: 'onboardingProgressBody',
    art: require('../../../assets/clashking/cwl/legend.webp'),
  },
  {
    title: 'onboardingRemindersTitle',
    body: 'onboardingRemindersBody',
    art: require('../../../assets/clashking/icons/sword-cross.png'),
  },
] as const satisfies readonly { title: MessageKey; body: MessageKey; art: number }[];

export function OnboardingScreen({ eligible }: { eligible: boolean }) {
  const state = useSyncExternalStore(
    onboarding.subscribe,
    onboarding.getSnapshot,
    onboarding.getSnapshot,
  );
  const covered = useStartupCovered();
  useEffect(() => {
    onboarding.setEligible(eligible && !covered);
  }, [eligible, covered, state.ready]);
  return state.ready ? (
    <OnboardingContent key={state.presentation} visible={state.visible} />
  ) : null;
}

// Mount a fresh pager for each explicit introduction. No effect-driven reset
// or stale native page index can leak from a previous replay.
function OnboardingContent({ visible }: { visible: boolean }) {
  const runtime = useAppRuntime();
  const { t, locale, isRtl } = useI18n();
  const theme = useCKTheme();
  const { reduceMotion } = useCKAccessibility();
  const pager = useRef<PagerViewHandle>(null);
  const [page, setPage] = useState(0);
  const [busy, setBusy] = useState(false);
  const [failed, setFailed] = useState(false);
  const finish = async (skip: boolean) => {
    if (busy) return;
    setBusy(true);
    setFailed(false);
    try {
      await onboarding.finish(skip ? 'skipped' : 'completed');
    } catch {
      setFailed(true);
    } finally {
      setBusy(false);
    }
  };
  const advance = () => {
    if (page < pages.length - 1) {
      const next = page + 1;
      if (reduceMotion) pager.current?.setPageWithoutAnimation(next);
      else pager.current?.setPage(next);
      return;
    }
    void finish(false);
  };
  const allow = async () => {
    if (busy) return;
    setBusy(true);
    setFailed(false);
    try {
      // Permission grants delivery only. Account selection and alert types stay
      // in Settings; onboarding must never subscribe someone to alerts silently.
      await runtime.push.requestPermissionAndRegister();
      await onboarding.finish();
    } catch {
      setFailed(true);
    } finally {
      setBusy(false);
    }
  };
  const supportsPush =
    runtime.appState.getState().isFeatureEnabled('notifications') &&
    runtime.push.supportsPushNotifications;
  return (
    <Modal
      visible={visible}
      animationType={reduceMotion ? 'none' : 'fade'}
      presentationStyle="fullScreen"
      supportedOrientations={modalOrientations}
      onRequestClose={() => void finish(true)}
    >
      <SafeAreaView
        style={[styles.root, { backgroundColor: theme.background }]}
        edges={['top', 'bottom', 'left', 'right']}
      >
        <View style={styles.top}>
          <Pressable
            disabled={page === 0 || busy}
            onPress={() =>
              reduceMotion
                ? pager.current?.setPageWithoutAnimation(page - 1)
                : pager.current?.setPage(page - 1)
            }
            accessibilityLabel={materialBackLabel(locale)}
            accessibilityRole="button"
            style={[styles.back, { opacity: page === 0 ? 0 : 1 }]}
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
                    backgroundColor:
                      index === page ? theme.primary : colorWithAlpha(theme.onSurface, 0.12),
                  },
                ]}
              />
            ))}
          </View>
          {page < 2 ? (
            <Pressable
              disabled={busy}
              onPress={() => void finish(true)}
              accessibilityRole="button"
              style={styles.skip}
            >
              <CKText role="bodyMedium" muted skeleton={false}>
                {t('notificationPrimerNotNow')}
              </CKText>
            </Pressable>
          ) : (
            <View style={styles.skip} />
          )}
        </View>
        <PagerView
          ref={pager}
          style={styles.pager}
          initialPage={0}
          layoutDirection={isRtl ? 'rtl' : 'ltr'}
          overdrag={false}
          scrollEnabled={!busy}
          onPageSelected={(event) => setPage(event.nativeEvent.position)}
        >
          {pages.map((item, index) => (
            <View
              key={item.title}
              collapsable={false}
              style={styles.page}
              accessibilityElementsHidden={page !== index}
              importantForAccessibility={page === index ? 'auto' : 'no-hide-descendants'}
            >
              <IntroPage index={index} active={visible && page === index} />
            </View>
          ))}
        </PagerView>
        <View style={styles.footer}>
          {failed ? (
            <CKText accessibilityLiveRegion="polite" muted skeleton={false} style={styles.error}>
              {t('generalError')}
            </CKText>
          ) : null}
          <Pressable
            disabled={busy}
            onPress={page === 2 && supportsPush ? () => void allow() : advance}
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
              {page === 2
                ? supportsPush
                  ? t('notificationPrimerAllow')
                  : t('homeDone')
                : materialContinueLabel(locale)}
            </CKText>
          </Pressable>
          {page === 2 ? (
            <Pressable
              disabled={busy}
              onPress={() => void finish(true)}
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
    </Modal>
  );
}

function IntroPage({ index, active }: { index: number; active: boolean }) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const { height } = useWindowDimensions();
  const { reduceMotion } = useCKAccessibility();
  const [foreground, setForeground] = useState(AppState.currentState === 'active');
  const [entry] = useState(() => new Animated.Value(0));
  const item = pages[index]!;
  useEffect(() => {
    const subscription = AppState.addEventListener('change', (next) =>
      setForeground(next === 'active'),
    );
    return () => subscription.remove();
  }, []);
  useEffect(() => {
    const show = active && foreground;
    if (active) AccessibilityInfo.announceForAccessibility(t(item.title));
    if (!show || reduceMotion) {
      entry.setValue(show ? 1 : 0);
      return;
    }
    entry.setValue(0);
    const animation = Animated.timing(entry, { toValue: 1, duration: 360, useNativeDriver: true });
    animation.start();
    return () => animation.stop();
  }, [active, foreground, reduceMotion, entry, item.title, t]);
  const accent = index === 1 ? '#8D63D9' : index === 2 ? '#E8A524' : theme.primary;
  const stageHeight = Math.max(150, Math.min(height * 0.35, 310));
  return (
    <ScrollView
      bounces={false}
      showsVerticalScrollIndicator={false}
      contentContainerStyle={styles.scroll}
    >
      <View
        style={[styles.scene, { height: stageHeight }]}
        accessible={false}
        importantForAccessibility="no-hide-descendants"
        accessibilityElementsHidden
      >
        <View
          style={[
            styles.halo,
            {
              width: stageHeight * 0.82,
              height: stageHeight * 0.82,
              backgroundColor: colorWithAlpha(accent, 0.09),
            },
          ]}
        />
        <Animated.View
          style={{
            opacity: entry,
            transform: [
              {
                translateY: reduceMotion
                  ? 0
                  : entry.interpolate({ inputRange: [0, 1], outputRange: [16, 0] }),
              },
              {
                scale: reduceMotion
                  ? 1
                  : entry.interpolate({ inputRange: [0, 1], outputRange: [0.96, 1] }),
              },
            ],
          }}
        >
          <Image
            source={item.art}
            resizeMode="contain"
            style={{ width: stageHeight * 0.6, height: stageHeight * 0.6 }}
          />
        </Animated.View>
        {index === 0 ? (
          <>
            <View style={[styles.mini, styles.leading, { backgroundColor: theme.card }]}>
              <Users size={19} color={theme.onSurfaceVariant} />
              <CKText role="bodySmall" skeleton={false}>
                {t('searchTabPlayers')}
              </CKText>
            </View>
            <View style={[styles.mini, styles.trailing, { backgroundColor: theme.card }]}>
              <Shield size={19} color={theme.onSurfaceVariant} />
              <CKText role="bodySmall" skeleton={false}>
                {t('searchTabClans')}
              </CKText>
            </View>
          </>
        ) : index === 1 ? (
          <View style={[styles.mini, styles.progressPreview, { backgroundColor: theme.card }]}>
            <Check size={19} color={accent} />
            <CKText role="bodySmall" skeleton={false}>
              {t('notifGroupProgress')}
            </CKText>
            <View style={[styles.previewTrack, { backgroundColor: colorWithAlpha(accent, 0.13) }]}>
              <View style={[styles.previewFill, { backgroundColor: accent }]} />
            </View>
          </View>
        ) : (
          <View style={[styles.mini, styles.notification, { backgroundColor: theme.card }]}>
            <Bell size={23} color={accent} />
            <CKText role="bodyMedium" skeleton={false}>
              {t('notifGroupReminders')}
            </CKText>
          </View>
        )}
      </View>
      <View style={styles.copy}>
        <CKText role="screenTitle" skeleton={false} style={styles.title}>
          {t(item.title)}
        </CKText>
        <CKText role="bodyLarge" muted skeleton={false} style={styles.body}>
          {t(item.body)}
        </CKText>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  top: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    height: 56,
    justifyContent: 'space-between',
  },
  back: { width: 44, height: 44, justifyContent: 'center', alignItems: 'center' },
  skip: { minHeight: 44, minWidth: 70, alignItems: 'flex-end', justifyContent: 'center' },
  progress: { flexDirection: 'row', gap: 6 },
  progressPart: { height: 4, width: 22, borderRadius: 3 },
  pager: { flex: 1 },
  page: { flex: 1 },
  scroll: {
    flexGrow: 1,
    justifyContent: 'center',
    paddingHorizontal: ckSpacing.xl,
    paddingBottom: 12,
  },
  scene: {
    width: '100%',
    maxWidth: 460,
    alignSelf: 'center',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 20,
  },
  halo: { position: 'absolute', borderRadius: 999 },
  mini: {
    position: 'absolute',
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    padding: 15,
    borderRadius: ckRadius.tile,
  },
  leading: { left: '4%', bottom: '11%', transform: [{ rotate: '-5deg' }] },
  trailing: { right: '2%', top: '18%', transform: [{ rotate: '6deg' }] },
  progressPreview: { bottom: '6%', width: '82%', maxWidth: 350, justifyContent: 'center' },
  previewTrack: { width: 55, height: 6, borderRadius: 4 },
  previewFill: { width: '70%', height: 6, borderRadius: 4 },
  notification: { bottom: '9%', width: '76%', maxWidth: 330 },
  copy: { maxWidth: 440, width: '100%', alignSelf: 'center', gap: 14 },
  title: { textAlign: 'center', fontSize: 29, lineHeight: 35 },
  body: { textAlign: 'center', lineHeight: 25 },
  footer: {
    paddingHorizontal: 24,
    paddingTop: 12,
    paddingBottom: 8,
    width: '100%',
    maxWidth: 488,
    alignSelf: 'center',
  },
  primary: {
    minHeight: 54,
    paddingHorizontal: 20,
    paddingVertical: 14,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: ckRadius.control,
  },
  secondary: { minHeight: 46, justifyContent: 'center', alignItems: 'center' },
  error: { textAlign: 'center', marginBottom: 8 },
});
