import { useCallback, useLayoutEffect, useRef, useState, useTransition } from 'react';
import type { LayoutChangeEvent, ScrollViewInstance } from 'react-native';
import { retainRecentSections } from './retained-sections';

/** Commit selection feedback separately from the potentially expensive section.
 * Retain the previous tree until a cold section is ready; warm sections commit
 * immediately. Retention lasts for this detail route, never across accounts. */
export function useSectionSelection<Key extends string>(
  initial: Key,
  initialRetained: readonly Key[] = [initial],
  retentionLimit = Number.POSITIVE_INFINITY,
) {
  const [selectedKey, setSelectedKey] = useState(initial);
  const [content, setContent] = useState<{ key: Key; retained: readonly Key[] }>(() => ({
    key: initial,
    retained: [...new Set(initialRetained)],
  }));
  const [pending, startTransition] = useTransition();
  const select = useCallback(
    (next: Key, updateContent?: () => void) => {
      setSelectedKey(next);
      const commit = () => {
        updateContent?.();
        setContent((current) =>
          current.key === next
            ? current
            : {
                key: next,
                retained: retainRecentSections(current.retained, next, retentionLimit),
              },
        );
      };
      if (content.retained.includes(next)) commit();
      else startTransition(commit);
    },
    [content.retained, retentionLimit],
  );
  return { selectedKey, contentKey: content.key, retainedKeys: content.retained, pending, select };
}

/** Preserve a partially visible header, or its collapsed position. A new
 * section starts beneath the tabs rather than inheriting another section's
 * deep offset or restoring an independently saved position. */
export function sectionScrollOffset(offset: number, headerHeight: number): number {
  return Math.max(0, Math.min(offset, headerHeight));
}

export function useSectionScroll(contentKey: string) {
  const scrollRef = useRef<ScrollViewInstance>(null);
  const attachScroll = useCallback((instance: ScrollViewInstance | null) => {
    scrollRef.current = instance;
  }, []);
  const scrollY = useRef(0);
  const headerHeight = useRef(0);
  const switchRequested = useRef(false);
  const [viewportHeight, setViewportHeight] = useState(0);
  const [tabsHeight, setTabsHeight] = useState(0);
  const onViewportLayout = useCallback((event: LayoutChangeEvent) => {
    setViewportHeight(event.nativeEvent.layout.height);
  }, []);
  const onHeaderLayout = useCallback((event: LayoutChangeEvent) => {
    headerHeight.current = event.nativeEvent.layout.height;
  }, []);
  const onTabsLayout = useCallback((event: LayoutChangeEvent) => {
    setTabsHeight(event.nativeEvent.layout.height);
  }, []);
  const recordScroll = useCallback((offset: number) => {
    scrollY.current = offset;
  }, []);
  const prepareSwitch = useCallback(() => {
    switchRequested.current = true;
  }, []);
  useLayoutEffect(() => {
    if (!switchRequested.current) return;
    switchRequested.current = false;
    // Preparation does not freeze the old section. If the user kept scrolling,
    // preserve the latest header position, not where it was at the original tap.
    const offset = sectionScrollOffset(scrollY.current, headerHeight.current);
    scrollY.current = offset;
    scrollRef.current?.scrollTo({ y: offset, animated: false });
  }, [contentKey]);
  // Even an empty/short section must fill the space below pinned tabs. Without
  // this floor, native content-size clamping pulls the hero back into view.
  const minimumContentHeight = Math.max(360, viewportHeight - tabsHeight);
  return {
    attachScroll,
    onViewportLayout,
    onHeaderLayout,
    onTabsLayout,
    recordScroll,
    prepareSwitch,
    minimumContentHeight,
  };
}
