import {
  createContext,
  forwardRef,
  useCallback,
  useContext,
  useEffect,
  useImperativeHandle,
  useRef,
  useSyncExternalStore,
  type PropsWithChildren,
} from 'react';
import {
  AccessibilityInfo,
  Image,
  Platform,
  ScrollView,
  StyleSheet,
  View,
  type ScrollViewProps,
  type ViewProps,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { ArrowUp, Hand, MoveHorizontal } from 'lucide-react-native';
import { useI18n, materialContinueLabel } from '../../i18n';
import { CKText, PressableSurface, useCKTheme } from '../../ui';
import {
  tutorials,
  tutorialSteps,
  type TutorialId,
  type TutorialTargetId,
} from './tutorial-service';
import { tutorialCopy } from './tutorial-copy';

const RevealContext = createContext<(node: View) => void>(() => {});
const villagerPoses = {
  neutral: require('../../../assets/clashking/tutorials/villager.webp'),
  happy: require('../../../assets/clashking/tutorials/villager-happy.webp'),
  thinking: require('../../../assets/clashking/tutorials/villager-thinking.webp'),
};
const targetLabels: Partial<Record<TutorialTargetId, string>> = {
  'home-reorder': 'Hold, then drag',
  'sidebar-open': 'Tap your avatar',
  'clan-pages': 'Switch pages here',
  'notifications-permission': 'Device alerts',
  'notifications-entities': 'Choose a player or clan',
  'notifications-reminders': 'Set reminder times',
};
/** Scroll real content into view; the guide never simulates a tap or changes a setting. */
export const TutorialScrollView = forwardRef<ScrollView, ScrollViewProps>(
  function TutorialScrollView({ children, onScroll, ...props }, forwardedRef) {
    const ref = useRef<ScrollView>(null),
      offset = useRef(0);
    useImperativeHandle(forwardedRef, () => ref.current!);
    const reveal = useCallback((node: View) => {
      node.measureInWindow((_x, y) => {
        if (y > 260 || y < 70)
          ref.current?.scrollTo({ y: Math.max(0, offset.current + y - 160), animated: false });
      });
    }, []);
    return (
      <RevealContext.Provider value={reveal}>
        <ScrollView
          {...props}
          ref={ref}
          scrollEventThrottle={16}
          onScroll={(event) => {
            offset.current = event.nativeEvent.contentOffset.y;
            onScroll?.(event);
          }}
        >
          {children}
        </ScrollView>
      </RevealContext.Provider>
    );
  },
);

export function TutorialTarget({
  id,
  offer,
  enabled = true,
  children,
  ...props
}: PropsWithChildren<ViewProps & { id: TutorialTargetId; offer?: TutorialId; enabled?: boolean }>) {
  const ref = useRef<View>(null),
    reveal = useContext(RevealContext);
  const state = useSyncExternalStore(
    tutorials.subscribe,
    tutorials.getSnapshot,
    tutorials.getSnapshot,
  );
  useEffect(
    () =>
      enabled
        ? tutorials.registerTarget(id, {
            reveal: () => {
              if (ref.current) reveal(ref.current);
            },
          })
        : undefined,
    [id, reveal, enabled],
  );
  useEffect(() => {
    if (enabled && offer && state.ready) tutorials.offer(offer);
  }, [offer, state.ready, enabled]);
  const active =
    enabled && state.current && tutorialSteps[state.current][state.step]?.target === id;
  return (
    <View
      testID={`tutorial-target-${id}`}
      {...props}
      style={[props.style, active && styles.activeTarget]}
      ref={ref}
      collapsable={false}
    >
      {active && id === 'notifications-reminders' ? <TutorialOverlay inline /> : null}
      {children}
      {/* This cue is a child of the actual control: scrolling/sticky headers move it
        together with the target. Never measure a second screen-space rectangle. */}
      {active && (targetLabels[id] || id === 'bookmark') && id !== 'home-reorder' && id !== 'notifications-reminders' ? (
        <View
          pointerEvents="none"
          accessibilityElementsHidden
          importantForAccessibility="no-hide-descendants"
          style={[styles.targetCue, id === 'bookmark' ? styles.rightCue : styles.leftCue]}
        >
          <ArrowUp
            color="#F8D88F"
            strokeWidth={3}
            size={28}
            style={id === 'bookmark' ? { marginRight: 8 } : { marginLeft: 8 }}
          />
          {targetLabels[id] ? <View style={styles.cueLabel}>
            <CKText role="metadata" style={styles.cueText}>
              {targetLabels[id]}
            </CKText>
          </View> : null}
        </View>
      ) : null}
    </View>
  );
}

export function TutorialOverlay({ inline = false }: { inline?: boolean } = {}) {
  const state = useSyncExternalStore(
    tutorials.subscribe,
    tutorials.getSnapshot,
    tutorials.getSnapshot,
  );
  const { t, locale } = useI18n();
  const theme = useCKTheme(),
    insets = useSafeAreaInsets();
  const step = state.current ? tutorialSteps[state.current][state.step] : undefined;
  useEffect(() => {
    if (!step) return;
    if ((step.target === 'notifications-reminders') !== inline) return;
    const body =
      step.action === 'open-notifications' && Platform.OS === 'web'
        ? tutorialCopy.tutorialWebExploreBody
        : tutorialCopy[step.body];
    AccessibilityInfo.announceForAccessibility(`${tutorialCopy[step.title]}. ${body}`);
    if (step.target) tutorials.target(step.target)?.reveal();
  }, [step, t, state.revision, inline]);
  if (!step || !state.current) return null;
  if ((step.target === 'notifications-reminders') !== inline) return null;
  const pose =
    state.current === 'welcome' && (state.step === 0 || state.step === 3)
      ? 'happy'
      : state.current === 'notifications' || (state.current === 'clanGuide' && state.step === 1)
        ? 'thinking'
        : 'neutral';
  return (
    <View pointerEvents="box-none" style={inline ? styles.inlineGuide : styles.overlay} testID="tutorial-overlay">
      <View
        pointerEvents="box-none"
        style={inline ? undefined : [styles.guidePosition, { left: 14, right: 14, bottom: insets.bottom + 78 }]}
      >
        <View style={styles.guide}>
          <Image
            accessibilityIgnoresInvertColors
            source={villagerPoses[pose]}
            resizeMode="contain"
            style={styles.villager}
          />
          <View style={[styles.dialogue, { backgroundColor: '#FFF4DC' }]}>
            <CKText role="metadata" style={styles.counter}>
              {state.step + 1} / {tutorialSteps[state.current].length}
            </CKText>
            <CKText role="titleSmall" style={styles.title}>
              {tutorialCopy[step.title]}
            </CKText>
            {step.target === 'home-reorder' ? (
              <View style={styles.cueLabel}>
                <Hand color="#4E3D27" size={18} />
                <MoveHorizontal color="#4E3D27" size={16} />
                <CKText role="metadata" style={styles.cueText}>
                  {targetLabels['home-reorder']}
                </CKText>
              </View>
            ) : null}
            <CKText role="body" style={styles.body}>
              {step.action === 'open-notifications' && Platform.OS === 'web'
                ? tutorialCopy.tutorialWebExploreBody
                : tutorialCopy[step.body]}
            </CKText>
            <View style={styles.actions}>
              <PressableSurface
                testID="tutorial-skip"
                accessibilityRole="button"
                accessibilityLabel={tutorialCopy.tutorialNotNow}
                onPress={tutorials.dismiss}
                style={styles.skip}
              >
                <CKText role="bodySmall" style={{ color: '#69563D' }}>
                  {tutorialCopy.tutorialNotNow}
                </CKText>
              </PressableSurface>
              <PressableSurface
                testID="tutorial-next"
                accessibilityRole="button"
                onPress={tutorials.next}
                style={[styles.next, { backgroundColor: theme.secondary }]}
              >
                <CKText role="labelLarge" style={{ color: '#FFFFFF' }}>
                  {step.action === 'open-notifications'
                    ? Platform.OS === 'web'
                      ? tutorialCopy.tutorialExampleClan
                      : t('settingsNotificationsTitle')
                    : materialContinueLabel(locale)}
                </CKText>
              </PressableSurface>
            </View>
          </View>
        </View>
      </View>
    </View>
  );
}
const styles = StyleSheet.create({
  inlineGuide: { marginBottom: 20 },
  overlay: {
    position: 'absolute',
    top: 0,
    right: 0,
    bottom: 0,
    left: 0,
    zIndex: 10000,
    elevation: 100,
  },
  activeTarget: { zIndex: 50 },
  targetCue: { position: 'absolute', zIndex: 51 },
  leftCue: { top: '100%', left: 8, alignItems: 'flex-start' },
  rightCue: { top: '100%', right: 0, alignItems: 'flex-end' },
  cueLabel: {
    backgroundColor: '#FFF4DC',
    borderRadius: 10,
    paddingHorizontal: 9,
    paddingVertical: 5,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  cueText: { color: '#4E3D27', fontSize: 12, fontWeight: '700' },
  guidePosition: { position: 'absolute', maxWidth: 560, alignSelf: 'center' },
  guide: { flexDirection: 'row', alignItems: 'flex-end' },
  villager: { width: 84, height: 154, marginRight: -4, zIndex: 1 },
  dialogue: {
    flex: 1,
    borderRadius: 20,
    borderBottomLeftRadius: 5,
    padding: 16,
    gap: 7,
    borderWidth: 2,
    borderColor: '#B99A64',
    shadowColor: '#000',
    shadowOpacity: 0.2,
    shadowRadius: 16,
    shadowOffset: { width: 0, height: 4 },
  },
  counter: { color: '#8C6B37', fontSize: 10 },
  title: { color: '#3E2B16', fontWeight: '700' },
  body: { color: '#4E3D27', fontSize: 13, lineHeight: 19 },
  actions: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    gap: 8,
    marginTop: 3,
  },
  skip: {
    backgroundColor: 'transparent',
    borderWidth: 0,
    paddingHorizontal: 2,
    minHeight: 44,
    justifyContent: 'center',
  },
  next: {
    borderWidth: 0,
    paddingHorizontal: 14,
    paddingVertical: 10,
    minHeight: 44,
    justifyContent: 'center',
  },
});
