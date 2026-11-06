import { useAvatarNames } from './avatar-names';
import { memo, useEffect, useId, useRef, useState } from 'react';
import {
  FlatList,
  Modal,
  Pressable,
  ScrollView,
  StyleSheet,
  View,
  useWindowDimensions,
} from 'react-native';
import Animated, {
  FadeIn,
  FadeOut,
  useSharedValue,
  useAnimatedScrollHandler,
  useAnimatedReaction,
  runOnJS,
  useAnimatedStyle,
  withTiming,
  type SharedValue,
} from 'react-native-reanimated';
import Svg, { Defs, LinearGradient, RadialGradient, Rect, Stop } from 'react-native-svg';
import { useCKThemeMode } from '../../ui/theme';
import { ChevronLeft, Pencil } from 'lucide-react-native';
import {
  SafeAreaProvider,
  SafeAreaView,
  initialWindowMetrics,
} from 'react-native-safe-area-context';
import { materialBackLabel, materialContinueLabel, useI18n } from '../../i18n';
import { CKText, useCKTheme } from '../../ui';
import { modalOrientations } from '../../ui/modal-orientations';
import { ClashAvatar, ProfileAvatar } from './clash-avatar';
import { useAvatarPreference } from './avatar-preference';
import catalog from './catalog.json';
import { useCKAccessibility } from '../../ui/accessibility';

