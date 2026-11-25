import { useLayoutEffect, useMemo, useRef, useState } from 'react';
import { PanResponder, Platform, Pressable, View, type KeyDownEvent } from 'react-native';
import { ChevronDown, ChevronUp, Minus, Plus } from '@/ui/icons';
import { useI18n } from '../i18n';
import { CKText } from './text';
import { useCKTheme } from './theme';

/** Keep pointer updates local; rebuilding stats or combinations waits for release. */
type LevelSliderProps = {
  value: number;
  minimum: number;
  maximum: number;
  label: string;
  accent?: string;
  showStepButtons?: boolean;
  compact?: boolean;
  valueLabel?: string;
  /** Optional exact milestones; omit for ordinary every-level controls. */
  steps?: readonly number[];
  /** Lightweight preview only; expensive work belongs in onChange on release. */
  onPreviewChange?: (value: number) => void;
  onChange: (value: number) => void;
};

export function LevelSlider(props: LevelSliderProps) {
  return <LevelSliderControl key={`${props.value}-${props.minimum}-${props.maximum}`} {...props} />;
}

function LevelSliderControl({
  value,
  minimum,
  maximum,
  label,
  accent,
  steps,
  showStepButtons = false,
  compact = false,
  valueLabel,
  onPreviewChange,
  onChange,
}: LevelSliderProps) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const controlColor = accent ?? theme.onSurface;
  const [preview, setPreview] = useState(value);
  const [width, setWidth] = useState(1);
  const [fraction, setFraction] = useState(
    maximum > minimum ? (value - minimum) / (maximum - minimum) : 0,
  );
  const dragStartValue = useRef(value);
  const dragging = useRef(false);
  const liveValue = useRef(value);
  const callbacks = useRef({ onChange, onPreviewChange });
  useLayoutEffect(() => {
    callbacks.current = { onChange, onPreviewChange };
  }, [onChange, onPreviewChange]);
  const allowed = useMemo(
    () =>
      steps
        ? [...new Set([minimum, maximum, value, ...steps])]
            .filter((level) => Number.isFinite(level) && level >= minimum && level <= maximum)
            .sort((a, b) => a - b)
        : undefined,
    [maximum, minimum, steps, value],
  );
  const stepValue = (direction: number) =>
    allowed
      ? allowed[Math.max(0, Math.min(allowed.length - 1, allowed.indexOf(preview) + direction))]!
      : Math.max(minimum, Math.min(maximum, preview + direction));
  const adjust = (direction: number) => {
    const next = stepValue(direction);
    liveValue.current = next;
    setPreview(next);
    setFraction(maximum > minimum ? (next - minimum) / (maximum - minimum) : 0);
    onPreviewChange?.(next);
    onChange(next);
  };
  const stepButton = (direction: -1 | 1) => {
    const disabled = direction < 0 ? preview <= minimum : preview >= maximum;
    const Icon = compact ? (direction < 0 ? ChevronDown : ChevronUp) : direction < 0 ? Minus : Plus;
    return (
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={t(direction < 0 ? 'sideDecrease' : 'sideIncrease')}
        accessibilityState={{ disabled }}
        disabled={disabled}
        // eslint-disable-next-line react-hooks/refs -- adjust reads refs only when this press callback executes.
        onPress={() => adjust(direction)}
        style={{
          width: 44,
          height: 44,
          alignItems: 'center',
          justifyContent: 'center',
          opacity: disabled ? 0.3 : 1,
        }}
      >
        <Icon size={22} color={controlColor} />
      </Pressable>
    );
  };
  // Drag relative to the selected level, not the finger's landing position.
  // Touching the 44pt target while scrolling must not seek. Dense hero ranges
  // get at least 4pt per level; another drag can continue from the same level.
  // Keep handlers stable when a lightweight preview re-renders its parent.
  /* eslint-disable react-hooks/refs -- PanResponder registers event callbacks here; refs are read only when a gesture fires. */
  const responder = useMemo(() => {
    const range = maximum - minimum;
    const dragDistance = Math.max(width, range * 4);
    const move = (dx: number) => {
      const travel = Math.sign(dx) * Math.max(0, Math.abs(dx) - 6);
      const raw = Math.max(
        minimum,
        Math.min(maximum, dragStartValue.current + (travel / dragDistance) * range),
      );
      const next = allowed
        ? allowed.reduce((nearest, level) =>
            Math.abs(level - raw) < Math.abs(nearest - raw) ? level : nearest,
          )
        : Math.round(raw);
      const changed = liveValue.current !== next;
      liveValue.current = next;
      setFraction(range > 0 ? (raw - minimum) / range : 0);
      setPreview(next);
      if (changed) callbacks.current.onPreviewChange?.(next);
    };
    const finish = () => {
      dragging.current = false;
      setFraction(maximum > minimum ? (liveValue.current - minimum) / (maximum - minimum) : 0);
      if (liveValue.current !== dragStartValue.current)
        callbacks.current.onChange(liveValue.current);
    };
    const cancel = () => {
      dragging.current = false;
      const changed = liveValue.current !== dragStartValue.current;
      liveValue.current = dragStartValue.current;
      setPreview(liveValue.current);
      setFraction(range > 0 ? (liveValue.current - minimum) / range : 0);
      if (changed) callbacks.current.onPreviewChange?.(liveValue.current);
    };
    return PanResponder.create({
      onStartShouldSetPanResponder: () => maximum > minimum,
      onMoveShouldSetPanResponder: (_, gesture) =>
        maximum > minimum &&
        Math.abs(gesture.dx) > 6 &&
        Math.abs(gesture.dx) > Math.abs(gesture.dy),
      onPanResponderGrant: () => {
        dragStartValue.current = liveValue.current;
        dragging.current = false;
      },
      onPanResponderMove: (_, gesture) => {
        if (gesture.numberActiveTouches !== 1) return;
        if (!dragging.current) {
          if (Math.abs(gesture.dx) <= 6 || Math.abs(gesture.dx) <= Math.abs(gesture.dy)) return;
          dragging.current = true;
        }
        move(gesture.dx);
      },
      onPanResponderRelease: finish,
      onPanResponderTerminate: cancel,
      onPanResponderTerminationRequest: () => !dragging.current,
    });
  }, [allowed, maximum, minimum, width]);
  /* eslint-enable react-hooks/refs */
  return (
    <View style={{ gap: 4 }}>
      <View style={{ flexDirection: 'row', justifyContent: 'space-between', gap: 12 }}>
        <CKText role="metadata" muted>
          {label}
        </CKText>
        <CKText role="rowTitle" style={{ color: controlColor }}>
          {valueLabel && preview === value ? valueLabel : t('sideLevel', { level: preview })}
        </CKText>
      </View>
      <View style={{ flexDirection: 'row', alignItems: 'center' }}>
        {showStepButtons ? stepButton(-1) : null}
        <View
          accessibilityRole="adjustable"
          accessibilityLabel={label}
          accessibilityValue={{ min: minimum, max: maximum, now: preview }}
          accessibilityActions={[{ name: 'increment' }, { name: 'decrement' }]}
          onAccessibilityAction={(event) => {
            adjust(event.nativeEvent.actionName === 'increment' ? 1 : -1);
          }}
          onLayout={(event) => setWidth(Math.max(1, event.nativeEvent.layout.width))}
          style={{
            flex: 1,
            height: 44,
            justifyContent: 'center',
            marginHorizontal: compact ? 8 : 12,
          }}
          {...(Platform.OS === 'web'
            ? {
                tabIndex: 0,
                onKeyDown: (event: KeyDownEvent) => {
                  const key = event.nativeEvent.key;
                  const delta =
                    key === 'ArrowRight' || key === 'ArrowUp'
                      ? 1
                      : key === 'ArrowLeft' || key === 'ArrowDown'
                        ? -1
                        : 0;
                  if (!delta && key !== 'Home' && key !== 'End') return;
                  event.preventDefault();
                  const next =
                    key === 'Home' ? minimum : key === 'End' ? maximum : stepValue(delta);
                  liveValue.current = next;
                  setPreview(next);
                  setFraction(maximum > minimum ? (next - minimum) / (maximum - minimum) : 0);
                  onPreviewChange?.(next);
                  onChange(next);
                },
              }
            : {})}
          {...responder.panHandlers}
        >
          <View
            pointerEvents="none"
            style={{ height: 5, borderRadius: 999, backgroundColor: theme.surfaceContainerHighest }}
          />
          <View
            pointerEvents="none"
            style={{
              position: 'absolute',
              height: 5,
              width: `${fraction * 100}%`,
              borderRadius: 999,
              backgroundColor: controlColor,
            }}
          />
          <View
            pointerEvents="none"
            style={{
              position: 'absolute',
              left: `${fraction * 100}%`,
              marginLeft: compact ? -8 : -11,
              width: compact ? 16 : 22,
              height: compact ? 16 : 22,
              borderRadius: 11,
              backgroundColor: controlColor,
            }}
          />
        </View>
        {showStepButtons ? stepButton(1) : null}
      </View>
    </View>
  );
}
