import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  ActivityIndicator,
  PanResponder,
  Platform,
  StyleSheet,
  View,
  type KeyDownEvent,
} from 'react-native';
import { Pause, Play } from '@/ui/icons';
import { useI18n } from '../../../i18n';
import { CKText, PressableSurface, colorWithAlpha, useCKTheme } from '../../../ui';
import { SceneryAudioService, type SceneryAudioState } from '../audio/scenery-audio-service';

const initialState: SceneryAudioState = {
  checking: true,
  available: false,
  loading: false,
  playing: false,
  positionMilliseconds: 0,
  durationMilliseconds: 0,
};

/** One soundtrack player for Wiki and collection details; never autoplays. */
export function SceneryPlayer({ source }: { source: string }) {
  return <SceneryPlayerContent key={source} source={source} />;
}

function SceneryPlayerContent({ source }: { source: string }) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [state, setState] = useState(initialState);
  const service = useRef<SceneryAudioService | null>(null);
  const seek = useCallback(
    (position: number) => service.current?.seek(position).catch(() => {}) ?? Promise.resolve(),
    [],
  );
  useEffect(() => {
    let active = true;
    let current: SceneryAudioService | undefined;
    let unsubscribe = () => {};
    const runtimeImport =
      Platform.OS === 'web'
        ? import('../audio/expo-scenery-audio-runtime').then(
            ({ ExpoSceneryAudioRuntime }) => new ExpoSceneryAudioRuntime(),
          )
        : import('../audio/native-scenery-audio-runtime').then(
            ({ NativeSceneryAudioRuntime }) => new NativeSceneryAudioRuntime(),
          );
    void runtimeImport
      .then((runtime) => {
        if (!active) return;
        current = new SceneryAudioService(
          source,
          Platform.OS === 'ios' ? 'ios' : Platform.OS === 'android' ? 'android' : 'web',
          runtime,
        );
        service.current = current;
        unsubscribe = current.subscribe(setState);
        void current.checkAvailability();
      })
      .catch(() => {
        if (active) setState({ ...initialState, checking: false });
      });
    return () => {
      active = false;
      unsubscribe();
      service.current = null;
      void current?.dispose();
    };
  }, [source]);
  if (!state.checking && !state.available) return null;
  const busy = state.checking || state.loading;
  return (
    <View style={[styles.card, { backgroundColor: theme.card }]}>
      <View style={styles.heading}>
        <PressableSurface
          accessibilityRole="button"
          accessibilityLabel={
            state.playing ? t('upgradeTrackerPauseSoundtrack') : t('upgradeTrackerPlaySoundtrack')
          }
          accessibilityState={{ disabled: busy, busy }}
          disabled={busy}
          onPress={() => void service.current?.toggle()}
          radius={24}
          style={[styles.play, { backgroundColor: theme.primary, borderWidth: 0 }]}
        >
          {busy ? (
            <ActivityIndicator color={theme.onPrimary} />
          ) : state.playing ? (
            <Pause size={22} fill={theme.onPrimary} color={theme.onPrimary} />
          ) : (
            <Play
              size={22}
              fill={theme.onPrimary}
              color={theme.onPrimary}
              style={{ marginLeft: 2 }}
            />
          )}
        </PressableSurface>
        <CKText role="rowTitle" style={{ flex: 1 }}>
          {t('upgradeTrackerMusic')}
        </CKText>
        <CKText muted role="metadata" style={styles.times}>
          {formatAudio(state.positionMilliseconds)} /{' '}
          {state.durationMilliseconds ? formatAudio(state.durationMilliseconds) : '–:––'}
        </CKText>
      </View>
      <SoundtrackSeek
        position={state.positionMilliseconds}
        duration={state.durationMilliseconds}
        disabled={busy || state.durationMilliseconds <= 0}
        onSeek={seek}
      />
    </View>
  );
}

