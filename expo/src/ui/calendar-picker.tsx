import { useMemo, useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { ChevronLeft, ChevronRight } from 'lucide-react-native';

import { toIntlLocale, useI18n } from '../i18n';
import { materialNextMonthTooltip, materialPreviousMonthTooltip } from '../i18n/material-labels';
import { CKText } from './text';
import { ckRadius, ckSpacing, colorWithAlpha } from './tokens';
import { useCKTheme } from './theme';

export function CalendarPicker({
  start,
  end,
  minimum,
  maximum,
  range = false,
  onChange,
}: {
  start: Date;
  end?: Date;
  minimum: Date;
  maximum: Date;
  range?: boolean;
  onChange: (start: Date, end?: Date) => void;
}) {
  const { locale } = useI18n();
  const theme = useCKTheme();
  const [month, setMonth] = useState(() => firstOfMonth(start));
  const days = useMemo(() => calendarDays(month), [month]);
  const weekdayLabels = useMemo(() => weekdayNames(locale), [locale]);
  const select = (value: Date) => {
    if (!range) {
      onChange(value);
      return;
    }
    if (end || value < start) onChange(value, undefined);
    else onChange(start, value);
  };
  const previous = addMonths(month, -1);
  const next = addMonths(month, 1);
  return (
    <View accessibilityRole="summary" style={styles.container}>
      <View style={styles.header}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={materialPreviousMonthTooltip(locale)}
          disabled={endOfMonth(previous) < minimum}
          onPress={() => setMonth(previous)}
          style={styles.arrow}
        >
          <ChevronLeft color={theme.onSurface} />
        </Pressable>
        <CKText role="titleMedium">
          {new Intl.DateTimeFormat(toIntlLocale(locale), {
            month: 'long',
            year: 'numeric',
          }).format(month)}
        </CKText>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={materialNextMonthTooltip(locale)}
          disabled={next > maximum}
          onPress={() => setMonth(next)}
          style={styles.arrow}
        >
          <ChevronRight color={theme.onSurface} />
        </Pressable>
      </View>
      <View style={styles.week}>
        {weekdayLabels.map((label, index) => (
          <CKText key={`${label}-${index}`} role="labelSmall" muted style={styles.cell}>
            {label}
          </CKText>
        ))}
      </View>
      <View style={styles.grid}>
        {days.map((value, index) => {
          if (!value) return <View key={`blank-${index}`} style={styles.cell} />;
          const disabled = value < minimum || value > maximum;
          const selected = sameDay(value, start) || (end ? sameDay(value, end) : false);
          const within = Boolean(range && end && value > start && value < end);
          return (
            <Pressable
              key={value.toISOString()}
              accessibilityRole="button"
              accessibilityState={{ selected, disabled }}
              disabled={disabled}
              onPress={() => select(value)}
              style={[
                styles.cell,
                within && { backgroundColor: colorWithAlpha(theme.primary, 0.1) },
              ]}
            >
              <View style={[styles.day, selected && { backgroundColor: theme.primary }]}>
                <CKText
                  role="bodyMedium"
                  style={
                    selected
                      ? { color: theme.onPrimary }
                      : disabled
                        ? { color: colorWithAlpha(theme.onSurface, 0.3) }
                        : undefined
                  }
                >
                  {value.getDate()}
                </CKText>
              </View>
            </Pressable>
          );
        })}
      </View>
    </View>
  );
}

function calendarDays(month: Date): (Date | null)[] {
  const leading = new Date(month.getFullYear(), month.getMonth(), 1).getDay();
  const count = new Date(month.getFullYear(), month.getMonth() + 1, 0).getDate();
  const values: (Date | null)[] = Array.from({ length: leading }, () => null);
  for (let day = 1; day <= count; day += 1)
    values.push(new Date(month.getFullYear(), month.getMonth(), day));
  while (values.length % 7) values.push(null);
  return values;
}
function weekdayNames(locale: string): string[] {
  const sunday = new Date(2026, 7, 2);
  return Array.from({ length: 7 }, (_, index) =>
    new Intl.DateTimeFormat(toIntlLocale(locale), { weekday: 'narrow' }).format(
      new Date(2026, 7, sunday.getDate() + index),
    ),
  );
}
function firstOfMonth(value: Date): Date {
  return new Date(value.getFullYear(), value.getMonth(), 1);
}
function endOfMonth(value: Date): Date {
  return new Date(value.getFullYear(), value.getMonth() + 1, 0);
}
function addMonths(value: Date, amount: number): Date {
  return new Date(value.getFullYear(), value.getMonth() + amount, 1);
}
function sameDay(left: Date, right: Date): boolean {
  return (
    left.getFullYear() === right.getFullYear() &&
    left.getMonth() === right.getMonth() &&
    left.getDate() === right.getDate()
  );
}

const styles = StyleSheet.create({
  container: { gap: ckSpacing.sm },
  header: {
    minHeight: 48,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  arrow: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  week: { flexDirection: 'row' },
  grid: { flexDirection: 'row', flexWrap: 'wrap' },
  cell: { width: '14.2857%', minHeight: 42, alignItems: 'center', justifyContent: 'center' },
  day: {
    width: 38,
    height: 38,
    borderRadius: ckRadius.pill,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
