import { useEffect, useId, useMemo, useState } from 'react';
import { AppState, StyleSheet, View } from 'react-native';
import { useIsFocused } from '@react-navigation/native';
import Animated, {
  useAnimatedProps,
  useDerivedValue,
  useFrameCallback,
  useSharedValue,
} from 'react-native-reanimated';
import Svg, { Defs, FeGaussianBlur, Filter, G, Path, type PathProps } from 'react-native-svg';
import { useCKAccessibility } from '../../ui/accessibility';
import { useCKThemeMode } from '../../ui/theme';
import { ckRadius } from '../../ui/tokens';

const AnimatedPath = Animated.createAnimatedComponent(Path);
const bleed = 36;
type EdgePoint = { x: number; y: number; nx: number; ny: number };

// Sample each edge at the same density, including the round corners. A fixed
// point budget would stretch the electricity when the card changes size.
function perimeter(width: number, height: number): EdgePoint[] {
  if (width <= bleed * 2 || height <= bleed * 2) return [];
  const left = bleed;
  const top = bleed;
  const right = width - bleed;
  const bottom = height - bleed;
  const radius = Math.min(ckRadius.card, (right - left) / 2, (bottom - top) / 2);
  const points: EdgePoint[] = [];
  const line = (x: number, y: number, dx: number, dy: number, nx: number, ny: number) => {
    const count = Math.max(1, Math.ceil(Math.hypot(dx, dy) / 1.5));
    for (let i = 0; i < count; i++) {
      points.push({ x: x + (dx * i) / count, y: y + (dy * i) / count, nx, ny });
    }
  };
  const corner = (cx: number, cy: number, start: number) => {
    const count = Math.max(4, Math.ceil((Math.PI * radius) / 3));
    for (let i = 0; i < count; i++) {
      const angle = start + ((Math.PI / 2) * i) / count;
      const nx = Math.cos(angle),
        ny = Math.sin(angle);
      points.push({ x: cx + radius * nx, y: cy + radius * ny, nx, ny });
    }
  };
  line(left + radius, top, right - left - radius * 2, 0, 0, -1);
  corner(right - radius, top + radius, -Math.PI / 2);
  line(right, top + radius, 0, bottom - top - radius * 2, 1, 0);
  corner(right - radius, bottom - radius, 0);
  line(right - radius, bottom, -(right - left - radius * 2), 0, 0, 1);
  corner(left + radius, bottom - radius, Math.PI / 2);
  line(left, bottom - radius, 0, -(bottom - top - radius * 2), -1, 0);
  corner(left + radius, top + radius, Math.PI);
  return points;
}

function crackleNoise(point: number, tick: number): number {
  'worklet';
  const value = Math.sin(point * 127.1 + tick * 311.7) * 43758.5453;
  return (value - Math.floor(value)) * 2 - 1;
}

function spatialNoise(index: number, count: number, tick: number, spacing: number): number {
  'worklet';
  // Wrap the noise around the perimeter so the join has no visible seam.
  // Shared neighboring samples keep the subpixel shimmer spatially coherent.
  const cells = Math.max(2, Math.round(count / spacing));
  const position = (index / count) * cells;
  const cell = Math.floor(position),
    mix = position - cell;
  return crackleNoise(cell, tick) * (1 - mix) + crackleNoise((cell + 1) % cells, tick) * mix;
}

function rimOffset(index: number, count: number, time: number): number {
  'worklet';
  const tick = Math.floor(time * 12),
    mix = time * 12 - tick;
  return (
    (spatialNoise(index, count, tick, 8) * (1 - mix) +
      spatialNoise(index, count, tick + 1, 8) * mix) *
      0.65 +
    spatialNoise(index, count, Math.floor(time * 23), 2) * 0.12
  );
}

function rimPoint(point: EdgePoint, offset: number): string {
  'worklet';
  return `${(point.x + point.nx * offset).toFixed(2)},${(point.y + point.ny * offset).toFixed(2)}`;
}

function chargedPaths(points: readonly EdgePoint[], time: number, still: boolean) {
  'worklet';
  let main = '',
    hot = '',
    warm = '';
  const count = points.length;
  if (!count) return { main, hot, warm };
  const vertices: string[] = [];
  for (let i = 0; i < count; i++) {
    vertices.push(rimPoint(points[i]!, still ? 0 : rimOffset(i, count, time)));
    main += `${i === 0 ? 'M' : 'L'}${vertices[i]}`;
  }
  main += 'Z';
  if (still) return { main, hot, warm };
  // Match the reference's calm "Charged" pill: keep the rim continuous and
  // its geometry stable. Energy travels as small bright regions, not forks,
  // gaps, or large bends in the card silhouette.
  for (let i = 0; i < count; i += 5) {
    const progress = i / count;
    let energy = 0;
    for (let spot = 0; spot < 4; spot++) {
      const center = (spot * 0.251 + time * (0.019 + spot * 0.003)) % 1;
      const distance = Math.abs(progress - center);
      const wrapped = Math.min(distance, 1 - distance);
      const pulse = 0.75 + 0.25 * Math.sin(time * (2.3 + spot * 0.4) + spot * 2.1);
      energy += Math.exp(-Math.pow(wrapped / 0.035, 2)) * pulse;
    }
    let path = `M${vertices[i]}`;
    for (let j = 1; j <= 5; j++) path += `L${vertices[(i + j) % count]}`;
    if (energy > 0.55) hot += path;
    if (energy > 0.15) warm += path;
  }
  return { main, hot, warm };
}

