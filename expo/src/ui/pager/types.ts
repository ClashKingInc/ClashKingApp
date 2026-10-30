import type { PropsWithChildren } from 'react';
import type { NativeSyntheticEvent, StyleProp, ViewStyle } from 'react-native';

export interface PagerViewHandle {
  setPage(index: number): void;
  setPageWithoutAnimation(index: number): void;
  setScrollEnabled?(enabled: boolean): void;
}

export interface PagerViewOnPageSelectedEventData {
  readonly position: number;
}

export type PagerViewOnPageSelectedEvent = NativeSyntheticEvent<PagerViewOnPageSelectedEventData>;
export type PagerViewOnPageScrollEvent = NativeSyntheticEvent<{ position: number; offset: number }>;

export type PagerViewProps = PropsWithChildren<{
  readonly initialPage?: number;
  readonly keyboardDismissMode?: 'none' | 'on-drag';
  readonly layoutDirection?: 'ltr' | 'rtl';
  readonly offscreenPageLimit?: number;
  readonly onPageSelected?: (event: PagerViewOnPageSelectedEvent) => void;
  readonly onPageScroll?: (event: PagerViewOnPageScrollEvent) => void;
  readonly onPageScrollStateChanged?: (
    event: NativeSyntheticEvent<{ pageScrollState: 'idle' | 'dragging' | 'settling' }>,
  ) => void;
  readonly orientation?: 'horizontal' | 'vertical';
  readonly overdrag?: boolean;
  readonly overScrollMode?: 'auto' | 'always' | 'never';
  readonly scrollEnabled?: boolean;
  readonly style?: StyleProp<ViewStyle>;
  readonly testID?: string;
}>;
