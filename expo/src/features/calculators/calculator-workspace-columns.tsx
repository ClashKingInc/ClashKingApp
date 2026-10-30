import { Children, type ReactNode } from 'react';
import { View } from 'react-native';
import { useAdaptiveLayout } from '../../ui/adaptive-layout';

/** Keep phone ordering and gestures intact; only expanded iOS windows split a workflow. */
export function CalculatorWorkspaceColumns({
  children,
  compactGap,
}: {
  children: ReactNode;
  compactGap?: number;
}) {
  const layout = useAdaptiveLayout();
  if (!layout.isExpanded || layout.columns(420, 2) < 2) {
    return compactGap === undefined ? (
      <>{children}</>
    ) : (
      <View style={{ gap: compactGap }}>{children}</View>
    );
  }
  return (
    <View style={{ flexDirection: 'row', alignItems: 'flex-start', gap: 24 }}>
      {Children.toArray(children).map((child, index) => (
        <View key={index} style={{ flex: 1, minWidth: 0, gap: 20 }}>
          {child}
        </View>
      ))}
    </View>
  );
}
