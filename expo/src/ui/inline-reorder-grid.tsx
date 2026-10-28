import {
  useEffect,
  useLayoutEffect,
  useCallback,
  useContext,
  useMemo,
  useRef,
  useState,
  type MutableRefObject,
  type ReactNode,
  type RefObject,
} from 'react';
import { View, type ScrollViewInstance } from 'react-native';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import Animated, { useAnimatedStyle, useSharedValue, withTiming } from 'react-native-reanimated';
import { CARD_REORDER_HOLD_MS } from './drag-jiggle';
import { useI18n } from '../i18n';
import { useCKAccessibility } from './accessibility';
import { PrimaryPageGestureContext } from './primary-swipe-guard';

type Position = { x: number; y: number; width: number; height: number };
type Drag = {
  key: string;
  from: number;
  original: string[];
  origin: Position;
  grabX: number;
  grabY: number;
  startScroll: number;
  x: number;
  y: number;
  absoluteY: number;
};

/** One keyed tree for both one- and two-column layouts. Reordering changes
 * positions in place; it never reparents cards into a modal or resets their state. */
export function InlineReorderGrid<T>({
  data,
  keyExtractor,
  columns,
  gap = 12,
  renderItem,
  onReorder,
  onDragStateChange,
  scrollRef,
  scrollOffset,
}: {
  data: readonly T[];
  keyExtractor: (item: T) => string;
  columns: number;
  gap?: number;
  renderItem: (item: T, index: number, active: boolean) => ReactNode;
  onReorder: (data: T[], from: number, to: number) => unknown;
  onDragStateChange: (active: boolean) => void;
  scrollRef: RefObject<ScrollViewInstance | null>;
  scrollOffset: MutableRefObject<number>;
}) {
  const { isRtl } = useI18n();
  const incoming = data.map(keyExtractor);
  const signature = JSON.stringify(incoming);
  const [keys, setKeys] = useState(incoming);
  const [activeKey, setActiveKey] = useState<string | null>(null);
  const [width, setWidth] = useState(0);
  const [heights, setHeights] = useState<Record<string, number>>({});
  const drag = useRef<Drag | null>(null);
  const order = useRef(keys);
  const reorderVersion = useRef(0);
  const positions = useRef<Record<string, Position>>({});
  const bounds = useRef({ y: 0, height: 0 });
  const latest = useRef({ data, keyExtractor, onReorder, onDragStateChange });
  useLayoutEffect(() => {
    latest.current = { data, keyExtractor, onReorder, onDragStateChange };
  });
  const dragX = useSharedValue(0),
    dragY = useSharedValue(0);
  const originX = useSharedValue(0),
    originY = useSharedValue(0);
  const previousSignature = useRef(signature);
  useEffect(() => {
    if (signature === previousSignature.current || drag.current) return;
    previousSignature.current = signature;
    setKeys(JSON.parse(signature));
  }, [signature, activeKey]);
  const byKey = new Map(data.map((item) => [keyExtractor(item), item]));
  const displayed = [
    ...keys.filter((key) => byKey.has(key)),
    ...incoming.filter((key) => !keys.includes(key)),
  ];
  useLayoutEffect(() => {
    order.current = displayed;
  });
  const columnWidth = Math.max(0, (width - gap * (columns - 1)) / columns);
  const bottoms = Array.from({ length: columns }, () => 0);
  const layout: Record<string, Position> = {};
  displayed.forEach((key, index) => {
    const column = index % columns;
    layout[key] = {
      x: (isRtl ? columns - 1 - column : column) * (columnWidth + gap),
      y: bottoms[column]!,
      width: columnWidth,
      height: heights[key] ?? 180,
    };
    bottoms[column] = layout[key]!.y + layout[key]!.height + gap;
  });
  useLayoutEffect(() => {
    positions.current = layout;
  });
  const update = (x: number, y: number, absoluteY: number) => {
    const current = drag.current;
    if (!current) return;
    current.x = x;
    current.y = y;
    current.absoluteY = absoluteY;
    const dy = y + scrollOffset.current - current.startScroll;
    dragX.value = x;
    dragY.value = dy;
    const pointerX = current.origin.x + current.grabX + x;
    const pointerY = current.origin.y + current.grabY + dy;
    const target = order.current.findIndex((key) => {
      if (key === current.key) return false;
      const p = positions.current[key];
      // A small inner target keeps unequal-height cards from oscillating at
      // shared edges while the dragged card follows the original grab point.
      return (
        p &&
        pointerX >= p.x + 12 &&
        pointerX <= p.x + p.width - 12 &&
        pointerY >= p.y + 16 &&
        pointerY <= p.y + p.height - 16
      );
    });
    const from = order.current.indexOf(current.key);
    if (target < 0 || target === from) return;
    const next = [...order.current];
    next.splice(from, 1);
    next.splice(target, 0, current.key);
    order.current = next;
    setKeys(next);
  };
  const begin = (key: string, x: number, y: number, absoluteY: number) => {
    const origin = positions.current[key];
    if (!origin || displayed.length < 2) return;
    reorderVersion.current += 1;
    originX.value = origin.x;
    originY.value = origin.y;
    dragX.value = 0;
    dragY.value = 0;
    drag.current = {
      key,
      from: order.current.indexOf(key),
      original: [...order.current],
      origin,
      grabX: x,
      grabY: y,
      startScroll: scrollOffset.current,
      x: 0,
      y: 0,
      absoluteY,
    };
    scrollRef.current?.measureInWindow((_x, top, _width, height) => {
      bounds.current = { y: top, height };
    });
    setActiveKey(key);
    latest.current.onDragStateChange(true);
  };
  const finish = (success: boolean) => {
    const current = drag.current;
    if (!current) return;
    drag.current = null;
    setActiveKey(null);
    latest.current.onDragStateChange(false);
    if (!success) {
      order.current = current.original;
      setKeys(current.original);
      return;
    }
    const to = order.current.indexOf(current.key);
    if (to === current.from) return;
    const map = new Map(
      latest.current.data.map((item) => [latest.current.keyExtractor(item), item]),
    );
    const committed = [...order.current];
    const version = reorderVersion.current;
    const rollback = () => {
      // A late failed save must not undo a newer drag or an externally updated
      // roster. Only restore the exact optimistic order this save produced.
      if (
        version !== reorderVersion.current ||
        drag.current ||
        order.current.join('\u0000') !== committed.join('\u0000')
      )
        return;
      order.current = current.original;
      setKeys(current.original);
    };
    try {
      const result = latest.current.onReorder(
        committed.map((key) => map.get(key)!).filter(Boolean),
        current.from,
        to,
      );
      if (result === false) rollback();
      else if (result && typeof (result as PromiseLike<unknown>).then === 'function') {
        void Promise.resolve(result).then((saved) => {
          if (saved === false) rollback();
        }, rollback);
      }
    } catch {
      rollback();
    }
  };
  const finishRef = useRef(finish);
  useLayoutEffect(() => {
    finishRef.current = finish;
  });
  useEffect(() => {
    if (drag.current) finishRef.current(false);
  }, [columns, width]);
  // Only a held, moving card can drive edge scrolling. A stationary pickup
  // near the viewport edge must not jump a tall card to a different position.
  const updateRef = useRef(update);
  useLayoutEffect(() => {
    updateRef.current = update;
  });
  useEffect(() => {
    if (!activeKey) return;
    const timer = setInterval(() => {
      const d = drag.current,
        b = bounds.current;
      if (!d || !b.height || Math.abs(d.y) < 8) return;
      const localY = d.absoluteY - b.y;
      const amount = localY < 48 ? -12 : localY > b.height - 48 ? 12 : 0;
      if (amount)
        scrollRef.current?.scrollTo({
          y: Math.max(0, scrollOffset.current + amount),
          animated: false,
        });
      updateRef.current(d.x, d.y, d.absoluteY);
    }, 32);
    return () => clearInterval(timer);
  }, [activeKey, scrollRef, scrollOffset]);
  useEffect(() => () => latest.current.onDragStateChange(false), []);
  return (
    <View
      testID="inline-reorder-grid"
      onLayout={(e) => setWidth(e.nativeEvent.layout.width)}
      style={{
        height: Math.max(0, ...bottoms) - (displayed.length ? gap : 0),
        position: 'relative',
      }}
    >
      {displayed.map((key, index) => (
        <GridCell
          key={key}
          position={layout[key]!}
          active={activeKey === key}
          enabled={displayed.length > 1}
          originX={originX}
          originY={originY}
          dragX={dragX}
          dragY={dragY}
          onBegin={(x, y, absoluteY) => begin(key, x, y, absoluteY)}
          onMove={update}
          onFinish={finish}
          onHeight={(height) =>
            setHeights((current) =>
              current[key] === height ? current : { ...current, [key]: height },
            )
          }
        >
          {renderItem(byKey.get(key)!, index, activeKey === key)}
        </GridCell>
      ))}
    </View>
  );
}