export function AvatarPicker({
  onContinue,
  onBack,
}: {
  onContinue: () => void;
  onBack: () => void;
}) {
  const names = useAvatarNames();
  const { id, save, ready, failed: loadFailed, reload } = useAvatarPreference();
  const [selection, setChoice] = useState<string | null>(null);
  const choice = selection ?? id;
  const [selectionReaction, setSelectionReaction] = useState({ id: '', sequence: 0 });
  const [busy, setBusy] = useState(false),
    [failed, setFailed] = useState(false);
  const { t, locale, isRtl } = useI18n();
  const theme = useCKTheme();
  const { reduceMotion } = useCKAccessibility();
  const { width, height } = useWindowDimensions();
  const itemWidth = Math.min(width * 0.64, 300);
  const look = useSharedValue(0);
  const progress = useSharedValue(0);
  const offset = useSharedValue(0);
  const scrollingOnUI = useSharedValue(false);
  const contextDirection = useSharedValue(0);
  const slider = useRef<FlatList<(typeof catalog)[number]>>(null);
  const [rowWidth, setRowWidth] = useState(width);
  const moving = useRef(false),
    draggingRow = useRef(false);
  const tapBlocked = useRef(false),
    pressMoved = useRef(false);
  const pressStart = useRef({ x: 0, y: 0 });
  const settleTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const unblockTapTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const [scrolling, setScrolling] = useState(false);
  const clearSettle = () => {
    if (settleTimer.current !== null) clearTimeout(settleTimer.current);
    settleTimer.current = null;
  };
  const settle = () => {
    clearSettle();
    if (!moving.current || draggingRow.current) return;
    moving.current = false;
    setScrolling(false);
    tapBlocked.current = true;
    if (unblockTapTimer.current !== null) clearTimeout(unblockTapTimer.current);
    unblockTapTimer.current = setTimeout(() => {
      tapBlocked.current = false;
    }, 180);
    scrollingOnUI.set(false);
    look.set(reduceMotion ? 0 : withTiming(0, { duration: 550 }));
    const index = Math.max(0, Math.min(catalog.length - 1, Math.round(offset.get() / itemWidth)));
    setChoice(catalog[index]!.id);
    // Celebrate a completed gesture, not every character passed during a fling
    // or the initial restoration of the account's saved avatar.
    setSelectionReaction((previous) => ({
      id: catalog[index]!.id,
      sequence: previous.sequence + 1,
    }));
  };
  const scheduleSettle = () => {
    clearSettle();
    const previous = offset.get();
    settleTimer.current = setTimeout(() => {
      // Some native programmatic/no-momentum scrolls omit momentum-end. Poll
      // only while settling; never send every scroll frame through JS/timers.
      if (Math.abs(offset.get() - previous) > 0.5) scheduleSettle();
      else settle();
    }, 180);
  };
  // Native scrolling owns the row. Selection never starts another scroll after
  // a swipe settles, which would fight inertia and cause the previous jumping.
  useEffect(() => {
    if (ready && selection === null && !moving.current) {
      const index = Math.max(
        0,
        catalog.findIndex((a) => a.id === id),
      );
      slider.current?.scrollToOffset({ offset: index * itemWidth, animated: false });
      offset.set(index * itemWidth);
      progress.set(index);
    }
  }, [id, ready, rowWidth, selection, itemWidth, progress, offset]);
  useEffect(
    () => () => {
      if (settleTimer.current !== null) clearTimeout(settleTimer.current);
      if (unblockTapTimer.current !== null) clearTimeout(unblockTapTimer.current);
    },
    [],
  );
  const scrollHandler = useAnimatedScrollHandler({
    onScroll: (event) => {
      const next = Math.abs(event.contentOffset.x);
      const delta = next - offset.value;
      offset.set(next);
      progress.set(next / itemWidth);
      if (scrollingOnUI.value && Math.abs(delta) > 0.1) {
        const direction = Math.sign(delta) * 0.7 * (isRtl ? -1 : 1);
        // Start a glance on direction changes, not a new timing animation on
        // every frame. Native scrolling and scale never wait for React/JS.
        const target = reduceMotion ? direction * 0.4 : direction;
        if (direction !== contextDirection.value) {
          contextDirection.set(direction);
          look.set(reduceMotion ? target : withTiming(target, { duration: 180 }));
        }
      }
    },
  });
  const size = Math.min(width - 32, height < 700 ? 250 : 350);
  return (
    <SafeAreaView
      edges={['top', 'bottom', 'left', 'right']}
      style={{ flex: 1, backgroundColor: theme.background }}
    >
      <CharacterBackdrop key={choice} id={choice} reduced={reduceMotion} />
      <View style={styles.top}>
        <Pressable
          disabled={busy}
          onPress={onBack}
          accessibilityRole="button"
          accessibilityLabel={materialBackLabel(locale)}
          style={({ pressed }) => [styles.back, { opacity: pressed ? 0.55 : 1 }]}
        >
          <ChevronLeft
            size={26}
            color={theme.onSurface}
            style={isRtl ? { transform: [{ scaleX: -1 }] } : undefined}
          />
        </Pressable>
      </View>
      <ScrollView bounces={false} contentContainerStyle={styles.body}>
        <CKText role="bodyMedium" muted style={{ marginBottom: 12 }}>
          {t('avatarPickerTitle')}
        </CKText>
        <View
          style={styles.slider}
          onLayout={(event) => setRowWidth(event.nativeEvent.layout.width)}
        >
          <Animated.FlatList
            ref={slider}
            horizontal
            removeClippedSubviews={false}
            initialNumToRender={3}
            maxToRenderPerBatch={3}
            windowSize={5}
            scrollEnabled={ready && !busy}
            inverted={isRtl}
            data={catalog}
            keyExtractor={(item) => item.id}
            showsHorizontalScrollIndicator={false}
            scrollEventThrottle={16}
            onScrollBeginDrag={() => {
              clearSettle();
              moving.current = true;
              draggingRow.current = true;
              scrollingOnUI.set(true);
              contextDirection.set(0);
              tapBlocked.current = true;
              pressMoved.current = true;
              setScrolling(true);
            }}
            onScroll={scrollHandler}
            onScrollEndDrag={() => {
              draggingRow.current = false;
              scheduleSettle();
            }}
            onMomentumScrollBegin={() => {
              moving.current = true;
              setScrolling(true);
              scheduleSettle();
            }}
            snapToInterval={itemWidth}
            decelerationRate="fast"
            contentContainerStyle={{
              paddingHorizontal: Math.max(0, (rowWidth - itemWidth) / 2),
              paddingVertical: 14,
            }}
            getItemLayout={(_, i) => ({ length: itemWidth, offset: itemWidth * i, index: i })}
            onMomentumScrollEnd={(event) => {
              offset.set(Math.abs(event.nativeEvent.contentOffset.x));
              settle();
            }}
            renderItem={({ item, index }) => (
              <CarouselFace
                index={index}
                progress={progress}
                width={itemWidth}
                reduced={reduceMotion}
              >
                <Pressable
                  disabled={busy || !ready}
                  onPressIn={(event) => {
                    pressMoved.current = false;
                    pressStart.current = { x: event.nativeEvent.pageX, y: event.nativeEvent.pageY };
                  }}
                  onTouchMove={(event) => {
                    if (
                      Math.hypot(
                        event.nativeEvent.pageX - pressStart.current.x,
                        event.nativeEvent.pageY - pressStart.current.y,
                      ) > 8
                    )
                      pressMoved.current = true;
                  }}
                  onPress={() => {
                    if (pressMoved.current || moving.current || tapBlocked.current) return;
                    if (item.id === choice) return;
                    setChoice(item.id);
                    const index = catalog.findIndex((a) => a.id === item.id);
                    moving.current = true;
                    scrollingOnUI.set(true);
                    contextDirection.set(0);
                    if (reduceMotion) offset.set(index * itemWidth);
                    setScrolling(true);
                    slider.current?.scrollToOffset({
                      offset: index * itemWidth,
                      animated: !reduceMotion,
                    });
                    scheduleSettle();
                  }}
                  accessibilityRole="button"
                  accessibilityLabel={names[item.id]}
                  accessibilityState={{ selected: item.id === choice }}
                  style={({ pressed }) => ({
                    alignItems: 'center',
                    width: itemWidth,
                    paddingVertical: 20,
                    opacity: pressed ? 0.85 : 1,
                  })}
                >
                  <ClashAvatar
                    id={item.id}
                    size={size}
                    lookX={look}
                    carouselProgress={progress}
                    carouselIndex={index}
                    carouselScrolling={scrollingOnUI}
                    selectionPulse={
                      selectionReaction.id === item.id ? selectionReaction.sequence : 0
                    }
                    interactive={item.id === choice}
                    allowTouch={false}
                    observeTouch={item.id === choice && ready && !busy}
                  />
                </Pressable>
              </CarouselFace>
            )}
          />
        </View>
        <CarouselCaption progress={progress} initialId={choice} />
        {failed || loadFailed ? (
          <CKText accessibilityLiveRegion="polite">{t('generalError')}</CKText>
        ) : null}
        {loadFailed ? (
          <Pressable
            accessibilityRole="button"
            onPress={() => void reload()}
            style={{ padding: 12 }}
          >
            <CKText>{t('generalRetry')}</CKText>
          </Pressable>
        ) : null}
      </ScrollView>
      <View style={styles.footer}>
        <Pressable
          disabled={busy || !ready || scrolling}
          onPress={() => {
            setBusy(true);
            setFailed(false);
            void save(choice)
              .then(onContinue)
              .catch(() => setFailed(true))
              .finally(() => setBusy(false));
          }}
          accessibilityRole="button"
          accessibilityState={{ busy, disabled: busy || !ready || scrolling }}
          style={({ pressed }) => [
            styles.continue,
            {
              backgroundColor: theme.primary,
              opacity: busy || !ready || scrolling ? 0.5 : pressed ? 0.85 : 1,
            },
          ]}
        >
          <CKText role="bodyLarge" style={{ color: theme.onPrimary, fontWeight: '700' }}>
            {materialContinueLabel(locale)}
          </CKText>
        </Pressable>
      </View>
    </SafeAreaView>
  );
}
export function SettingsAvatar() {
  const { reduceMotion } = useCKAccessibility();
  const [open, setOpen] = useState(false);
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <View style={{ alignItems: 'center', width: 144, height: 144 }}>
      <ProfileAvatar size={144} interactive={!open} />
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={t('profileAvatar')}
        onPress={() => setOpen(true)}
        style={({ pressed }) => ({
          position: 'absolute',
          right: 0,
          bottom: 0,
          width: 40,
          height: 40,
          borderRadius: 20,
          alignItems: 'center',
          justifyContent: 'center',
          backgroundColor: theme.surfaceContainerHighest,
          borderWidth: 3,
          borderColor: theme.background,
          opacity: pressed ? 0.7 : 1,
        })}
      >
        <Pencil size={18} color={theme.onSurface} />
      </Pressable>
      <Modal
        visible={open}
        onRequestClose={() => setOpen(false)}
        supportedOrientations={modalOrientations}
        presentationStyle="fullScreen"
        animationType={reduceMotion ? 'none' : 'slide'}
      >
        {/* A native modal needs its own inset measurement; the Settings screen's
            provider describes the underlying route, not this presentation. */}
        <SafeAreaProvider initialMetrics={initialWindowMetrics}>
          <AvatarPicker onBack={() => setOpen(false)} onContinue={() => setOpen(false)} />
        </SafeAreaProvider>
      </Modal>
    </View>
  );
}
const styles = StyleSheet.create({
  top: { paddingHorizontal: 16, paddingTop: 6 },
  back: { width: 48, height: 48, alignItems: 'center', justifyContent: 'center' },
  body: { flexGrow: 1, alignItems: 'center', justifyContent: 'center', paddingBottom: 8 },
  title: { textAlign: 'center', paddingHorizontal: 24 },
  name: { textAlign: 'center', fontWeight: '700' },
  slider: { width: '100%', marginTop: 12 },
  option: {
    width: 92,
    height: 92,
    borderRadius: 30,
    borderWidth: 2,
    alignItems: 'center',
    justifyContent: 'center',
  },
  check: {
    position: 'absolute',
    right: 0,
    bottom: 0,
    width: 22,
    height: 22,
    borderRadius: 11,
    alignItems: 'center',
    justifyContent: 'center',
  },
  footer: { paddingHorizontal: 24, paddingTop: 8, paddingBottom: 16 },
  continue: {
    minHeight: 56,
    borderRadius: 18,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 16,
  },
});