export function SuperchargeBorder() {
  const { reduceMotion } = useCKAccessibility();
  const filterId = useId().replace(/:/g, '');
  const themeMode = useCKThemeMode();
  const focused = useIsFocused();
  const [foreground, setForeground] = useState(AppState.currentState === 'active');
  const [size, setSize] = useState({ width: 0, height: 0 });
  const points = useMemo(() => perimeter(size.width, size.height), [size.width, size.height]);
  const time = useSharedValue(0);
  const lastFrame = useSharedValue(0);

  useEffect(() => {
    const subscription = AppState.addEventListener('change', (state) => {
      setForeground(state === 'active');
    });
    return () => subscription.remove();
  }, []);

  const frame = useFrameCallback(({ timestamp }) => {
    if (lastFrame.value === 0) {
      lastFrame.value = timestamp;
      return;
    }
    const elapsed = timestamp - lastFrame.value;
    // Bound decorative path updates to 30 Hz on the UI thread. No React
    // state updates or damage calculations occur on animation frames.
    if (elapsed < 1000 / 30) return;
    time.value += Math.min(elapsed, 64) / 1000;
    lastFrame.value = timestamp;
  }, false);

  useEffect(() => {
    lastFrame.set(0);
    frame.setActive(foreground && focused && !reduceMotion && points.length > 0);
    return () => frame.setActive(false);
  }, [foreground, focused, reduceMotion, points.length, frame, lastFrame]);

  const paths = useDerivedValue(() => chargedPaths(points, time.value, reduceMotion));
  const outlineProps = useAnimatedProps<PathProps>(() => ({ d: paths.value.main }));
  const hotProps = useAnimatedProps<PathProps>(() => ({ d: paths.value.hot }));
  const warmProps = useAnimatedProps<PathProps>(() => ({ d: paths.value.warm }));

  const blue = themeMode === 'dark' ? '#62A0FF' : '#337EE5';
  return (
    <View
      pointerEvents="none"
      accessible={false}
      accessibilityElementsHidden
      importantForAccessibility="no-hide-descendants"
      testID="damage-supercharge-border"
      onLayout={({ nativeEvent: { layout } }) =>
        setSize((current) =>
          current.width === layout.width && current.height === layout.height
            ? current
            : { width: layout.width, height: layout.height },
        )
      }
      style={styles.overlay}
    >
      <Svg width={size.width} height={size.height}>
        <Defs>
          <Filter
            id={`${filterId}-bloom`}
            x="0"
            y="0"
            width={size.width}
            height={size.height}
            filterUnits="userSpaceOnUse"
          >
            <FeGaussianBlur stdDeviation={6} />
          </Filter>
          <Filter
            id={`${filterId}-halo`}
            x="0"
            y="0"
            width={size.width}
            height={size.height}
            filterUnits="userSpaceOnUse"
          >
            <FeGaussianBlur stdDeviation={1.3} />
          </Filter>
        </Defs>
        <G filter={`url(#${filterId}-bloom)`}>
          <AnimatedPath
            animatedProps={outlineProps}
            fill="none"
            stroke={blue}
            strokeWidth={9}
            opacity={0.85}
          />
          <AnimatedPath
            animatedProps={warmProps}
            fill="none"
            stroke={blue}
            strokeWidth={8}
            opacity={0.45}
          />
        </G>
        <G filter={`url(#${filterId}-halo)`}>
          <AnimatedPath
            animatedProps={outlineProps}
            fill="none"
            stroke="#75BBFF"
            strokeWidth={3}
            opacity={0.9}
          />
          <AnimatedPath
            animatedProps={hotProps}
            fill="none"
            stroke="#BDEAFF"
            strokeWidth={3.4}
            opacity={0.8}
          />
        </G>
        <AnimatedPath
          animatedProps={outlineProps}
          fill="none"
          stroke="#D8F1FF"
          strokeWidth={1.5}
          opacity={0.85}
          strokeLinejoin="round"
        />
        <AnimatedPath
          animatedProps={warmProps}
          fill="none"
          stroke="#E4F7FF"
          strokeWidth={1.6}
          opacity={0.8}
          strokeLinecap="round"
        />
        <AnimatedPath
          animatedProps={hotProps}
          fill="none"
          stroke="#F7FCFF"
          strokeWidth={1.85}
          strokeLinecap="round"
        />
      </Svg>
    </View>
  );
}

const styles = StyleSheet.create({
  // The halo stays outside layout and never covers a control's hit target.
  overlay: { position: 'absolute', inset: -bleed },
});
