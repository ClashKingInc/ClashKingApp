import type { ReactNode } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { Goal, Search, UserCog } from 'lucide-react-native';

import { CKText, ckColors, colorWithAlpha, useCKTheme } from '../ui';

export function DesktopHeader({
  title,
  searchHint,
  achievementsLabel,
  accountsLabel,
  contentWidth,
  onSearch,
  onAchievements,
  onAccounts,
  trailing,
  isRtl = false,
}: {
  title: string;
  searchHint: string;
  achievementsLabel: string;
  accountsLabel: string;
  contentWidth: number;
  onSearch?: () => void;
  onAchievements: () => void;
  onAccounts: () => void;
  trailing?: ReactNode;
  isRtl?: boolean;
}) {
  const theme = useCKTheme();
  const compact = contentWidth < 820;
  const actions = (
    <View style={[styles.actions, isRtl && styles.rowRtl, !compact && styles.fixedActions]}>
      {onSearch && (
        <Pressable
          accessibilityLabel={searchHint}
          accessibilityRole="search"
          onPress={onSearch}
          style={({ pressed }) => [
            styles.search,
            {
              backgroundColor: colorWithAlpha(theme.surfaceContainerHighest, 0.42),
              borderColor: colorWithAlpha(theme.outlineVariant, 0.34),
            },
            pressed && styles.pressed,
          ]}
        >
          <Search color={theme.onSurfaceVariant} size={20} />
          <CKText muted numberOfLines={1} style={styles.searchText}>
            {searchHint}
          </CKText>
        </Pressable>
      )}
      <HeaderAction label={achievementsLabel} onPress={onAchievements}>
        <Goal color={ckColors.warGold} size={22} />
      </HeaderAction>
      <HeaderAction label={accountsLabel} onPress={onAccounts}>
        <UserCog color={theme.onSurface} size={22} />
      </HeaderAction>
      {trailing}
    </View>
  );
  return (
    <View style={[styles.header, { borderBottomColor: colorWithAlpha(theme.outlineVariant, 0.2) }]}>
      {compact ? (
        <View style={styles.compactContent}>
          <CKText role="screenTitle" numberOfLines={1} style={styles.titleText}>
            {title}
          </CKText>
          {actions}
        </View>
      ) : (
        <View style={[styles.row, isRtl && styles.rowRtl]}>
          <CKText role="screenTitle" numberOfLines={1} style={[styles.title, styles.titleText]}>
            {title}
          </CKText>
          {actions}
        </View>
      )}
    </View>
  );
}

function HeaderAction({
  children,
  label,
  onPress,
}: {
  children: ReactNode;
  label: string;
  onPress: () => void;
}) {
  const theme = useCKTheme();
  return (
    <Pressable
      accessibilityLabel={label}
      accessibilityRole="button"
      onPress={onPress}
      style={({ pressed }) => [
        styles.action,
        {
          backgroundColor: colorWithAlpha(theme.surfaceContainerHighest, 0.42),
          borderColor: colorWithAlpha(theme.outlineVariant, 0.34),
        },
        pressed && styles.pressed,
      ]}
    >
      {children}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  header: {
    minHeight: 82,
    borderBottomWidth: StyleSheet.hairlineWidth,
    paddingLeft: 24,
    paddingTop: 16,
    paddingRight: 24,
    paddingBottom: 15,
    justifyContent: 'center',
  },
  row: { flexDirection: 'row', alignItems: 'center', gap: 24 },
  compactContent: { gap: 12 },
  title: { flex: 1 },
  titleText: { fontWeight: '800' },
  actions: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  fixedActions: { width: 520 },
  search: {
    height: 50,
    borderRadius: 16,
    borderWidth: StyleSheet.hairlineWidth,
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 14,
    gap: 8,
  },
  searchText: { flex: 1 },
  action: {
    width: 50,
    height: 50,
    borderRadius: 14,
    borderWidth: StyleSheet.hairlineWidth,
    alignItems: 'center',
    justifyContent: 'center',
  },
  pressed: { opacity: 0.72 },
  rowRtl: { flexDirection: 'row-reverse' },
});
