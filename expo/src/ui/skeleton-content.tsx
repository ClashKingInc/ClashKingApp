import { createContext, useContext, type PropsWithChildren } from 'react';
import { View, type StyleProp, type ViewStyle, type ViewProps } from 'react-native';
import { useI18n } from '../i18n';

const SkeletonContentContext = createContext(false);

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
  const pending = inherited || loading;
  return (
    <SkeletonContentContext.Provider value={pending}>
      <View
        testID={testID}
        onLayout={onLayout}
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
  return useContext(SkeletonContentContext);
}
