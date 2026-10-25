import type { ViewInstance } from 'react-native';
import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState, type PropsWithChildren } from 'react';
import { Animated, AppState, Easing, Platform, Pressable, StyleSheet, View } from 'react-native';
import { Image } from 'expo-image';
import { captureRef, releaseCapture } from 'react-native-view-shot';
import { useCKAccessibility } from '../../ui';

// The bundled build cycle is 750ms. Keep the builder on the repair pose for
// three complete cycles before restoring the title and walking away.
const BUILD_START = 1250;
const BUILD_END = BUILD_START + 3 * 750;
const DURATION = BUILD_END + 700;
const HIT = 450 / DURATION;
const REPAIR_START = BUILD_END / DURATION;
const REPAIR_END = (BUILD_END + 250) / DURATION;
type Bounds = { x: number; y: number; width: number; height: number };
type Strike = Bounds & { image?: string; last: boolean; startX: number; startY: number; angle: string };
const Context = createContext<{
  attach: (node: ViewInstance | null) => void;
  launch: () => void;
  busy: boolean;
  retired: boolean;
  strike: Strike | null;
  clock: Animated.Value;
} | null>(null);

export function CalculatorTitleTarget({ children, label }: PropsWithChildren<{ label: string }>) {
  const context = useContext(Context);
  const opacity = context?.retired ? 0 : context?.strike ? context.clock.interpolate({ inputRange: [0, HIT, HIT + .025, REPAIR_START, REPAIR_END, 1], outputRange: [1, 1, 0, 0, context.strike.last ? 0 : 1, context.strike.last ? 0 : 1] }) : 1;
  return <Pressable accessibilityRole="button" accessibilityLabel={label} disabled={!context || context.busy || context.retired} onPress={context?.launch} hitSlop={8}>
    <Animated.View ref={context?.attach} collapsable={false} style={{ opacity }}>{children}</Animated.View>
  </Pressable>;
}

