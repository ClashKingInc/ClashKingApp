import { useMemo, useState } from 'react';
import {
  Modal,
  PanResponder,
  Pressable,
  StyleSheet,
  View,
  type AccessibilityActionEvent,
} from 'react-native';
import { Clock3, Shield } from 'lucide-react-native';

import { useI18n } from '../../../i18n';
import { CKText, GlassSurface, Surface, ckRadius, colorWithAlpha, useCKTheme } from '../../../ui';

export type WarStatsRangeMode = 'wars' | 'days';

export interface WarStatsRangeSelection {
  readonly mode: WarStatsRangeMode;
  readonly wars: number;
  readonly days: number;
}

export function ClanWarStatsRangeModal({
  initialMode,
  initialWarRange,
  initialDayRange,
  onClose,
  onApply,
}: {
  initialMode: WarStatsRangeMode;
  initialWarRange: number;
  initialDayRange: number;
  onClose: () => void;
  onApply: (selection: WarStatsRangeSelection) => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [mode, setMode] = useState(initialMode);
  const [wars, setWars] = useState(initialWarRange);
  const [days, setDays] = useState(initialDayRange);
  const usingWars = mode === 'wars';
  const value = usingWars ? wars : days;
  const minimum = usingWars ? 10 : 7;
  const maximum = usingWars ? 100 : 365;
  const step = usingWars ? 5 : 1;
  const rangeLabel = usingWars ? 'Wars to include' : 'Days to include';

  const reset = () => {
    setMode('wars');
    setWars(50);
    setDays(90);
  };

  return (
    <Modal visible transparent animationType="slide" onRequestClose={onClose}>
      <View style={styles.overlay}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={t('generalCancel')}
          onPress={onClose}
          style={StyleSheet.absoluteFill}
        />
        <Surface radius={ckRadius.card} style={styles.sheet}>
          <View
            style={[styles.dragHandle, { backgroundColor: colorWithAlpha(theme.onSurface, 0.32) }]}
          />
          <CKText role="titleLarge" style={styles.title}>
            War stats range
          </CKText>
          <CKText muted>
            Choose whether the stats cover a fixed number of recent wars or a recent span of days.
          </CKText>

          <GlassSurface cornerRadius={ckRadius.pill} style={styles.segmented}>
            {(['wars', 'days'] as const).map((value) => {
              const selected = mode === value;
              return (
                <Pressable
                  key={value}
                  accessibilityRole="radio"
                  accessibilityState={{ selected }}
                  accessibilityLabel={value === 'wars' ? t('warStatsWars') : 'Days'}
                  onPress={() => setMode(value)}
                  style={styles.segmentButton}
                >
                  <View
                    style={[
                      styles.segmentFill,
                      selected && {
                        backgroundColor: colorWithAlpha(theme.primary, 0.16),
                        borderColor: colorWithAlpha(theme.primary, 0.42),
                      },
                    ]}
                  >
                    <CKText role="labelLarge" style={selected && { color: theme.primary }}>
                      {value === 'wars' ? t('warStatsWars') : 'Days'}
                    </CKText>
                  </View>
                </Pressable>
              );
            })}
          </GlassSurface>

          <View style={styles.rangeHeader}>
            {usingWars ? (
              <Shield size={18} color={theme.primary} />
            ) : (
              <Clock3 size={18} color={theme.primary} />
            )}
            <CKText role="rowTitle" style={styles.grow}>
              {rangeLabel}
            </CKText>
            <CKText role="labelLarge" style={{ color: theme.primary }}>
              {value}
            </CKText>
          </View>
          <RangeSlider
            key={mode}
            label={rangeLabel}
            value={value}
            minimum={minimum}
            maximum={maximum}
            step={step}
            onChange={usingWars ? setWars : setDays}
          />
          <View style={styles.rangeBounds}>
            <CKText>{minimum}</CKText>
            <CKText>{maximum}</CKText>
          </View>

          <View style={styles.actions}>
            <Pressable accessibilityRole="button" onPress={reset} style={styles.actionButton}>
              <CKText>{t('generalReset')}</CKText>
            </Pressable>
            <Pressable
              accessibilityRole="button"
              onPress={() => onApply({ mode, wars, days })}
              style={[
                styles.applyButton,
                { backgroundColor: theme.primary, borderColor: theme.primary },
              ]}
            >
              <CKText style={{ color: theme.onPrimary }}>{t('generalApply')}</CKText>
            </Pressable>
          </View>
        </Surface>
      </View>
    </Modal>
  );
}

function RangeSlider({
  label,
  value,
  minimum,
  maximum,
  step,
  onChange,
}: {
  label: string;
  value: number;
  minimum: number;
  maximum: number;
  step: number;
  onChange: (value: number) => void;
}) {
  const theme = useCKTheme();
  const [width, setWidth] = useState(0);
  const range = maximum - minimum;
  const updateFromPosition = (position: number) => {
    if (width <= 0 || range <= 0) return;
    const raw = minimum + (position / width) * range;
    const stepped = minimum + Math.round((raw - minimum) / step) * step;
    onChange(Math.max(minimum, Math.min(maximum, stepped)));
  };
  const responder = useMemo(
    () =>
      PanResponder.create({
        onStartShouldSetPanResponder: () => true,
        onMoveShouldSetPanResponder: () => true,
        onPanResponderGrant: (event) => updateFromPosition(event.nativeEvent.locationX),
        onPanResponderMove: (event) => updateFromPosition(event.nativeEvent.locationX),
      }),
    // Width and range changes intentionally rebuild the responder's position mapping.
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [maximum, minimum, range, step, width],
  );
  const fraction = range > 0 ? (value - minimum) / range : 0;
  const adjust = (event: AccessibilityActionEvent) => {
    if (event.nativeEvent.actionName === 'increment') {
      onChange(Math.min(maximum, value + step));
    } else if (event.nativeEvent.actionName === 'decrement') {
      onChange(Math.max(minimum, value - step));
    }
  };

  return (
    <View
      accessibilityRole="adjustable"
      accessibilityLabel={label}
      accessibilityValue={{ min: minimum, max: maximum, now: value }}
      accessibilityActions={[{ name: 'increment' }, { name: 'decrement' }]}
      onAccessibilityAction={adjust}
      onLayout={(event) => setWidth(event.nativeEvent.layout.width)}
      style={styles.slider}
      {...responder.panHandlers}
    >
      <View style={[styles.sliderTrack, { backgroundColor: theme.surfaceContainerHighest }]} />
      <View
        style={[
          styles.sliderFill,
          { backgroundColor: theme.primary, width: `${Math.max(0, Math.min(1, fraction)) * 100}%` },
        ]}
      />
      <View
        style={[
          styles.sliderThumb,
          {
            backgroundColor: theme.primary,
            borderColor: theme.surface,
            left: `${Math.max(0, Math.min(1, fraction)) * 100}%`,
          },
        ]}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  overlay: { flex: 1, justifyContent: 'flex-end', backgroundColor: '#00000066' },
  sheet: {
    width: '100%',
    maxWidth: 760,
    alignSelf: 'center',
    paddingHorizontal: 20,
    paddingBottom: 20,
    gap: 16,
  },
  dragHandle: { width: 32, height: 4, borderRadius: 2, alignSelf: 'center', marginTop: 8 },
  title: { fontWeight: '800', marginBottom: -12 },
  segmented: { minHeight: 52, flexDirection: 'row', padding: 4 },
  segmentButton: { flex: 1 },
  segmentFill: {
    minHeight: 44,
    borderRadius: ckRadius.pill,
    borderWidth: 1,
    borderColor: 'transparent',
    alignItems: 'center',
    justifyContent: 'center',
  },
  rangeHeader: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  grow: { flex: 1 },
  slider: { height: 34, justifyContent: 'center', marginHorizontal: 8 },
  sliderTrack: { height: 4, borderRadius: 2 },
  sliderFill: { position: 'absolute', left: 0, height: 4, borderRadius: 2 },
  sliderThumb: {
    position: 'absolute',
    width: 20,
    height: 20,
    marginLeft: -10,
    borderRadius: 10,
    borderWidth: 2,
  },
  rangeBounds: { flexDirection: 'row', justifyContent: 'space-between' },
  actions: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  actionButton: { minHeight: 44, justifyContent: 'center', paddingHorizontal: 12 },
  applyButton: {
    minHeight: 44,
    minWidth: 92,
    borderRadius: ckRadius.control,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 18,
  },
});
