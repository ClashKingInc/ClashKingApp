import type { ReactNode } from 'react';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';

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
  variant?: 'glass' | 'underline' | 'compact';
};

export function ProfileTabs({
  tabs,
  selectedKey,
  onSelect,
  overflowLabel,
  onOverflowPress,
  variant = 'glass',
}: ProfileTabsProps) {
  const theme = useCKTheme();
  const selected = tabs.find((tab) => tab.key === selectedKey) ?? tabs[0];

  if (tabs.length > 3) {
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
    return (
      <View
        testID="profile-tabs-underline"
        style={[
          styles.underlineBar,
          { borderBottomColor: colorWithAlpha(theme.outlineVariant, 0.35) },
        ]}
      >
        {tabs.map((tab) => {
          const isSelected = tab.key === selectedKey;
          return (
            <Pressable
              key={tab.key}
              testID={`profile-tabs-underline-tab-${tab.key}`}
              accessibilityRole="tab"
              accessibilityState={{ selected: isSelected }}
              accessibilityLabel={tab.label}
              onPress={() => onSelect(tab.key)}
              style={styles.underlineTab}
            >
              {tintIcon(tab.icon, colorWithAlpha(theme.onSurface, isSelected ? 1 : 0.64))}
              <CKText
                role="labelLarge"
                style={{ color: colorWithAlpha(theme.onSurface, isSelected ? 1 : 0.64) }}
              >
                {tab.label}
              </CKText>
              {isSelected ? (
                <View style={[styles.underlineIndicator, { backgroundColor: theme.primary }]} />
              ) : null}
            </Pressable>
          );
        })}
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
              <CKText role="labelSmall">{tab.label}</CKText>
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
              <CKText role="labelLarge" style={isSelected ? { color: theme.primary } : undefined}>
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
    flex: 1,
    height: 50,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: ckSpacing.sm,
  },
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
