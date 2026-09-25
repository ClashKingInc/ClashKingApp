import type { ReactNode } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { ChevronLeft, ChevronRight } from 'lucide-react-native';

import { materialNextPageTooltip, materialPreviousPageTooltip, useI18n } from '../i18n';
import { CKText } from './text';
import { useCKTheme } from './theme';

/** The day navigation used by Legends, with an optional calendar action on its label. */
export function DateNavigator({
  label,
  onPrevious,
  onNext,
  onPressLabel,
  previousDisabled = false,
  nextDisabled = false,
  accessibilityLabel,
  children,
}: {
  label: string;
  onPrevious: () => void;
  onNext: () => void;
  onPressLabel?: () => void;
  previousDisabled?: boolean;
  nextDisabled?: boolean;
  accessibilityLabel?: string;
  children?: ReactNode;
}) {
  const { locale } = useI18n();
  const theme = useCKTheme();
  const center = (
    <>
      <CKText role="rowTitle">{label}</CKText>
      {children}
    </>
  );
  return (
    <View accessibilityLabel={accessibilityLabel} style={styles.dayNavigation}>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={materialPreviousPageTooltip(locale)}
        accessibilityState={{ disabled: previousDisabled }}
        disabled={previousDisabled}
        onPress={onPrevious}
        style={[styles.dayNavigationButton, previousDisabled && styles.disabled]}
      >
        <ChevronLeft color={theme.onSurface} size={26} />
      </Pressable>
      {onPressLabel ? (
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={label}
          onPress={onPressLabel}
          style={styles.dayNavigationLabel}
        >
          {center}
        </Pressable>
      ) : (
        <View style={styles.dayNavigationLabel}>{center}</View>
      )}
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={materialNextPageTooltip(locale)}
        accessibilityState={{ disabled: nextDisabled }}
        disabled={nextDisabled}
        onPress={onNext}
        style={[styles.dayNavigationButton, nextDisabled && styles.disabled]}
      >
        <ChevronRight color={theme.onSurface} size={26} />
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  dayNavigation: {
    minHeight: 62,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 8,
  },
  dayNavigationLabel: {
    flex: 1,
    minHeight: 44,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 2,
  },
  dayNavigationButton: {
    minWidth: 44,
    minHeight: 44,
    alignItems: 'center',
    justifyContent: 'center',
  },
  disabled: { opacity: 0.35 },
});
