import Reanimated, {
  useAnimatedStyle,
  useAnimatedScrollHandler,
  useSharedValue,
} from 'react-native-reanimated';
import { useWikiScroll } from './wiki-scroll-view';
import { useState, useRef, useLayoutEffect, useCallback, type ReactNode } from 'react';
import { StyleSheet, Text, View, type ViewInstance } from 'react-native';
import { MobileWebImage, colorWithAlpha, useCKTheme } from '../../ui';
import { ckTypography } from '../../ui/tokens';
import { useI18n } from '../../i18n';

export interface WikiColumn {
  key: string;
  label: string;
  image?: string;
  width?: number;
}
export interface WikiTableRow {
  key: string;
  label: string;
  image?: string;
  values: Readonly<Record<string, ReactNode>>;
  selected?: boolean;
}

type WikiTableProps = {
  columns: readonly WikiColumn[];
  rows: readonly WikiTableRow[];
  identityLabel: string;
  identityWidth?: number;
  singleLineIdentity?: boolean;
  identityAccessory?: (row: WikiTableRow) => ReactNode;
};

export function WikiTable(props: WikiTableProps) {
  // A different tab/schema must not inherit another table's measured header
  // height or horizontal offset. Row selection alone preserves both.
  const schema = JSON.stringify([props.identityLabel, props.identityWidth, props.columns]);
  return <WikiTableContent key={schema} {...props} />;
}

/** Freeze identity outside the horizontal viewport. Measure the data rows so
 * enlarged/localized text cannot drift out of alignment with that identity. */
