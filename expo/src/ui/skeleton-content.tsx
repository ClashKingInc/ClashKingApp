import { createContext, useContext, useMemo, type PropsWithChildren } from 'react';
import { View, type StyleProp, type ViewStyle, type ViewProps } from 'react-native';
import { useI18n } from '../i18n';
import { useSkeletonMotion } from './skeleton-motion';

const SkeletonContentContext = createContext<{
  loading: boolean;
  opacity: number | ReturnType<typeof useSkeletonMotion>;
}>({ loading: false, opacity: 1 });

/** Loading uses the real card tree. Placeholder values are presentation-only:
 * never pass them to stores, exports or actions. Keep known controls outside
 * this boundary so users can still leave a page while its data loads. */
export function SkeletonContent({
  loading = true,
  children,
  style,
  label,
  testID,
  onLayout,
}: PropsWithChildren<{
  loading?: boolean;
  style?: StyleProp<ViewStyle>;
  label?: string;
  testID?: string;
  onLayout?: ViewProps['onLayout'];
}>) {
  const { t } = useI18n();
  const inherited = useContext(SkeletonContentContext);
  const pending = inherited.loading || loading;
  const ownOpacity = useSkeletonMotion(loading && !inherited.loading);
  const opacity = inherited.loading ? inherited.opacity : ownOpacity;
  const appearance = useMemo(() => ({ loading: pending, opacity }), [pending, opacity]);
  return (
    <SkeletonContentContext.Provider value={appearance}>
      <View
        testID={testID}
        onLayout={onLayout}
        // Animate placeholders, not their parent: fixed labels and controls
        // must stay visible during the reveal delay and shared loading pulse.
        style={style}
        pointerEvents={pending ? 'none' : 'auto'}
        accessibilityRole={pending ? 'progressbar' : undefined}
        accessibilityLabel={pending ? (label ?? t('generalLoading')) : undefined}
        accessibilityState={pending ? { busy: true } : undefined}
        accessible={pending}
      >
        <View
          style={{ display: 'contents' }}
          accessibilityElementsHidden={pending}
          importantForAccessibility={pending ? 'no-hide-descendants' : 'auto'}
        >
          {children}
        </View>
      </View>
    </SkeletonContentContext.Provider>
  );
}

export function useSkeletonContent(): boolean {
  return useContext(SkeletonContentContext).loading;
}

/** One boundary shares its reveal and pulse with every pending primitive. */
export function useSkeletonAppearance() {
  return useContext(SkeletonContentContext);
}