export function CalculatorFireballPlayground({ children, visible }: PropsWithChildren<{ visible: boolean }>) {
  const { reduceMotion } = useCKAccessibility();
  const root = useRef<ViewInstance>(null), title = useRef<ViewInstance | null>(null);
  const [clock] = useState(() => new Animated.Value(0));
  const [size, setSize] = useState({ width: 0, height: 0 });
  const [strike, setStrike] = useState<Strike | null>(null);
  const [busy, setBusy] = useState(false), [retired, setRetired] = useState(false);
  const [impact, setImpact] = useState(false), [working, setWorking] = useState(false), [leaving, setLeaving] = useState(false);
  const hits = useRef(0), running = useRef(false), mounted = useRef(true), run = useRef(0);
  const timers = useRef<ReturnType<typeof setTimeout>[]>([]);
  const snapshot = useRef<string | undefined>(undefined);
  const attach = useCallback((node: ViewInstance | null) => { title.current = node; }, []);
  const cancel = useCallback(() => {
    run.current++;
    timers.current.forEach(clearTimeout); timers.current = [];
    clock.stopAnimation(); clock.setValue(hits.current >= 3 ? 1 : 0); running.current = false;
    if (snapshot.current && Platform.OS !== 'web') releaseCapture(snapshot.current);
    snapshot.current = undefined;
    if (mounted.current) { setStrike(null); setBusy(false); setRetired(hits.current >= 3); setImpact(false); setWorking(false); setLeaving(false); }
  }, [clock]);
  useEffect(() => {
    mounted.current = true;
    const listener = AppState.addEventListener('change', state => { if (state !== 'active') cancel(); });
    return () => { mounted.current = false; listener.remove(); cancel(); };
  }, [cancel]);
  useEffect(() => { if (!visible || reduceMotion) { if (!visible) hits.current = 0; cancel(); } }, [visible, reduceMotion, cancel]);
  const launch = useCallback(async () => {
    if (running.current || hits.current >= 3 || reduceMotion || !root.current || !title.current) return;
    running.current = true; setBusy(true);
    const token = ++run.current;
    const node = title.current;
    const measure = (view: ViewInstance) => new Promise<Bounds>(resolve => view.measureInWindow((x, y, width, height) => resolve({ x, y, width, height })));
    const [outer, target] = await Promise.all([measure(root.current), measure(node)]);
    if (!mounted.current || token !== run.current) return;
    let image: string | undefined, timeout: ReturnType<typeof setTimeout> | undefined;
    try {
      let timedOut = false;
      const capture = captureRef(node, { format: 'png', quality: .85, result: Platform.OS === 'web' ? 'base64' : 'tmpfile', ...(Platform.OS === 'ios' ? { useRenderInContext: true } : {}) });
      void capture.then(uri => { if (timedOut && Platform.OS !== 'web') releaseCapture(uri); }, () => {});
      const captured = await Promise.race([capture, new Promise<never>((_, reject) => { timeout = setTimeout(() => { timedOut = true; reject(new Error('Title capture timeout')); }, 1200); })]);
      if (!mounted.current || token !== run.current) { if (Platform.OS !== 'web') releaseCapture(captured); return; }
      image = Platform.OS === 'web' ? `data:image/png;base64,${captured}` : captured;
      snapshot.current = image;
    } catch { /* The title must still return after a failed decorative capture. */ }
    finally { if (timeout) clearTimeout(timeout); }
    if (!mounted.current || token !== run.current) return;
    const x = target.x - outer.x, y = target.y - outer.y, cx = x + target.width / 2, cy = y + target.height / 2;
    const startX = outer.width + 70, startY = Math.max(0, cy - 70);
    const last = ++hits.current === 3;
    setStrike({ ...target, x, y, image, last, startX, startY, angle: `${Math.atan2(cy - startY, cx - startX) * 180 / Math.PI - 90}deg` });
    const later = (at: number, action: () => void) => timers.current.push(setTimeout(() => { if (mounted.current && token === run.current) action(); }, at));
    later(450, () => setImpact(true)); later(1700, () => setImpact(false));
    if (!last) { later(BUILD_START, () => setWorking(true)); later(BUILD_END, () => { setWorking(false); setLeaving(true); }); }
    // After the third accepted launch, the title stays absent until reopening.
    Animated.timing(clock, { toValue: 1, duration: DURATION, easing: Easing.linear, useNativeDriver: true }).start(({ finished }) => { if (finished && token === run.current) cancel(); });
  }, [cancel, clock, reduceMotion]);
  const context = useMemo(() => ({ attach, launch: () => { void launch(); }, busy: busy || reduceMotion, retired, strike, clock }), [attach, launch, busy, reduceMotion, retired, strike, clock]);
  const value = (inputRange: number[], outputRange: number[]) => clock.interpolate({ inputRange, outputRange, extrapolate: 'clamp' });
  const cx = strike ? strike.x + strike.width / 2 : 0, cy = strike ? strike.y + strike.height / 2 : 0;
  return <Context.Provider value={context}><View ref={root} collapsable={false} style={styles.stage} onLayout={({ nativeEvent: { layout } }) => setSize({ width: layout.width, height: layout.height })}>
    {children}
    {strike && visible && !reduceMotion ? <View pointerEvents="none" accessibilityElementsHidden importantForAccessibility="no-hide-descendants" style={StyleSheet.absoluteFill}>
      <Animated.View style={{ position: 'absolute', width: 74, height: 116, opacity: value([0, HIT - .005, HIT, 1], [1, 1, 0, 0]), transform: [
        { translateX: value([0, HIT, 1], [strike.startX - 37, cx - 37, cx - 37]) }, { translateY: value([0, HIT, 1], [strike.startY - 80, cy - 80, cy - 80]) }, { rotate: strike.angle },
      ] }}><Image source={require('../../../assets/clashking/calculators/fireball-flame-loop.webp')} autoplay contentFit="contain" transition={0} style={StyleSheet.absoluteFill} /></Animated.View>
      {impact ? <Image source={require('../../../assets/clashking/calculators/fireball-impact.webp')} autoplay contentFit="contain" transition={0} style={{ position: 'absolute', left: cx - 120, top: cy - 85, width: 240, height: 170 }} /> : null}
      {Array.from({ length: 20 }, (_, index) => {
        const col = index % 10, row = Math.floor(index / 10), width = strike.width / 10, height = strike.height / 2;
        const dx = (col - 4.5) * 5, dy = 20 + index * 7 % 22, angle = (index % 2 ? -1 : 1) * (15 + index * 3);
        const endX = strike.last ? dx : 0, endY = strike.last ? dy : 0, endAngle = strike.last ? `${angle}deg` : '0deg';
        return <Animated.View key={index} style={{ position: 'absolute', left: strike.x + col * width, top: strike.y + row * height, width, height, overflow: 'hidden', opacity: value([0, HIT, HIT + .02, REPAIR_START, REPAIR_END, 1], [0, 0, 1, 1, 0, 0]), transform: [
          { translateX: value([0, HIT, 950 / DURATION, REPAIR_START, REPAIR_END, 1], [0, 0, dx, dx, endX, endX]) }, { translateY: value([0, HIT, 650 / DURATION, 950 / DURATION, REPAIR_START, REPAIR_END, 1], [0, 0, -8, dy, dy, endY, endY]) }, { rotate: clock.interpolate({ inputRange: [0, HIT, 950 / DURATION, REPAIR_START, REPAIR_END, 1], outputRange: ['0deg', '0deg', `${angle}deg`, `${angle}deg`, endAngle, endAngle] }) },
        ] }}>{strike.image ? <Image source={{ uri: strike.image }} transition={0} contentFit="fill" style={{ position: 'absolute', left: -col * width, top: -row * height, width: strike.width, height: strike.height }} /> : <View style={{ flex: 1, backgroundColor: '#BBC7D7' }} />}</Animated.View>;
      })}
      {!strike.last ? <Animated.View style={{ position: 'absolute', top: Math.min(size.height - 80, strike.y + strike.height - 10), width: 76, height: 76, opacity: value([0, 650 / DURATION, 730 / DURATION, REPAIR_END, 1], [0, 0, 1, 1, 0]), transform: [{ translateX: value([0, 675 / DURATION, BUILD_START / DURATION, REPAIR_START, 1], [-80, -80, cx - 38, cx - 38, -80]) }, { scaleX: leaving ? -1 : 1 }] }}>
        <Image key={working ? 'build' : 'walk'} source={working ? require('../../../assets/clashking/calculators/builder-build.webp') : require('../../../assets/clashking/calculators/builder-walk.webp')} autoplay contentFit="contain" transition={0} style={StyleSheet.absoluteFill} />
      </Animated.View> : null}
    </View> : null}
  </View></Context.Provider>;
}
const styles = StyleSheet.create({ stage: { flex: 1, overflow: 'hidden' } });
