import { useState, type ReactNode } from 'react';
import { Animated, Pressable, ScrollView, StyleSheet, View } from 'react-native';

import { DestinationPicker } from './destination-picker';
import { GlassSurface } from './glass';
import { tintIcon } from './icon-slot';
import { CKText } from './text';
import { ckControlHeight, ckRadius, ckSpacing, colorWithAlpha } from './tokens';
import { useCKTheme } from './theme';

export type ProfileTab = {
  key: string;
  label: string;
  icon?: ReactNode;
};

export type ProfileTabsProps = {
  tabs: readonly ProfileTab[];
  selectedKey: string;
  onSelect: (key: string) => void;
  overflowLabel?: string;
  onOverflowPress?: () => void;
  // Compact is legacy dense data chrome, not a section-navigation style.
  // For two-choice content switches use SlidingSegmentControl; profile
  // sections use underline. Do not revive compact tabs on new screens.
  variant?: 'glass' | 'underline' | 'compact';
  /** Fit keeps every section visible; useful for four short, text-only tabs. */
  overflow?: 'menu' | 'scroll' | 'fit';
  /** Optional continuous position from a pager; other profile tabs keep their existing behavior. */
  animatedPosition?: Animated.Value;
  indicatorRtl?: boolean;
};

export function ProfileTabs({
  tabs,
  selectedKey,
  onSelect,
  overflowLabel,
  onOverflowPress,
  variant = 'glass',
  overflow = 'menu',
  animatedPosition,
  indicatorRtl = false,
}: ProfileTabsProps) {
  const theme = useCKTheme();
  const [underlineWidth, setUnderlineWidth] = useState(0);
  const followsPager = !!animatedPosition && overflow !== 'scroll' && tabs.length > 1;
  const selected = tabs.find((tab) => tab.key === selectedKey) ?? tabs[0];

  if (tabs.length > 3 && overflow === 'menu') {
    return (
      <DestinationPicker
        accessibilityLabel={overflowLabel ?? selected?.label}
        externallyManaged={onOverflowPress !== undefined}
        onOpen={onOverflowPress}
        onSelect={onSelect}
        options={tabs}
        selectedKey={selectedKey}
        showPositionHint
      />
    );
  }

  if (variant === 'underline') {
    const underlineTabs = tabs.map((tab) => {
      const isSelected = tab.key === selectedKey;
      return (
        <Pressable
          key={tab.key}
          testID={`profile-tabs-underline-tab-${tab.key}`}
          accessibilityRole="tab"
          accessibilityState={{ selected: isSelected }}
          accessibilityLabel={tab.label}
          onPress={() => onSelect(tab.key)}
          style={[
            styles.underlineTab,
            overflow === 'scroll' ? styles.underlineScrollTab : { flex: 1 },
          ]}
        >
          {tintIcon(tab.icon, colorWithAlpha(theme.onSurface, isSelected ? 1 : 0.64))}
          <CKText
            skeleton={false}
            role="labelLarge"
            style={{ color: colorWithAlpha(theme.onSurface, isSelected ? 1 : 0.64) }}
          >
            {tab.label}
          </CKText>
          {isSelected && !followsPager ? (
            <View style={[styles.underlineIndicator, { backgroundColor: theme.primary }]} />
          ) : null}
        </Pressable>
      );
    });
    const underlineStyle = [
      styles.underlineBar,
      { borderBottomColor: colorWithAlpha(theme.outlineVariant, 0.35) },
    ];
    return overflow === 'scroll' ? (
      <ScrollView
        testID="profile-tabs-underline-scroll"
        horizontal
        showsHorizontalScrollIndicator={false}
        style={underlineStyle}
        contentContainerStyle={styles.underlineScrollContent}
      >
        {underlineTabs}
      </ScrollView>
    ) : (
      <View
        testID="profile-tabs-underline"
        style={[
          underlineStyle,
          followsPager && { flexDirection: indicatorRtl ? 'row-reverse' : 'row' },
        ]}
        onLayout={(event) => setUnderlineWidth(event.nativeEvent.layout.width)}
      >
        {underlineTabs}
        {followsPager && underlineWidth > 0 ? (
          <Animated.View
            pointerEvents="none"
            style={{
              position: 'absolute',
              left: 0,
              bottom: 0,
              height: 2.5,
              width: underlineWidth / tabs.length,
              backgroundColor: theme.primary,
              transform: [
                {
                  translateX: animatedPosition!.interpolate({
                    inputRange: [0, tabs.length - 1],
                    outputRange: indicatorRtl
                      ? [underlineWidth - underlineWidth / tabs.length, 0]
                      : [0, underlineWidth - underlineWidth / tabs.length],
                    extrapolate: 'clamp',
                  }),
                },
              ],
            }}
          />
        ) : null}
      </View>
    );
  }

  if (variant === 'compact') {
    return (
      <View
        testID="profile-tabs-compact"
        style={[
          styles.compactBar,
          {
            backgroundColor: colorWithAlpha(theme.onSurface, 0.06),
            borderColor: colorWithAlpha(theme.outlineVariant, 0.32),
          },
        ]}
      >
        {tabs.map((tab) => {
          const isSelected = tab.key === selectedKey;
          return (
            <Pressable
              key={tab.key}
              testID={`profile-tabs-compact-tab-${tab.key}`}
              accessibilityRole="tab"
              accessibilityState={{ selected: isSelected }}
              accessibilityLabel={tab.label}
              onPress={() => onSelect(tab.key)}
              style={[
                styles.compactTab,
                isSelected && { backgroundColor: colorWithAlpha(theme.onSurface, 0.12) },
              ]}
            >
              <CKText skeleton={false} role="labelSmall">
                {tab.label}
              </CKText>
            </Pressable>
          );
        })}
      </View>
    );
  }

  return (
    <GlassSurface cornerRadius={ckRadius.card} style={styles.tabBar}>
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.tabContent}
      >
        {tabs.map((tab) => {
          const isSelected = tab.key === selectedKey;
          return (
            <Pressable
              key={tab.key}
              accessibilityRole="tab"
              accessibilityState={{ selected: isSelected }}
              accessibilityLabel={tab.label}
              onPress={() => onSelect(tab.key)}
              style={[
                styles.tab,
                isSelected && { backgroundColor: colorWithAlpha(theme.primary, 0.14) },
              ]}
            >
              {tintIcon(tab.icon, isSelected ? theme.primary : theme.onSurfaceVariant)}
              <CKText
                skeleton={false}
                role="labelLarge"
                style={isSelected ? { color: theme.primary } : undefined}
              >
                {tab.label}
              </CKText>
            </Pressable>
          );
        })}
      </ScrollView>
    </GlassSurface>
  );
}

