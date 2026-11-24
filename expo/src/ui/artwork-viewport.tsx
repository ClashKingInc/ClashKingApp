import {
  createContext,
  createRef,
  useCallback,
  useContext,
  useEffect,
  useRef,
  useState,
  useSyncExternalStore,
  type ComponentRef,
  type ReactNode,
} from 'react';
import { View, type ViewProps } from 'react-native';

// Start artwork slightly before its group comes into view during a scroll.
const ARTWORK_OVERSCAN = 160;
const unsubscribe = () => {};
const subscribeNone = () => unsubscribe;
type NativeView = ComponentRef<typeof View>;

export function createArtworkViewport() {
  const contentRef = createRef<NativeView>();
  const listeners = new Set<() => void>();
  const layoutListeners = new Set<() => void>();
  let top = 0;
  let height = 0;
  let contentTop = 0;
  let active = true;
  const notify = () => {
    for (const listener of listeners) listener();
  };
  return {
    contentRef,
    subscribe(listener: () => void) {
      listeners.add(listener);
      return () => {
        listeners.delete(listener);
      };
    },
    subscribeLayout(listener: () => void) {
      layoutListeners.add(listener);
      return () => {
        layoutListeners.delete(listener);
      };
    },
    setScroll(offset: number) {
      if (offset === top) return;
      top = offset;
      notify();
    },
    setHeight(next: number) {
      if (next === height) return;
      height = next;
      notify();
    },
    onContentLayout(next: number) {
      if (next !== contentTop) {
        contentTop = next;
        notify();
      }
      // A sibling accordion can move a group without changing its own layout.
      if (active) for (const listener of layoutListeners) listener();
    },
    setActive(next: boolean) {
      if (next === active) return;
      active = next;
      notify();
    },
    isActive: () => active,
    includes(y: number, groupHeight: number) {
      const start = top - contentTop;
      return (
        active &&
        height > 0 &&
        y < start + height + ARTWORK_OVERSCAN &&
        y + groupHeight > start - ARTWORK_OVERSCAN
      );
    },
  };
}

export const ArtworkViewportContext = createContext<ReturnType<
  typeof createArtworkViewport
> | null>(null);

/** Keeps each group's layout and controls mounted while deferring offscreen artwork. */
export function ArtworkViewportGroup({
  enabled,
  style,
  children,
}: {
  enabled: boolean;
  style: ViewProps['style'];
  children: (showArtwork: boolean) => ReactNode;
}) {
  const context = useContext(ArtworkViewportContext);
  const viewport = enabled ? context : null;
  const ref = useRef<NativeView>(null);
  const [bounds, setBounds] = useState<{ y: number; height: number } | null>();
  const measure = useCallback(() => {
    if (!viewport?.isActive()) return;
    const content = viewport.contentRef.current;
    if (!content || !ref.current) {
      setBounds(null);
      return;
    }
    ref.current.measureLayout(
      content,
      (_x, y, _width, height) => {
        if (!viewport.isActive()) return;
        setBounds((current) =>
          current && current.y === y && current.height === height ? current : { y, height },
        );
      },
      () => {
        if (viewport.isActive()) setBounds(null);
      },
    );
  }, [viewport]);
  useEffect(() => viewport?.subscribeLayout(measure), [viewport, measure]);
  const showArtwork = useSyncExternalStore(
    viewport?.subscribe ?? subscribeNone,
    () =>
      !viewport ||
      (viewport.isActive() &&
        (bounds === null || (!!bounds && viewport.includes(bounds.y, bounds.height)))),
    () => true,
  );
  return (
    <View
      ref={viewport ? ref : undefined}
      collapsable={viewport ? false : undefined}
      style={style}
      onLayout={viewport ? measure : undefined}
    >
      {children(showArtwork)}
    </View>
  );
}
