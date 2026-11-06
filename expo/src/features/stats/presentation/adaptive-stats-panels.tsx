import { Children, type ReactNode } from 'react';
import { StyleSheet, View, type StyleProp, type ViewStyle } from 'react-native';
import { useAdaptiveLayout } from '../../../ui/adaptive-layout';
import { ResponsiveGrid } from '../../../ui/responsive-grid';

/** Keep each chart or distribution together, and keep the same tree while folding. */
export function AdaptiveStatsPanels({
  children,
  style,
  embedded = false,
  gap = 16,
}: {
  readonly children: ReactNode;
  readonly style?: StyleProp<ViewStyle>;
  readonly embedded?: boolean;
  readonly gap?: number;
}) {
  const layout = useAdaptiveLayout();
  if (!layout.isDuo && !layout.isTablet)
    return embedded ? <>{children}</> : <View style={style}>{children}</View>;
  if (Children.toArray(children).length === 0) return null;
  // Caller spacing must also drive the width calculation. A 24pt styled gap
  // with 16pt calculated spacing pushed the second distribution below the first.
  const styledGap = StyleSheet.flatten(style)?.gap;
  const measuredGap = typeof styledGap === 'number' ? styledGap : gap;
  return (
    <ResponsiveGrid
      style={style}
      minItemWidth={layout.isDuo ? 360 : 460}
      maxColumns={layout.isExpanded ? layout.columns(layout.isDuo ? 360 : 460, 2) : 1}
      gap={measuredGap}
    >
      {children}
    </ResponsiveGrid>
  );
}
