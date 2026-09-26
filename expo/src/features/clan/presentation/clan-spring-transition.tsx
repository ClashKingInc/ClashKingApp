import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from 'react';
import {
  Animated,
  StyleSheet,
  View,
  useWindowDimensions,
  type LayoutRectangle,
} from 'react-native';
import { CKText } from '../../../ui/text';
import { MobileWebImage } from '../../../ui/mobile-web-image';
import { useCKTheme } from '../../../ui/theme';
import { useCKAccessibility } from '../../../ui/accessibility';

export type ClanSpringOrigin = {
  card: LayoutRectangle;
  badge: LayoutRectangle;
  name: LayoutRectangle;
  viewport: { width: number; height: number };
  badgeUrl: string;
  title: string;
};
type IdentityPart = 'badge' | 'name';
type Targets = Partial<Record<IdentityPart, LayoutRectangle>>;
export function validClanSpringOrigin(origin: ClanSpringOrigin, width: number, height: number) {
  return (
    origin.viewport.width === width &&
    origin.viewport.height === height &&
    [origin.card, origin.badge, origin.name].every(
      (rect) =>
        [rect.x, rect.y, rect.width, rect.height].every(Number.isFinite) &&
        rect.width > 0 &&
        rect.height > 0 &&
        rect.x >= 0 &&
        rect.y >= 0 &&
        rect.x + rect.width <= width + 1 &&
        rect.y + rect.height <= height + 1,
    )
  );
}
const IdentityContext = createContext<{
  active: boolean;
  register: (part: IdentityPart, rect: LayoutRectangle) => void;
} | null>(null);

/** Measure the real destination, and hide only that identity while its stand-in owns it. */
export function ClanSpringTarget({ part, children }: { part: IdentityPart; children: ReactNode }) {
  const context = useContext(IdentityContext);
  const ref = useRef<View>(null);
  const register = context?.register;
  return (
    <View
      ref={ref}
      collapsable={false}
      onLayout={() => {
        if (register)
          ref.current?.measureInWindow((x, y, width, height) =>
            register(part, { x, y, width, height }),
          );
      }}
      style={{ opacity: context?.active ? 0 : 1 }}
      testID={`clan-spring-target-${part}`}
    >
      {children}
    </View>
  );
}

/** One spring owns the surface and both identity elements. Content never waits for data. */
export function ClanSpringTransition({
  origin,
  children,
  onComplete,
}: {
  origin: ClanSpringOrigin;
  children: ReactNode;
  onComplete?: () => void;
}) {
  const { width, height, fontScale } = useWindowDimensions();
  const theme = useCKTheme();
  const { reduceMotion } = useCKAccessibility();
  const [progress] = useState(() => new Animated.Value(0));
  const [targets, setTargets] = useState<Targets>({});
  const [finished, setFinished] = useState(false);
  const ended = useRef(false);
  const complete = useRef(onComplete);
  useEffect(() => {
    complete.current = onComplete;
  }, [onComplete]);
  const enabled = !reduceMotion && fontScale <= 1.2 && validClanSpringOrigin(origin, width, height);
  const finish = useCallback(() => {
    if (ended.current) return;
    ended.current = true;
    progress.stopAnimation();
    progress.setValue(1);
    setFinished(true);
    complete.current?.();
  }, [progress]);
  const register = useCallback((part: IdentityPart, rect: LayoutRectangle) => {
    if (
      ended.current ||
      !Object.values(rect).every(Number.isFinite) ||
      rect.width <= 0 ||
      rect.height <= 0
    )
      return;
    setTargets((current) => (current[part] ? current : { ...current, [part]: rect }));
  }, []);
  const ready = !!targets.badge && !!targets.name;
  useEffect(() => {
    if (!enabled) {
      finish();
      return;
    }
    if (!ready) {
      // Inaccessible/unmeasurable layouts get a normal page, never an invisible wait.
      const timeout = setTimeout(finish, 120);
      return () => clearTimeout(timeout);
    }
    if (ended.current) return;
    const animation = Animated.spring(progress, {
      toValue: 1,
      stiffness: 240,
      damping: 29,
      mass: 0.85,
      overshootClamping: true,
      restDisplacementThreshold: 0.005,
      restSpeedThreshold: 0.005,
      useNativeDriver: true,
    });
    animation.start(({ finished: settled }) => {
      if (settled) finish();
    });
    return () => animation.stop();
  }, [enabled, ready, finish, progress]);
  const active = enabled && !finished;
  const context = useMemo(() => ({ active, register }), [active, register]);
  const move = (start: number, end: number) =>
    progress.interpolate({ inputRange: [0, 1], outputRange: [start, end], extrapolate: 'clamp' });
  const contentOpacity = progress.interpolate({
    inputRange: [0, 0.15, 0.7, 1],
    outputRange: [0, 0, 1, 1],
    extrapolate: 'clamp',
  });
  const identity = (part: IdentityPart, child: ReactNode) => {
    const source = origin[part];
    const target =
      targets[part] ??
      (part === 'name'
        ? {
            x: source.x + source.width / 2 - (source.width * 26) / 17 / 2,
            y: source.y + source.height / 2 - 13.5,
            width: (source.width * 26) / 17,
            height: 27,
          }
        : source);
    return (
      <Animated.View
        style={{
          position: 'absolute',
          left: target.x,
          top: target.y,
          width: target.width,
          height: target.height,
          transform: [
            { translateX: move(source.x + source.width / 2 - target.x - target.width / 2, 0) },
            { translateY: move(source.y + source.height / 2 - target.y - target.height / 2, 0) },
            { scale: move(part === 'badge' ? source.width / target.width : 17 / 26, 1) },
          ],
        }}
      >
        {child}
      </Animated.View>
    );
  };
  return (
    <IdentityContext.Provider value={context}>
      <View
        style={[styles.fill, { backgroundColor: theme.background }]}
        testID="clan-spring-transition"
        onTouchStart={finish}
      >
        {active ? (
          <Animated.View
            pointerEvents="none"
            style={[
              StyleSheet.absoluteFill,
              {
                backgroundColor: theme.card,
                borderRadius: 12,
                transform: [
                  { translateX: move(origin.card.x + origin.card.width / 2 - width / 2, 0) },
                  { translateY: move(origin.card.y + origin.card.height / 2 - height / 2, 0) },
                  { scaleX: move(origin.card.width / width, 1) },
                  { scaleY: move(origin.card.height / height, 1) },
                ],
              },
            ]}
          />
        ) : null}
        <Animated.View
          style={[
            styles.fill,
            { opacity: active ? contentOpacity : 1, backgroundColor: theme.background },
          ]}
        >
          {children}
        </Animated.View>
        {active ? (
          <View
            pointerEvents="none"
            accessibilityElementsHidden
            importantForAccessibility="no-hide-descendants"
            style={StyleSheet.absoluteFill}
          >
            {identity(
              'badge',
              <MobileWebImage
                imageUrl={origin.badgeUrl}
                displaySize={{ width: 94, height: 94 }}
                cachePolicy="memory-disk"
                transition={0}
                style={{ width: '100%', height: '100%' }}
              />,
            )}
            {identity(
              'name',
              <CKText
                numberOfLines={1}
                style={{
                  textAlign: 'center',
                  fontSize: 26,
                  lineHeight: 27,
                  fontWeight: '700',
                  color: '#FFF',
                }}
              >
                {origin.title}
              </CKText>,
            )}
          </View>
        ) : null}
      </View>
    </IdentityContext.Provider>
  );
}
const styles = StyleSheet.create({ fill: { flex: 1 } });
