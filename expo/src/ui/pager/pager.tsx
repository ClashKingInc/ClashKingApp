import {
  Children,
  forwardRef,
  useCallback,
  useEffect,
  useImperativeHandle,
  useRef,
  useState,
} from 'react';
import {
  ScrollView,
  StyleSheet,
  View,
  type LayoutChangeEvent,
  type NativeScrollEvent,
  type NativeSyntheticEvent,
} from 'react-native';

import type {
  PagerViewHandle,
  PagerViewOnPageSelectedEvent,
  PagerViewOnPageScrollEvent,
  PagerViewProps,
} from './types';

export function pageOffsetForIndex(
  index: number,
  pageCount: number,
  width: number,
  isRtl: boolean,
): number {
  const bounded = Math.max(0, Math.min(index, Math.max(0, pageCount - 1)));
  return (isRtl ? pageCount - 1 - bounded : bounded) * width;
}

export function pageIndexForOffset(
  offset: number,
  pageCount: number,
  width: number,
  isRtl: boolean,
): number {
  if (pageCount === 0 || width <= 0) return 0;
  const visualIndex = Math.max(0, Math.min(Math.round(Math.abs(offset) / width), pageCount - 1));
  return isRtl ? pageCount - 1 - visualIndex : visualIndex;
}

/** Touch/trackpad-scrollable web PageView with mandatory page snapping. */
export const PagerView = forwardRef<PagerViewHandle, PagerViewProps>(function PagerView(
  {
    children,
    initialPage = 0,
    keyboardDismissMode = 'none',
    layoutDirection = 'ltr',
    onPageSelected,
    onPageScroll,
    orientation = 'horizontal',
    scrollEnabled = true,
    style,
    testID,
  },
  ref,
) {
  if (orientation !== 'horizontal') {
    throw new Error('The ClashKing web pager supports horizontal PageView behavior only.');
  }
  const pages = Children.toArray(children);
  const isRtl = layoutDirection === 'rtl';
  const scroll = useRef<ScrollView>(null);
  const [width, setWidth] = useState(0);
  const selectedPage = useRef(initialPage);
  const reportedPage = useRef(initialPage);
  const animationFrame = useRef<number | undefined>(undefined);
  const selectionCallback = useRef(onPageSelected);
  useEffect(() => {
    selectionCallback.current = onPageSelected;
  }, [onPageSelected]);
  const stopAnimation = useCallback(() => {
    if (animationFrame.current !== undefined) cancelAnimationFrame(animationFrame.current);
    animationFrame.current = undefined;
  }, []);
  useEffect(() => stopAnimation, [stopAnimation]);

  const moveToPage = useCallback(
    (index: number, animated: boolean) => {
      selectedPage.current = Math.max(0, Math.min(index, Math.max(0, pages.length - 1)));
      if (width <= 0) return;
      stopAnimation();
      const target = pageOffsetForIndex(selectedPage.current, pages.length, width, isRtl);
      const finish = () => {
        animationFrame.current = undefined;
        if (reportedPage.current === selectedPage.current) return;
        reportedPage.current = selectedPage.current;
        selectionCallback.current?.({
          nativeEvent: { position: selectedPage.current },
        } as PagerViewOnPageSelectedEvent);
      };
      if (!animated) {
        scroll.current?.scrollTo({ x: target, y: 0, animated: false });
        finish();
        return;
      }
      const start = scroll.current?.getScrollableNode()?.scrollLeft ?? target;
      const startTime = performance.now();
      // Browser-native smooth scrolling can take >600ms across two tabs. Use
      // a bounded, interruptible transition and always report its settled page.
      const frame = (now: number) => {
        const progress = Math.min(1, (now - startTime) / 220);
        const eased = 1 - Math.pow(1 - progress, 3);
        scroll.current?.scrollTo({ x: start + (target - start) * eased, y: 0, animated: false });
        if (progress < 1) animationFrame.current = requestAnimationFrame(frame);
        else finish();
      };
      animationFrame.current = requestAnimationFrame(frame);
    },
    [isRtl, pages.length, width, stopAnimation],
  );

  useImperativeHandle(
    ref,
    () => ({
      setPage: (index) => moveToPage(index, true),
      setPageWithoutAnimation: (index) => moveToPage(index, false),
    }),
    [moveToPage],
  );

  useEffect(() => {
    moveToPage(selectedPage.current, false);
  }, [moveToPage]);

  const handleLayout = (event: LayoutChangeEvent) => {
    const nextWidth = event.nativeEvent.layout.width;
    if (nextWidth > 0 && nextWidth !== width) setWidth(nextWidth);
  };

  const handleMomentumEnd = (event: NativeSyntheticEvent<NativeScrollEvent>) => {
    const next = pageIndexForOffset(event.nativeEvent.contentOffset.x, pages.length, width, isRtl);
    if (animationFrame.current !== undefined || next === reportedPage.current) return;
    selectedPage.current = next;
    reportedPage.current = next;
    onPageSelected?.({ nativeEvent: { position: next } } as PagerViewOnPageSelectedEvent);
  };

  return (
    <View onLayout={handleLayout} style={style} testID={testID}>
      <ScrollView
        bounces={false}
        contentContainerStyle={[styles.content, isRtl ? styles.contentRtl : styles.contentLtr]}
        decelerationRate="fast"
        disableIntervalMomentum
        horizontal
        keyboardDismissMode={keyboardDismissMode === 'on-drag' ? 'on-drag' : 'none'}
        onMomentumScrollEnd={handleMomentumEnd}
        onTouchStart={stopAnimation}
        scrollEventThrottle={16}
        onScroll={(event) => {
          if (!onPageScroll || width <= 0) return;
          const visual = Math.abs(event.nativeEvent.contentOffset.x) / width;
          const logical = Math.max(
            0,
            Math.min(pages.length - 1, isRtl ? pages.length - 1 - visual : visual),
          );
          const position = Math.floor(logical);
          onPageScroll({
            nativeEvent: { position, offset: logical - position },
          } as PagerViewOnPageScrollEvent);
        }}
        overScrollMode="never"
        pagingEnabled
        ref={scroll}
        scrollEnabled={scrollEnabled}
        showsHorizontalScrollIndicator={false}
        snapToInterval={width > 0 ? width : undefined}
        snapToOffsets={width > 0 ? pages.map((_, index) => index * width) : undefined}
        style={[styles.scroll, webScrollSnapStyle]}
        testID={testID ? `${testID}-scroll` : undefined}
      >
        {pages.map((page, index) => (
          <View
            key={index}
            style={[styles.page, width > 0 ? { width } : styles.unmeasuredPage, webPageSnapStyle]}
          >
            {page}
          </View>
        ))}
      </ScrollView>
    </View>
  );
});

const webScrollSnapStyle = {
  scrollSnapType: 'x mandatory',
  WebkitOverflowScrolling: 'touch',
} as never;
const webPageSnapStyle = { scrollSnapAlign: 'start', scrollSnapStop: 'always' } as never;

const styles = StyleSheet.create({
  scroll: { flex: 1 },
  content: { flexGrow: 1 },
  contentLtr: { flexDirection: 'row' },
  contentRtl: { flexDirection: 'row-reverse' },
  page: { flexShrink: 0 },
  unmeasuredPage: { flex: 1 },
});
