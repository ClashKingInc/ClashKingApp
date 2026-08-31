import { Children, isValidElement, useState, type ReactNode } from 'react';
import {
  StyleSheet,
  View,
  type LayoutChangeEvent,
  type StyleProp,
  type ViewStyle,
} from 'react-native';

import { ckSpacing } from './tokens';
import { resolveGridColumns } from './layout';

export type ResponsiveGridProps = {
  children: ReactNode;
  minItemWidth?: number;
  minColumns?: number;
  maxColumns?: number;
  gap?: number;
  style?: StyleProp<ViewStyle>;
};

export function ResponsiveGrid({
  children,
  minItemWidth = 220,
  minColumns = 1,
  maxColumns = 4,
  gap = ckSpacing.md,
  style,
}: ResponsiveGridProps) {
  const [width, setWidth] = useState(0);
  const columns = resolveGridColumns({ width, minItemWidth, minColumns, maxColumns, gap });
  const itemWidth = width > 0 ? Math.max(0, (width - gap * (columns - 1)) / columns) : '100%';
  const onLayout = (event: LayoutChangeEvent) => setWidth(event.nativeEvent.layout.width);
  const childOccurrences = new Map<string, number>();
  const entries = Children.toArray(children).map((child) => {
    const identity = childIdentity(child);
    const occurrence = childOccurrences.get(identity) ?? 0;
    childOccurrences.set(identity, occurrence + 1);
    return { child, key: `${identity}:${occurrence}` };
  });

  return (
    <View onLayout={onLayout} style={[styles.grid, { gap }, style]}>
      {entries.map((entry) => (
        <View key={entry.key} style={{ width: itemWidth }}>
          {entry.child}
        </View>
      ))}
    </View>
  );
}

function childIdentity(child: ReactNode): string {
  if (isValidElement(child) && child.key !== null) return `element:${String(child.key)}`;
  if (typeof child === 'string' || typeof child === 'number') {
    return `primitive:${typeof child}:${String(child)}`;
  }
  return `node:${typeof child}`;
}

const styles = StyleSheet.create({
  grid: { width: '100%', flexDirection: 'row', flexWrap: 'wrap' },
});
