import type { ReactNode } from 'react';
import {
  Pressable,
  StyleSheet,
  TextInput,
  View,
  type StyleProp,
  type ViewStyle,
} from 'react-native';

import { GlassSurface } from './glass';
import { tintIcon } from './icon-slot';
import { CKText } from './text';
import { ckControlHeight, ckRadius, ckSpacing } from './tokens';
import { useCKTheme } from './theme';

export type SearchSortBarProps = {
  value: string;
  onChangeText: (value: string) => void;
  placeholder: string;
  searchLabel?: string;
  searchIcon?: ReactNode;
  sortLabel: string;
  sortValue?: string;
  sortIcon?: ReactNode;
  onSortPress: () => void;
  style?: StyleProp<ViewStyle>;
};

export type SearchFieldProps = Pick<
  SearchSortBarProps,
  'value' | 'onChangeText' | 'placeholder' | 'searchLabel' | 'searchIcon' | 'style'
>;

export function SearchField({
  value,
  onChangeText,
  placeholder,
  searchLabel,
  searchIcon,
  style,
}: SearchFieldProps) {
  const theme = useCKTheme();
  return (
    <GlassSurface
      cornerRadius={ckRadius.pill}
      style={[styles.search, style]}
      testID="search-sort-search"
    >
      {tintIcon(searchIcon, theme.onSurfaceVariant)}
      <TextInput
        accessibilityLabel={searchLabel ?? placeholder}
        allowFontScaling
        autoCapitalize="none"
        autoCorrect={false}
        clearButtonMode="while-editing"
        onChangeText={onChangeText}
        placeholder={placeholder}
        placeholderTextColor={theme.onSurfaceVariant}
        returnKeyType="search"
        style={[styles.input, { color: theme.onSurface }]}
        value={value}
      />
    </GlassSurface>
  );
}

export function SearchSortBar({
  value,
  onChangeText,
  placeholder,
  searchLabel,
  searchIcon,
  sortLabel,
  sortValue,
  sortIcon,
  onSortPress,
  style,
}: SearchSortBarProps) {
  const theme = useCKTheme();
  return (
    <View style={[styles.row, style]}>
      <SearchField
        value={value}
        onChangeText={onChangeText}
        placeholder={placeholder}
        searchLabel={searchLabel}
        searchIcon={searchIcon}
      />
      <Pressable accessibilityRole="button" accessibilityLabel={sortLabel} onPress={onSortPress}>
        <GlassSurface
          cornerRadius={ckRadius.chip}
          interactive
          style={styles.sort}
          testID="search-sort-control"
        >
          {tintIcon(sortIcon, theme.onSurface)}
          {sortValue ? (
            <CKText role="labelLarge" numberOfLines={1}>
              {sortValue}
            </CKText>
          ) : null}
        </GlassSurface>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  search: {
    height: ckControlHeight.compact,
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    gap: ckSpacing.sm,
    paddingHorizontal: ckSpacing.md,
  },
  input: {
    height: ckControlHeight.compact,
    flex: 1,
    fontFamily: 'ClashKing',
    fontSize: 14,
    fontWeight: '500',
    paddingVertical: 0,
  },
  sort: {
    minWidth: 40,
    height: 40,
    maxWidth: 160,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: ckSpacing.sm,
    paddingHorizontal: ckSpacing.md,
  },
});