function SoundtrackSeek({
  position,
  duration,
  disabled,
  onSeek,
}: {
  position: number;
  duration: number;
  disabled: boolean;
  onSeek: (position: number) => Promise<void>;
}) {
  const theme = useCKTheme();
  const { t } = useI18n();
  const geometry = useRef({ x: 0, width: 1 });
  const live = useRef(0);
  const [dragging, setDragging] = useState(false);
  const [draft, setDraft] = useState(0);
  const fraction = dragging ? draft : Math.max(0, Math.min(1, position / Math.max(1, duration)));
  // Playback ticks must not replace the gesture responder while a thumb is held.
  // Use window coordinates: locationX changes when the finger crosses the thumb.
  /* eslint-disable react-hooks/refs -- refs are accessed only by native gesture callbacks. */
  const responder = useMemo(() => {
    const preview = (pageX: number) => {
      const value = Math.max(0, Math.min(1, (pageX - geometry.current.x) / geometry.current.width));
      live.current = value;
      setDraft(value);
    };
    const finish = () => {
      void onSeek(live.current * duration).finally(() => setDragging(false));
    };
    return PanResponder.create({
      onStartShouldSetPanResponder: () => !disabled,
      onMoveShouldSetPanResponder: (_, gesture) =>
        !disabled && Math.abs(gesture.dx) > Math.abs(gesture.dy),
      onPanResponderGrant: (event) => {
        geometry.current.x = event.nativeEvent.pageX - event.nativeEvent.locationX;
        setDragging(true);
        preview(event.nativeEvent.pageX);
      },
      onPanResponderMove: (event) => preview(event.nativeEvent.pageX),
      onPanResponderRelease: finish,
      onPanResponderTerminate: () => setDragging(false),
      onPanResponderTerminationRequest: () => false,
    });
  }, [disabled, duration, onSeek]);
  /* eslint-enable react-hooks/refs */
  const adjust = (amount: number) => onSeek(Math.max(0, Math.min(duration, position + amount)));
  return (
    <View
      onLayout={(event) => {
        geometry.current.width = Math.max(1, event.nativeEvent.layout.width);
      }}
      collapsable={false}
      accessibilityRole="adjustable"
      accessibilityLabel={t('upgradeTrackerSoundtrackPosition')}
      accessibilityState={{ disabled }}
      accessibilityValue={{
        min: 0,
        max: Math.round(duration / 1000),
        now: Math.round(position / 1000),
        text: `${formatAudio(position)} / ${formatAudio(duration)}`,
      }}
      accessibilityActions={disabled ? [] : [{ name: 'increment' }, { name: 'decrement' }]}
      onAccessibilityAction={(event) => {
        if (!disabled) adjust(event.nativeEvent.actionName === 'increment' ? 10000 : -10000);
      }}
      {...(Platform.OS === 'web'
        ? {
            tabIndex: disabled ? -1 : 0,
            onKeyDown: (event: KeyDownEvent) => {
              const key = event.nativeEvent.key;
              if (disabled || !['ArrowLeft', 'ArrowRight', 'Home', 'End'].includes(key)) return;
              event.preventDefault();
              if (key === 'Home' || key === 'End') onSeek(key === 'Home' ? 0 : duration);
              else adjust(key === 'ArrowRight' ? 10000 : -10000);
            },
          }
        : {})}
      {...responder.panHandlers}
      style={[styles.seek, { opacity: disabled ? 0.45 : 1 }]}
    >
      <View
        pointerEvents="none"
        style={[styles.rail, { backgroundColor: colorWithAlpha(theme.primary, 0.22) }]}
      >
        <View
          style={[styles.fill, { width: `${fraction * 100}%`, backgroundColor: theme.primary }]}
        />
      </View>
      {!disabled ? (
        <View
          pointerEvents="none"
          style={[styles.thumb, { left: `${fraction * 100}%`, backgroundColor: theme.primary }]}
        />
      ) : null}
    </View>
  );
}

function formatAudio(ms: number) {
  const seconds = Math.max(0, Math.floor(ms / 1000));
  return `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, '0')}`;
}
const styles = StyleSheet.create({
  card: { paddingHorizontal: 16, paddingTop: 16, paddingBottom: 4, borderRadius: 16, gap: 2 },
  heading: { flexDirection: 'row', flexWrap: 'wrap', alignItems: 'center', gap: 12 },
  play: { width: 48, height: 48, alignItems: 'center', justifyContent: 'center' },
  times: { fontVariant: ['tabular-nums'], flexShrink: 0 },
  seek: { height: 44, justifyContent: 'center', marginHorizontal: 6 },
  rail: { height: 4, borderRadius: 2, overflow: 'hidden' },
  fill: { height: 4, borderRadius: 2 },
  thumb: { width: 12, height: 12, borderRadius: 6, position: 'absolute', marginLeft: -6 },
});