function GridCell({
  position,
  active,
  enabled,
  originX,
  originY,
  dragX,
  dragY,
  onBegin,
  onMove,
  onFinish,
  onHeight,
  children,
}: {
  position: Position;
  active: boolean;
  enabled: boolean;
  originX: { value: number };
  originY: { value: number };
  dragX: { value: number };
  dragY: { value: number };
  onBegin: (x: number, y: number, absoluteY: number) => void;
  onMove: (x: number, y: number, absoluteY: number) => void;
  onFinish: (success: boolean) => void;
  onHeight: (height: number) => void;
  children: ReactNode;
}) {
  const { reduceMotion } = useCKAccessibility();
  const parentSwipe = useContext(PrimaryPageGestureContext);
  const x = useSharedValue(position.x),
    y = useSharedValue(position.y);
  useEffect(() => {
    x.value = withTiming(position.x, { duration: reduceMotion ? 0 : 160 });
    y.value = withTiming(position.y, { duration: reduceMotion ? 0 : 160 });
  }, [position.x, position.y, reduceMotion, x, y]);
  const style = useAnimatedStyle(() => ({
    transform: [
      { translateX: active ? originX.value + dragX.value : x.value },
      { translateY: active ? originY.value + dragY.value : y.value },
    ],
  }));
  const handlers = useRef({ onBegin, onMove, onFinish });
  useLayoutEffect(() => {
    handlers.current = { onBegin, onMove, onFinish };
  });
  const startGesture = useCallback(
    (e: { x: number; y: number; absoluteY: number }) =>
      handlers.current.onBegin(e.x, e.y, e.absoluteY),
    [],
  );
  const moveGesture = useCallback(
    (e: { translationX: number; translationY: number; absoluteY: number }) =>
      handlers.current.onMove(e.translationX, e.translationY, e.absoluteY),
    [],
  );
  const finishGesture = useCallback(
    (_e: unknown, success: boolean) => handlers.current.onFinish(success),
    [],
  );
  const pan = useMemo(() => {
    const gesture = Gesture.Pan()
      .enabled(enabled)
      .activateAfterLongPress(CARD_REORDER_HOLD_MS)
      .minDistance(0)
      .runOnJS(true);
    if (parentSwipe) gesture.blocksExternalGesture(parentSwipe);
    // RNGH stores these for touch events; it does not read the refs in render.
    /* eslint-disable react-hooks/refs */
    return gesture.onStart(startGesture).onUpdate(moveGesture).onFinalize(finishGesture);
    /* eslint-enable react-hooks/refs */
  }, [enabled, parentSwipe, startGesture, moveGesture, finishGesture]);
  return (
    <GestureDetector gesture={pan}>
      <Animated.View
        onLayout={(e) => onHeight(e.nativeEvent.layout.height)}
        style={[
          {
            position: 'absolute',
            top: 0,
            left: 0,
            width: position.width,
            zIndex: active ? 100 : 0,
          },
          style,
        ]}
      >
        {children}
      </Animated.View>
    </GestureDetector>
  );
}