const styles = StyleSheet.create({
  underlineBar: {
    height: 50,
    flexDirection: 'row',
    borderBottomWidth: StyleSheet.hairlineWidth,
  },
  underlineTab: {
    height: 50,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: ckSpacing.sm,
  },
  underlineScrollContent: { flexDirection: 'row', alignItems: 'stretch' },
  // Keep intrinsic label widths in horizontal web scroll views. `flex: 0`
  // becomes a zero flex-basis there and makes the labels overlap.
  underlineScrollTab: { flexGrow: 0, flexShrink: 0, paddingHorizontal: ckSpacing.lg },
  underlineIndicator: {
    position: 'absolute',
    right: 0,
    bottom: 0,
    left: 0,
    height: 2.5,
  },
  compactBar: {
    height: 32,
    flexDirection: 'row',
    padding: 2,
    borderWidth: StyleSheet.hairlineWidth,
    borderRadius: 8,
  },
  compactTab: {
    flex: 1,
    minWidth: 72,
    height: 28,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 6,
  },
  tabBar: { minHeight: 50 },
  tabContent: { flexGrow: 1, padding: 3, gap: ckSpacing.xs },
  tab: {
    minWidth: 104,
    minHeight: ckControlHeight.compact,
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: ckSpacing.sm,
    paddingHorizontal: ckSpacing.md,
    borderRadius: ckRadius.tile,
  },
});