const characterColors: Record<string, readonly [string, string]> = {
  barbarian: ['#F4C65B', '#E58B52'],
  archer: ['#DF83B4', '#A9C16B'],
  goblin: ['#A5CF65', '#E6C474'],
  giant: ['#E8A769', '#D78C79'],
  wizard: ['#7399DC', '#A08ACA'],
  'hog-rider': ['#CB8E86', '#C4A375'],
  valkyrie: ['#E89465', '#CE6C89'],
  'barbarian-king': ['#E4BC61', '#A58ACC'],
  'archer-queen': ['#AA89D5', '#70B397'],
  'royal-champion': ['#6AB8C5', '#8995D2'],
  'minion-prince': ['#799CE3', '#AA84D3'],
};
const CharacterBackdrop = memo(function CharacterBackdrop({
  id,
  reduced,
}: {
  id: string;
  reduced: boolean;
}) {
  const dark = useCKThemeMode() === 'dark';
  const key = useId().replace(/:/g, '');
  const [first, second] = characterColors[id] ?? characterColors.barbarian!;
  return (
    <Animated.View
      pointerEvents="none"
      accessible={false}
      style={StyleSheet.absoluteFill}
      entering={reduced ? undefined : FadeIn.duration(420)}
      exiting={reduced ? undefined : FadeOut.duration(420)}
    >
      <Svg width="100%" height="100%" preserveAspectRatio="none" viewBox="0 0 100 100">
        <Defs>
          <LinearGradient id={key + 'wash'} x1="0%" y1="0%" x2="90%" y2="100%">
            <Stop offset="0" stopColor={first} stopOpacity={dark ? 0.2 : 0.3} />
            <Stop offset=".7" stopColor={second} stopOpacity={dark ? 0.12 : 0.18} />
            <Stop offset="1" stopColor={second} stopOpacity="0" />
          </LinearGradient>
          <RadialGradient id={key + 'glow'} cx="50%" cy="36%" rx="62%" ry="45%">
            <Stop offset="0" stopColor={first} stopOpacity={dark ? 0.2 : 0.3} />
            <Stop offset="1" stopColor={first} stopOpacity="0" />
          </RadialGradient>
        </Defs>
        <Rect width="100" height="100" fill={'url(#' + key + 'wash)'} />
        <Rect width="100" height="100" fill={'url(#' + key + 'glow)'} />
      </Svg>
    </Animated.View>
  );
});

