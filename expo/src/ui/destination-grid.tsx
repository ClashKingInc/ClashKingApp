import { StyleSheet, View, useWindowDimensions } from 'react-native';
import Svg, { Defs, LinearGradient, Rect, Stop } from 'react-native-svg';

import { CKText } from './text';
import { MobileWebImage } from './mobile-web-image';
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
    imageUrl?: string;
    accentColor?: string;
    onPress: () => void;
  }[];
};

/** Shared entry navigation; each destination keeps a complete, wrapping label. */
export function DestinationGrid({
  groups,
  initialWidth,
}: {
  groups: readonly DestinationGridGroup[];
  initialWidth?: number;
}) {
  const { fontScale } = useWindowDimensions();
  const theme = useCKTheme();
  return (
    <View style={{ gap: ckSpacing.lg }}>
      {groups.map((group) => (
        <View key={group.key} style={{ gap: ckSpacing.md }}>
          {group.title ? <CKText role="sectionTitle">{group.title}</CKText> : null}
          <ResponsiveGrid
            minItemWidth={136 * Math.max(1, fontScale)}
            maxColumns={4}
            fillLastRow={group.fillLastRow}
            initialWidth={initialWidth}
            testID={`destination-grid-${group.key}`}
          >
            {group.items.map((item) => (
              <PressableSurface
                key={item.key}
                testID={`destination-${item.key}`}
                accessibilityRole="button"
                accessibilityLabel={item.label}
                onPress={item.onPress}
                radius={ckRadius.tile}
                style={{
                  flex: 1,
                  minWidth: 0,
                  minHeight: 84,
                  padding: ckSpacing.md,
                  gap: ckSpacing.sm,
                  flexDirection: 'row',
                  alignItems: 'center',
                  overflow: 'hidden',
                  borderColor: colorWithAlpha(item.accentColor ?? theme.secondary, 0.18),
                }}
              >
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
                          stopOpacity={0.16}
                        />
                        <Stop
                          offset="1"
                          stopColor={item.accentColor ?? theme.secondary}
                          stopOpacity={0.015}
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
                {item.imageUrl ? (
                  <MobileWebImage
                    testID={`destination-art-${item.key}`}
                    imageUrl={item.imageUrl}
                    contentFit="contain"
                    style={{ width: 44, height: 44, flexShrink: 0 }}
                  />
                ) : null}
                <View style={{ flex: 1, minWidth: 0, justifyContent: 'center' }}>
                  <CKText role="bodyMedium">{item.label}</CKText>
                </View>
              </PressableSurface>
            ))}
          </ResponsiveGrid>
        </View>
      ))}
    </View>
  );
}
