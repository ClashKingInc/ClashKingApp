import { forwardRef, type Ref } from 'react';
import NativePagerView from 'react-native-pager-view';

import type { PagerViewHandle, PagerViewProps } from './types';

/** Native implementation backed by the same velocity-aware pager used before the abstraction. */
export const PagerView = forwardRef<PagerViewHandle, PagerViewProps>(
  function PagerView(props, ref) {
    return <NativePagerView {...props} ref={ref as Ref<NativePagerView>} />;
  },
);