function CarouselFace({
  index,
  progress,
  width,
  reduced,
  children,
}: {
  index: number;
  progress: SharedValue<number>;
  width: number;
  reduced: boolean;
  children: React.ReactNode;
}) {
  const motion = useAnimatedStyle(() => {
    const distance = Math.min(1, Math.abs(progress.value - index));
    return {
      opacity: 1 - distance * 0.42,
      transform: [{ scale: reduced ? 1 : 1 - distance * 0.19 }],
    };
  });
  return (
    <Animated.View style={[{ width, alignItems: 'center', justifyContent: 'center' }, motion]}>
      {children}
    </Animated.View>
  );
}

// Only the caption rerenders when the nearest character changes. Scrolling must
// not rebuild the list or its SVGs, and the name should not wait for inertia to end.
const CarouselCaption = memo(function CarouselCaption({
  progress,
  initialId,
}: {
  progress: SharedValue<number>;
  initialId: string;
}) {
  const names = useAvatarNames();
  const theme = useCKTheme();
  const [index, setIndex] = useState(() =>
    Math.max(
      0,
      catalog.findIndex((a) => a.id === initialId),
    ),
  );
  useAnimatedReaction(
    () => Math.max(0, Math.min(catalog.length - 1, Math.round(progress.value))),
    (next, previous) => {
      if (next !== previous) runOnJS(setIndex)(next);
    },
  );
  return (
    <>
      <CKText role="titleLarge" style={[styles.name, { marginTop: 12 }]}>
        {names[catalog[index]!.id]}
      </CKText>
      <View
        style={{
          flexDirection: 'row',
          gap: 6,
          alignItems: 'center',
          marginTop: 18,
          marginBottom: 12,
        }}
        accessible={false}
      >
        {catalog.map((a, i) => (
          <View
            key={a.id}
            style={{
              width: i === index ? 20 : 5,
              height: 5,
              borderRadius: 3,
              backgroundColor: i === index ? theme.primary : theme.outlineVariant,
            }}
          />
        ))}
      </View>
    </>
  );
});
