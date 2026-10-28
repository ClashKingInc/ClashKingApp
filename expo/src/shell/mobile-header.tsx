import type { ReactNode } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { Menu, Search } from 'lucide-react-native';
import { TutorialTarget } from '../features/tutorials/tutorial-ui';
import { GlobalSearchHeaderFrame, globalSearchHeaderLayout } from '../ui/header';
import { useTabletTypography } from '../ui/typography-context';

import {
  CKText,
  GlassControlSurface,
  GlassSurface,
  colorWithAlpha,
  useCKTheme,
  useCKThemeMode,
} from '../ui';

export function MobileHeader({
  avatar,
  profileLabel,
  searchHint,
  onOpenProfile,
  onSearch,
  isRtl = false,
  maxContentWidth,
  searchMaxWidth,
  pageTitle,
  alignSearchToEnd = false,
}: {
  avatar: ReactNode;
  profileLabel: string;
  searchHint: string;
  onOpenProfile: () => void;
  onSearch?: () => void;
  isRtl?: boolean;
  maxContentWidth?: number;
  searchMaxWidth?: number;
  /** Expanded layouts use a title and trailing search as two balanced groups. */
  pageTitle?: string;
  alignSearchToEnd?: boolean;
}) {
  const theme = useCKTheme();
  const mode = useCKThemeMode();
  const tablet = useTabletTypography();
  return (
    <GlobalSearchHeaderFrame style={styles.safeArea}>
      <View
        style={[
          styles.header,
          tablet && { height: 78, gap: 14 },
          isRtl && styles.rowRtl,
          maxContentWidth
            ? { width: '100%', maxWidth: maxContentWidth + 32, alignSelf: 'center' }
            : undefined,
        ]}
      >
        <TutorialTarget id="sidebar-open">
          <GlassSurface
            cornerRadius={23}
            interactive
            style={[
              styles.profileGlass,
              tablet && { width: 54, height: 54 },
              {
                borderColor: colorWithAlpha(theme.outlineVariant, mode === 'dark' ? 0.16 : 0.32),
                shadowOpacity: mode === 'dark' ? 0.14 : 0.1,
              },
            ]}
          >
            <Pressable
              accessibilityLabel={profileLabel}
              accessibilityRole="button"
              onPress={onOpenProfile}
              style={({ pressed }) => [styles.profileButton, pressed && styles.pressed]}
            >
              <View style={styles.avatar}>{avatar}</View>
              <View
                accessibilityElementsHidden
                importantForAccessibility="no-hide-descendants"
                pointerEvents="none"
                style={[
                  styles.menuBadge,
                  isRtl ? styles.menuBadgeRtl : styles.menuBadgeLtr,
                  {
                    backgroundColor: theme.surface,
                    borderColor: colorWithAlpha(
                      theme.outlineVariant,
                      mode === 'dark' ? 0.24 : 0.36,
                    ),
                  },
                ]}
                testID="profile-menu-indicator"
              >
                <Menu color={theme.onSurfaceVariant} size={11} strokeWidth={2.4} />
              </View>
            </Pressable>
          </GlassSurface>
        </TutorialTarget>
        {pageTitle ? (
          <CKText role="titleLarge" numberOfLines={1} style={styles.pageTitle}>
            {pageTitle}
          </CKText>
        ) : alignSearchToEnd ? (
          <View style={styles.headerSpacer} />
        ) : null}
        {onSearch && (
          <GlassControlSurface
            style={[
              styles.searchGlass,
              tablet && { height: 54 },
              (pageTitle || alignSearchToEnd) && styles.trailingSearch,
              searchMaxWidth ? { maxWidth: searchMaxWidth } : undefined,
            ]}
            testID="mobile-global-search-glass"
          >
            <Pressable
              accessibilityLabel={searchHint}
              accessibilityRole="search"
              onPress={onSearch}
              style={({ pressed }) => [
                styles.searchButton,
                isRtl && styles.rowRtl,
                pressed && styles.pressed,
              ]}
            >
              <Search color={theme.onSurfaceVariant} size={20} />
              <CKText muted numberOfLines={1} style={styles.searchText}>
                {searchHint}
              </CKText>
            </Pressable>
          </GlassControlSurface>
        )}
      </View>
    </GlobalSearchHeaderFrame>
  );
}

const styles = StyleSheet.create({
  safeArea: { backgroundColor: 'transparent' },
  header: {
    height: globalSearchHeaderLayout.height,
    paddingHorizontal: globalSearchHeaderLayout.paddingHorizontal,
    flexDirection: 'row',
    alignItems: 'center',
    gap: globalSearchHeaderLayout.gap,
  },
  profileGlass: { width: globalSearchHeaderLayout.leadingWidth, height: 46 },
  profileButton: { flex: 1, alignItems: 'center', justifyContent: 'center', position: 'relative' },
  avatar: {
    width: 36,
    height: 36,
    borderRadius: 18,
    overflow: 'hidden',
    alignItems: 'center',
    justifyContent: 'center',
  },
  menuBadge: {
    position: 'absolute',
    bottom: 2,
    width: 18,
    height: 18,
    borderRadius: 9,
    borderWidth: StyleSheet.hairlineWidth,
    alignItems: 'center',
    justifyContent: 'center',
  },
  menuBadgeLtr: { right: 1 },
  menuBadgeRtl: { left: 1 },
  searchGlass: {
    flex: 1,
    height: globalSearchHeaderLayout.fieldHeight,
  },
  searchButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 14,
    gap: 8,
  },
  searchText: { flex: 1 },
  pageTitle: { flex: 1, minWidth: 0, fontWeight: '700' },
  headerSpacer: { flex: 1 },
  // Reset the original flex:1 basis as well as growth; otherwise Yoga keeps a
  // zero basis and the bounded field collapses despite a valid accessibility node.
  trailingSearch: { flex: 0, flexBasis: 'auto', flexShrink: 1, width: '42%', marginStart: 12 },
  pressed: { opacity: 0.72 },
  rowRtl: { flexDirection: 'row-reverse' },
});
