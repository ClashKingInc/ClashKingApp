import { useEffect } from 'react';
import { StyleSheet, View, useWindowDimensions } from 'react-native';
import Svg, { Defs, LinearGradient, Rect, Stop } from 'react-native-svg';

import { CKText } from './text';
import { MobileWebImage, prefetchMobileImage, headerArtworkSize } from './mobile-web-image';
import { PressableSurface } from './surfaces';
import { ckRadius, ckSpacing, colorWithAlpha } from './tokens';
import { ResponsiveGrid } from './responsive-grid';
import { useCKTheme } from './theme';

export type DestinationGridGroup = {
  key: string;
  title?: string;
  fillLastRow?: boolean;
  items: readonly {
    key: string;
    label: string;
    subtitle?: string;
    imageUrl?: string;
    backgroundUrl?: string;
    accentColor?: string;
    onPress: () => void;
  }[];
};

/** Shared entry navigation; each destination keeps a complete, wrapping label. */
export function DestinationGrid({
  groups,
  initialWidth,
  compact = false,
  featured = false,
  tileHeight,
  maxColumns,
  minItemWidth,
  roomy = false,
}: {
  groups: readonly DestinationGridGroup[];
  initialWidth?: number;
  /** Centered three-column launcher; other destination pages keep the roomy layout. */
  compact?: boolean;
  featured?: boolean;
  tileHeight?: number;
  maxColumns?: number;
  minItemWidth?: number;
  /** Room for expanded-device labels and artwork without changing phone launchers. */
  roomy?: boolean;
}) {
  const { fontScale, width, height } = useWindowDimensions();
  const shortViewport = height < 750;
  const imageSize = featured
    ? roomy
      ? 42
      : (tileHeight ?? 76) < 65
        ? 28
        : 34
    : compact
      ? shortViewport
        ? 20
        : 24
      : 44;
  const artwork = JSON.stringify([
    ...new Set(
      (featured ? [] : groups).flatMap((group) =>
        group.items.flatMap((item) => (item.backgroundUrl ? [item.backgroundUrl] : [])),
      ),
    ),
  ]);
  useEffect(() => {
    const size = headerArtworkSize(width);
    for (const url of JSON.parse(artwork) as string[])
      void prefetchMobileImage(url, size.width, size.height);
  }, [artwork, width]);
  const theme = useCKTheme();
  return (
    <View style={{ gap: roomy ? 24 : featured ? 10 : compact ? ckSpacing.md : ckSpacing.lg }}>
      {groups.map((group) => (
        <View key={group.key} style={{ gap: compact ? ckSpacing.sm : ckSpacing.md }}>
          {group.title ? (
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
              {featured ? (
                <View
                  style={{
                    width: 4,
                    height: 18,
                    borderRadius: 2,
                    backgroundColor: group.items[0]?.accentColor ?? theme.secondary,
                  }}
                />
              ) : null}
              <CKText
                role="sectionTitle"
                style={
                  compact
                    ? {
                        fontSize: roomy ? 22 : shortViewport ? 15 : 17,
                        lineHeight: roomy ? 28 : 22,
                      }
                    : undefined
                }
              >
                {group.title}
              </CKText>
            </View>
          ) : null}
          <ResponsiveGrid
            minItemWidth={(minItemWidth ?? (compact ? 88 : 136)) * Math.max(1, fontScale)}
            maxColumns={maxColumns ?? (compact ? 3 : 4)}
            gap={compact ? ckSpacing.sm : ckSpacing.md}
            fillLastRow={group.fillLastRow}
            initialWidth={initialWidth}
            testID={`destination-grid-${group.key}`}
          >
            {group.items.map((item) => (
              <PressableSurface
                key={item.key}
                testID={`destination-${item.key}`}
                accessibilityRole="button"
                accessibilityLabel={[item.label, item.subtitle].filter(Boolean).join('. ')}
                onPress={item.onPress}
                radius={compact ? ckRadius.chip : ckRadius.tile}
                style={{
                  flex: 1,
                  minWidth: 0,
                  // Keep full wrapping labels and a 44px+ touch target. Large
                  // accessibility type may use fewer columns and scroll.
                  minHeight: featured
                    ? (tileHeight ?? 76)
                    : compact
                      ? shortViewport
                        ? 59
                        : 70
                      : 84,
                  padding: roomy
                    ? 12
                    : featured
                      ? 3
                      : compact
                        ? shortViewport
                          ? 3
                          : 6
                        : ckSpacing.md,
                  gap: roomy ? 8 : compact ? (shortViewport ? 3 : 4) : ckSpacing.sm,
                  flexDirection: compact ? 'column' : 'row',
                  alignItems: 'center',
                  justifyContent: 'center',
                  overflow: 'hidden',
                  backgroundColor: featured
                    ? colorWithAlpha(group.items[0]?.accentColor ?? theme.secondary, 0.08)
                    : undefined,
                  borderWidth: featured ? 0 : undefined,
                  borderColor: featured
                    ? 'transparent'
                    : compact
                      ? 'transparent'
                      : colorWithAlpha(item.accentColor ?? theme.secondary, 0.18),
                }}
              >
                {!featured ? (
                  <View
                    testID={`destination-tint-${item.key}`}
                    pointerEvents="none"
                    style={StyleSheet.absoluteFill}
                  >
                    <Svg width="100%" height="100%">
                      <Defs>
                        <LinearGradient
                          id={`destination-tint-${group.key}-${item.key}`}
                          x1="0%"
                          y1="0%"
                          x2="100%"
                          y2="100%"
                        >
                          <Stop
                            offset="0"
                            stopColor={item.accentColor ?? theme.secondary}
                            stopOpacity={featured ? 0.32 : compact ? 0.09 : 0.16}
                          />
                          <Stop
                            offset="1"
                            stopColor={item.accentColor ?? theme.secondary}
                            stopOpacity={featured ? 0.08 : 0.015}
                          />
                        </LinearGradient>
                      </Defs>
                      <Rect
                        width="100%"
                        height="100%"
                        fill={`url(#destination-tint-${group.key}-${item.key})`}
                      />
                    </Svg>
                  </View>
                ) : null}
                {item.imageUrl ? (
                  <MobileWebImage
                    testID={`destination-art-${item.key}`}
                    imageUrl={item.imageUrl}
                    displaySize={{ width: 64, height: 64 }}
                    cachePolicy="memory-disk"
                    contentFit="contain"
                    style={{ width: imageSize, height: imageSize, flexShrink: 0 }}
                  />
                ) : null}
                <View
                  style={{ flex: compact ? undefined : 1, minWidth: 0, justifyContent: 'center' }}
                >
                  <CKText
                    role={compact ? 'bodySmall' : 'bodyMedium'}
                    style={
                      compact
                        ? {
                            textAlign: 'center',
                            lineHeight: roomy ? 22 : featured ? 15 : 14,
                            ...(featured ? { fontSize: roomy ? 16 : 12, fontWeight: '600' } : {}),
                          }
                        : undefined
                    }
                  >
                    {item.label}
                  </CKText>
                  {item.subtitle ? (
                    <CKText muted role="bodySmall">
                      {item.subtitle}
                    </CKText>
                  ) : null}
                </View>
              </PressableSurface>
            ))}
          </ResponsiveGrid>
        </View>
      ))}
    </View>
  );
}
