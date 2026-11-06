import { useMemo, useRef, useState } from 'react';
import { PanResponder, Platform, Pressable, View, type KeyDownEvent } from 'react-native';
import { Minus, Plus } from 'lucide-react-native';
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
  const startX = useRef(0);
  const liveValue = useRef(value);
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
    const Icon = direction < 0 ? Minus : Plus;
    return (
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={t(direction < 0 ? 'sideDecrease' : 'sideIncrease')}
        accessibilityState={{ disabled }}
        disabled={disabled}
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
  // Read the grant position once, then use gesture displacement. locationX is
  // relative to the touched child and jumps when the thumb crosses the track.
  /* eslint-disable react-hooks/refs -- PanResponder registers event callbacks here; refs are read only when a gesture fires. */
  const responder = useMemo(() => {
    const move = (x: number) => {
      const nextFraction = Math.max(0, Math.min(1, x / width));
      const raw = minimum + nextFraction * (maximum - minimum);
      const next = allowed
        ? allowed.reduce((nearest, level) =>
            Math.abs(level - raw) < Math.abs(nearest - raw) ? level : nearest,
          )
        : Math.round(raw);
      const changed = liveValue.current !== next;
      liveValue.current = next;
      setFraction(nextFraction);
      setPreview(next);
      if (changed) onPreviewChange?.(next);
    };
    const finish = () => {
      setFraction(maximum > minimum ? (liveValue.current - minimum) / (maximum - minimum) : 0);
      onChange(liveValue.current);
    };
    return PanResponder.create({
      onStartShouldSetPanResponder: () => maximum > minimum,
      onMoveShouldSetPanResponder: (_, gesture) =>
        maximum > minimum && Math.abs(gesture.dx) > Math.abs(gesture.dy),
      onPanResponderGrant: (event) => {
        startX.current = event.nativeEvent.locationX;
        move(startX.current);
      },
      onPanResponderMove: (_, gesture) => move(startX.current + gesture.dx),
      onPanResponderRelease: finish,
      onPanResponderTerminate: finish,
      onPanResponderTerminationRequest: () => false,
    });
  }, [allowed, maximum, minimum, onChange, onPreviewChange, width]);
  /* eslint-enable react-hooks/refs */
  return (
    <View style={{ gap: 4 }}>
      <View style={{ flexDirection: 'row', justifyContent: 'space-between', gap: 12 }}>
        <CKText role="metadata" muted>
          {label}
        </CKText>
        <CKText role="rowTitle" style={{ color: controlColor }}>
          {t('sideLevel', { level: preview })}
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
            const next = stepValue(event.nativeEvent.actionName === 'increment' ? 1 : -1);
            setPreview(next);
            onChange(next);
          }}
          onLayout={(event) => setWidth(Math.max(1, event.nativeEvent.layout.width))}
          style={{ flex: 1, height: 44, justifyContent: 'center', marginHorizontal: 12 }}
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
                  setPreview(next);
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
              marginLeft: -11,
              width: 22,
              height: 22,
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
