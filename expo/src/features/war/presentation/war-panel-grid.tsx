import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';
import { Children, cloneElement, isValidElement, type ReactNode } from 'react';
import { StyleSheet, View, type StyleProp, type ViewStyle } from 'react-native';
import { useAdaptiveLayout } from '../../../ui/adaptive-layout';
import { ResponsiveGrid } from '../../../ui/responsive-grid';

export function WarPanelGrid({
  children,
  style,
  embedded = false,
  gap = 12,
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
  return (
    <ResponsiveGrid
      style={style}
      minItemWidth={330}
      maxColumns={layout.isExpanded ? layout.columns(330, 2) : 1}
      gap={gap}
    >
      {children}
    </ResponsiveGrid>
  );
}

/** Native modals have a separate window. Keep their safe-area geometry local
 * without changing the existing phone/Android content tree. */
export function EntityModalViewport({ children }: { children: ReactNode }) {
  const layout = useAdaptiveLayout();
  if (!layout.isDuo && !layout.isTablet) return <>{children}</>;
  // Tint belongs to the full modal window; only the content respects safe areas.
  // Moving the whole backdrop into SafeAreaView leaves untinted strips at the rail.
  const backdrop = isValidElement<{ style?: StyleProp<ViewStyle> }>(children)
    ? StyleSheet.flatten(children.props.style)?.backgroundColor
    : undefined;
  const content = isValidElement<{ style?: StyleProp<ViewStyle> }>(children)
    ? cloneElement(children, { style: [children.props.style, { backgroundColor: 'transparent' }] })
    : children;
  return (
    <SafeAreaProvider style={{ flex: 1, backgroundColor: backdrop }}>
      <SafeAreaView style={{ flex: 1 }}>{content}</SafeAreaView>
    </SafeAreaProvider>
  );
}