function WikiTableContent({
  columns,
  rows,
  identityLabel,
  identityWidth = 145,
  singleLineIdentity = false,
  identityAccessory,
}: WikiTableProps) {
  const theme = useCKTheme(),
    { isRtl } = useI18n();
  const [viewportWidth, setViewportWidth] = useState(0);
  const [shellHeight, setShellHeight] = useState(0);
  const [heights, setHeights] = useState<Record<string, number>>({});
  const measured = useRef<Record<string, number>>({});
  const pendingFrame = useRef<number | null>(null);
  // Hundreds of ordinary 46-point row/layout events are not state changes.
  // Ignore those defaults and coalesce genuinely taller labels/cells into one
  // frame; otherwise opening a long table repeatedly rebuilds every native cell.
  const measureRow = useCallback((key: string, height: number) => {
    const next = Math.ceil(height);
    const current = measured.current[key] ?? (key === 'header' ? 48 : 46);
    if (next <= current) return;
    measured.current[key] = next;
    if (pendingFrame.current !== null) return;
    pendingFrame.current = requestAnimationFrame(() => {
      pendingFrame.current = null;
      setHeights({ ...measured.current });
    });
  }, []);
  useLayoutEffect(
    () => () => {
      if (pendingFrame.current !== null) cancelAnimationFrame(pendingFrame.current);
    },
    [],
  );
  const scroll = useWikiScroll();
  const shell = useRef<ViewInstance>(null);
  const x = useSharedValue(0);
  const availableWidth = Math.max(0, viewportWidth - identityWidth);
  const minimumWidth = columns.reduce((sum, column) => sum + (column.width ?? 110), 0);
  const extraWidth =
    columns.length && minimumWidth < availableWidth
      ? (availableWidth - minimumWidth) / columns.length
      : 0;
  const columnWidth = (column: WikiColumn) => (column.width ?? 110) + extraWidth;
  const contentTop = useSharedValue<number | null>(null);
  const tableHeight = useSharedValue(0);
  const headerHeight = Math.ceil(Math.max(48, heights.header ?? 0));
  // Worklets may capture shared values, not the context's native React ref.
  // Capturing scroll itself freezes that ref and floods every mount/return with
  // serialization warnings and failed updates.
  const scrollY = scroll?.y;
  const contentRef = scroll?.content;
  const layoutRevision = scroll?.layoutRevision;
  useLayoutEffect(() => {
    // Measure against the stable content ancestor after layout changes. Window
    // coordinates include scroll motion and can leave a stale middle-of-table pin.
    const frame = requestAnimationFrame(() => {
      const content = contentRef?.current;
      if (!content) return;
      shell.current?.measureLayout(
        content,
        (_x, top) => contentTop.set(top),
        () => {},
      );
    });
    return () => cancelAnimationFrame(frame);
  }, [contentRef, shell, contentTop, layoutRevision, headerHeight, viewportWidth, shellHeight]);
  const horizontalScroll = useAnimatedScrollHandler((event) => {
    x.set(event.contentOffset.x);
  });
  const pinned = useAnimatedStyle(() => {
    if (!scrollY) return {};
    // Only scrollY changes per frame. Layout updates refresh the content-space
    // anchor, including when an image or a stat card above the table resizes.
    const top = contentTop.get();
    return {
      transform: [
        {
          translateY:
            top === null
              ? 0
              : Math.max(
                  0,
                  Math.min(scrollY.get() - top, Math.max(0, tableHeight.get() - headerHeight)),
                ),
        },
      ],
    };
  });
  const horizontalHeader = useAnimatedStyle(() => ({ transform: [{ translateX: -x.get() }] }));
  const heightFor = (key: string) => heights[key] ?? (key === 'header' ? 48 : 46);
  const rowStyle = (row: WikiTableRow) => ({
    minHeight: 46,
    backgroundColor: row.selected ? colorWithAlpha(theme.primary, 0.1) : theme.card,
    borderBottomColor: colorWithAlpha(theme.outlineVariant, 0.2),
  });
  return (
    <View style={{ gap: 6 }}>
      <Reanimated.View
        ref={shell}
        collapsable={false}
        onLayout={(e) => {
          setViewportWidth(e.nativeEvent.layout.width);
          tableHeight.set(e.nativeEvent.layout.height);
          setShellHeight(e.nativeEvent.layout.height);
        }}
        style={[
          styles.shell,
          { backgroundColor: theme.card, flexDirection: isRtl ? 'row-reverse' : 'row' },
        ]}
      >
        <View style={{ width: identityWidth, flexShrink: 0 }}>
          <View style={{ height: heightFor('header') }} />
          {rows.map((row) => (
            <View
              key={row.key}
              style={[styles.row, styles.identity, rowStyle(row), { height: heightFor(row.key) }]}
            >
              {identityAccessory?.(row)}
              {row.image ? (
                <MobileWebImage imageUrl={row.image} contentFit="contain" style={styles.icon} />
              ) : null}
              <Text
                allowFontScaling
                numberOfLines={singleLineIdentity ? 1 : undefined}
                style={[styles.label, { color: theme.onSurface }]}
                onTextLayout={(e) =>
                  measureRow(
                    row.key,
                    e.nativeEvent.lines.reduce((sum, line) => sum + line.height, 0) + 24,
                  )
                }
              >
                {row.label}
              </Text>
            </View>
          ))}
        </View>
        <Reanimated.ScrollView
          horizontal
          contentContainerStyle={{ flexGrow: 0 }}
          onScroll={horizontalScroll}
          scrollEventThrottle={16}
          style={{ width: availableWidth, flexShrink: 1, flexGrow: 0, alignSelf: 'flex-start' }}
          bounces={false}
          overScrollMode="never"
          contentInsetAdjustmentBehavior="never"
          automaticallyAdjustContentInsets={false}
          showsHorizontalScrollIndicator
          nestedScrollEnabled
        >
          <View style={{ flexGrow: 0 }}>
            <View style={{ height: heightFor('header') }} />
            {rows.map((row) => (
              <View
                key={row.key}
                onLayout={(e) => measureRow(row.key, e.nativeEvent.layout.height)}
                style={[styles.row, rowStyle(row), { minHeight: heightFor(row.key) }]}
              >
                {columns.map((col) => (
                  <View key={col.key} style={[styles.cell, { width: columnWidth(col) }]}>
                    {typeof row.values[col.key] === 'string' ||
                    typeof row.values[col.key] === 'number' ||
                    row.values[col.key] == null ? (
                      <Text allowFontScaling style={[styles.text, { color: theme.onSurface }]}>
                        {row.values[col.key] ?? '—'}
                      </Text>
                    ) : (
                      row.values[col.key]
                    )}
                  </View>
                ))}
              </View>
            ))}
          </View>
        </Reanimated.ScrollView>
        <Reanimated.View
          pointerEvents="box-none"
          style={[
            {
              position: 'absolute',
              top: 0,
              left: 0,
              right: 0,
              zIndex: 5,
              flexDirection: isRtl ? 'row-reverse' : 'row',
              backgroundColor: theme.card,
              borderBottomColor: theme.outlineVariant,
              borderBottomWidth: StyleSheet.hairlineWidth,
            },
            pinned,
          ]}
        >
          <View style={{ width: identityWidth, flexShrink: 0 }}>
            <View style={[styles.identity, styles.header, { height: heightFor('header') }]}>
              <Text
                allowFontScaling
                style={[styles.text, { color: theme.onSurfaceVariant }]}
                onTextLayout={(e) =>
                  measureRow(
                    'header',
                    e.nativeEvent.lines.reduce((sum, line) => sum + line.height, 0) + 24,
                  )
                }
              >
                {identityLabel}
              </Text>
            </View>
          </View>
          <View style={{ width: Math.max(0, viewportWidth - identityWidth), overflow: 'hidden' }}>
            <Reanimated.View
              style={[{ width: minimumWidth + extraWidth * columns.length }, horizontalHeader]}
            >
              <View
                onLayout={(e) => measureRow('header', e.nativeEvent.layout.height)}
                style={[styles.row, styles.header, { minHeight: heightFor('header') }]}
              >
                {columns.map((col) => (
                  <View key={col.key} style={[styles.cell, { width: columnWidth(col) }]}>
                    <View
                      style={{
                        flexDirection: 'row',
                        alignItems: 'center',
                        gap: 5,
                        maxWidth: '100%',
                      }}
                    >
                      {col.image ? (
                        <MobileWebImage
                          imageUrl={col.image}
                          contentFit="contain"
                          style={{ width: 20, height: 23 }}
                        />
                      ) : null}
                      <Text
                        allowFontScaling
                        style={[styles.text, { flexShrink: 1, color: theme.onSurfaceVariant }]}
                      >
                        {col.label}
                      </Text>
                    </View>
                  </View>
                ))}
              </View>
            </Reanimated.View>
          </View>
        </Reanimated.View>
      </Reanimated.View>
    </View>
  );
}
const styles = StyleSheet.create({
  shell: { borderRadius: 10, overflow: 'hidden', width: '100%' },
  identity: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 10,
  },
  header: { minHeight: 48 },
  row: { flexDirection: 'row', borderBottomWidth: StyleSheet.hairlineWidth, alignItems: 'stretch' },
  cell: {
    flexShrink: 0,
    paddingHorizontal: 10,
    paddingVertical: 10,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 5,
  },
  icon: { width: 24, height: 27, flexShrink: 0 },
  // Table values never animate or render skeletons. Native Text avoids creating
  // an Animated.Text host and its subscriptions for every offscreen cell.
  label: { ...ckTypography.bodySmall, flex: 1, fontSize: 12, lineHeight: 17 },
  text: {
    ...ckTypography.bodySmall,
    fontSize: 12,
    lineHeight: 17,
    textAlign: 'center',
    fontVariant: ['tabular-nums'],
  },
});
