import { useCallback, useMemo, useState, type ReactNode } from 'react';
import { requireNativeView } from 'expo';
import ClashKingNative from '@clashking/native';
import {
  StyleSheet,
  View,
  type NativeSyntheticEvent,
  type StyleProp,
  type ViewStyle,
} from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { isDuoDevice } from './adaptive-layout';
import { AdaptiveViewportContext } from './adaptive-viewport';

type Rect = { x: number; y: number; width: number; height: number };
type Region = Rect & { kind: 'division' | 'occlusion' };
type Measurement = {
  width: number;
  height: number;
  safeArea: { top: number; right: number; bottom: number; left: number };
  regions: Region[];
};
type ObserverProps = {
  style: StyleProp<ViewStyle>;
  pointerEvents: 'none';
  onReservedRegionsChange: (event: NativeSyntheticEvent<Measurement>) => void;
};

// Do not resolve an unregistered view on Android, an ordinary iPhone, or an
// older installed binary. Only the rebuilt Duo binary needs this observer.
const Observer =
  isDuoDevice && ClashKingNative.supportsReservedRegionObservation === true
    ? requireNativeView<ObserverProps>('ClashKingNative', 'ReservedRegionObserverView')
    : null;

/** Place this inside a native page or custom modal, never around its navigator.
 * A partial fold keeps both display halves available. Native navigation remains
 * outside and keeps its system-owned geometry; actual occlusions still clear. */
export function ReservedRegionLayout({
  children,
  style,
  testID,
}: {
  children: ReactNode;
  style?: StyleProp<ViewStyle>;
  testID?: string;
}) {
  return Observer ? (
    <ObservedLayout style={style} testID={testID}>
      {children}
    </ObservedLayout>
  ) : (
    <>{children}</>
  );
}

function ObservedLayout({
  children,
  style,
  testID,
}: {
  children: ReactNode;
  style?: StyleProp<ViewStyle>;
  testID?: string;
}) {
  const [size, setSize] = useState({ width: 0, height: 0 });
  const [measurement, setMeasurement] = useState<(Measurement & { pane: Rect }) | null>(null);
  const onRegions = useCallback((event: NativeSyntheticEvent<Measurement>) => {
    const next = event.nativeEvent;
    if (!(next.width > 0 && next.height > 0)) return;
    setMeasurement((previous) => ({ ...next, pane: clearPane(next, previous?.pane) }));
  }, []);
  // An event from the old display can arrive after the host has resized. Wait
  // for matching native geometry instead of constraining the new display to it.
  const current =
    measurement &&
    Math.abs(measurement.width - size.width) < 1 &&
    Math.abs(measurement.height - size.height) < 1
      ? measurement
      : null;
  const full = { x: 0, y: 0, ...size };
  const pane = current?.pane ?? full;
  const constrained =
    pane.x > 0.5 ||
    pane.y > 0.5 ||
    pane.width < size.width - 0.5 ||
    pane.height < size.height - 0.5;
  const contentWidth = pane.width;
  const contentHeight = pane.height;
  const viewport = useMemo(
    () =>
      contentWidth > 0 && contentHeight > 0
        ? { width: contentWidth, height: contentHeight, constrained }
        : null,
    [contentWidth, contentHeight, constrained],
  );
  return (
    <View
      testID={testID}
      style={[styles.host, style]}
      onLayout={({ nativeEvent: { layout } }) => {
        setSize((previous) =>
          previous.width === layout.width && previous.height === layout.height
            ? previous
            : { width: layout.width, height: layout.height },
        );
      }}
    >
      {Observer ? (
        <Observer
          pointerEvents="none"
          style={StyleSheet.absoluteFill}
          onReservedRegionsChange={onRegions}
        />
      ) : null}
      <AdaptiveViewportContext.Provider value={viewport}>
        {/* This native provider recalculates safe insets for the chosen pane.
            A left pane must not inherit the opposite edge's rail padding. */}
        <SafeAreaProvider
          style={
            constrained
              ? [styles.pane, { left: pane.x, top: pane.y, width: pane.width, height: pane.height }]
              : styles.fill
          }
        >
          {children}
        </SafeAreaProvider>
      </AdaptiveViewportContext.Provider>
    </View>
  );
}

function clearPane(measurement: Measurement, previous?: Rect): Rect {
  const { width, height, safeArea, regions } = measurement;
  const full: Rect = { x: 0, y: 0, width, height };
  const safe: Rect = {
    x: safeArea.left,
    y: safeArea.top,
    width: Math.max(0, width - safeArea.left - safeArea.right),
    height: Math.max(0, height - safeArea.top - safeArea.bottom),
  };
  let candidates = [full];
  for (const region of regions) {
    if (region.kind === 'division') {
      // A hinge is a division between useful surfaces, not a reason to discard
      // half the app. Expanded grids keep content on both sides of that fold.
      continue;
    } else if (intersection(region, safe)) {
      // Rail/status-bar occlusions already outside the safe area need no extra
      // displacement. An active camera inside content does need clear space.
      candidates = candidates.flatMap((rect) => avoidOcclusion(rect, region));
    }
  }
  candidates = candidates.filter((rect) => rect.width > 0 && rect.height > 0);
  if (!candidates.length) return full;
  const score = (rect: Rect) => area(intersection(rect, safe) ?? rect);
  const largest = candidates.reduce((best, rect) => (score(rect) > score(best) ? rect : best));
  // Keep the same side through small angle/region changes. Crossing the fold
  // just to gain a few points of space is harder to follow than a stable pane.
  const retained = previous
    ? candidates.find(
        (rect) =>
          contains(rect, previous.x + previous.width / 2, previous.y + previous.height / 2) &&
          score(rect) >= score(largest) * 0.85,
      )
    : undefined;
  return retained ?? largest;
}

function avoidOcclusion(rect: Rect, region: Rect): Rect[] {
  const cut = intersection(rect, region);
  if (!cut) return [rect];
  return [
    { ...rect, width: cut.x - rect.x },
    { ...rect, x: cut.x + cut.width, width: rect.x + rect.width - cut.x - cut.width },
    { ...rect, height: cut.y - rect.y },
    { ...rect, y: cut.y + cut.height, height: rect.y + rect.height - cut.y - cut.height },
  ];
}

function intersection(a: Rect, b: Rect): Rect | null {
  const x = Math.max(a.x, b.x),
    y = Math.max(a.y, b.y);
  const width = Math.min(a.x + a.width, b.x + b.width) - x;
  const height = Math.min(a.y + a.height, b.y + b.height) - y;
  return width > 0 && height > 0 ? { x, y, width, height } : null;
}
function area(rect: Rect) {
  return rect.width * rect.height;
}
function contains(rect: Rect, x: number, y: number) {
  return x >= rect.x && x <= rect.x + rect.width && y >= rect.y && y <= rect.y + rect.height;
}

const styles = StyleSheet.create({
  host: { flex: 1, minWidth: 0, minHeight: 0 },
  fill: { flex: 1 },
  pane: { position: 'absolute', overflow: 'hidden' },
});
