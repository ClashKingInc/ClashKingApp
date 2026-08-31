import type { ReactNode } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Search } from 'lucide-react-native';

import { CKText, GlassSurface, colorWithAlpha, useCKTheme, useCKThemeMode } from '../ui';

export function MobileHeader({
  avatar,
  profileLabel,
  searchHint,
  onOpenProfile,
  onSearch,
  isRtl = false,
}: {
  avatar: ReactNode;
  profileLabel: string;
  searchHint: string;
  onOpenProfile: () => void;
  onSearch?: () => void;
  isRtl?: boolean;
}) {
  const theme = useCKTheme();
  const mode = useCKThemeMode();
  return (
    <SafeAreaView edges={['top']} style={styles.safeArea}>
      <View style={[styles.header, isRtl && styles.rowRtl]}>
        <GlassSurface
          cornerRadius={23}
          interactive
          style={[
            styles.profileGlass,
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
          </Pressable>
        </GlassSurface>
        {onSearch && (
          <GlassSurface
            cornerRadius={24}
            interactive
            style={[
              styles.searchGlass,
              {
                borderColor: colorWithAlpha(theme.outlineVariant, mode === 'dark' ? 0.14 : 0.3),
                shadowOpacity: mode === 'dark' ? 0.12 : 0.08,
              },
            ]}
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
          </GlassSurface>
        )}
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: { backgroundColor: 'transparent' },
  header: {
    height: 64,
    paddingHorizontal: 16,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  profileGlass: { width: 46, height: 46 },
  profileButton: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  avatar: {
    width: 36,
    height: 36,
    borderRadius: 18,
    overflow: 'hidden',
    alignItems: 'center',
    justifyContent: 'center',
  },
  searchGlass: {
    flex: 1,
    height: 48,
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 3 },
    shadowRadius: 12,
  },
  searchButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 14,
    gap: 8,
  },
  searchText: { flex: 1 },
  pressed: { opacity: 0.72 },
  rowRtl: { flexDirection: 'row-reverse' },
});
