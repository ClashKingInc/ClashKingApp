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

import type { PagerViewHandle, PagerViewOnPageSelectedEvent, PagerViewProps } from './types';

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

  const moveToPage = useCallback(
    (index: number, animated: boolean) => {
      selectedPage.current = Math.max(0, Math.min(index, Math.max(0, pages.length - 1)));
      if (width <= 0) return;
      scroll.current?.scrollTo({
        x: pageOffsetForIndex(selectedPage.current, pages.length, width, isRtl),
        y: 0,
        animated,
      });
    },
    [isRtl, pages.length, width],
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
    if (next === selectedPage.current) return;
    selectedPage.current = next;
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
