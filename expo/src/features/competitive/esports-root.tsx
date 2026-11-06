import { useCallback, useEffect, useId, useRef, useState } from 'react';
import { Platform, Pressable, StyleSheet, View, type ViewInstance } from 'react-native';
import { ArrowLeft } from 'lucide-react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';
import { InlineBackControl } from '../../ui/native-back-context';
import { DestinationStack, useCKTheme } from '../../ui';
import { materialBackLabel, useI18n } from '../../i18n';
import { subscribeLocalBrowserNavigation } from '../../core/deep-links/expo-deep-link-runtime';
import { EsportsLanding, EsportsTeam, EsportsPlayer } from './esports-screen';

type Scene = { kind: 'esports' } | { kind: 'ccnTeam'; id: string } | { kind: 'ccnPlayer'; tag: string };

export function EsportsRoot({ onBack }: { onBack: () => void }) {
  const historyId = useId();
  const [navigation, setNavigation] = useState<{ scenes: Scene[]; depth: number }>({ scenes: [{ kind: 'esports' }], depth: 0 });
  const current = useRef(navigation);
  const pendingBrowserBack = useRef<number | undefined>(undefined);
  const host = useRef<ViewInstance>(null);
  const updateNavigation = useCallback((next: typeof navigation) => {
    current.current = next;
    setNavigation(next);
  }, []);
  useEffect(() => {
    if (Platform.OS !== 'web') return;
    // Consume only this mounted destination's browser entries. Other paths
    // still reach the app-link inbox and its existing authentication/router flow.
    const marker = (depth: number) => ({
      ...window.history.state,
      esportsNavigation: { id: historyId, depth },
    });
    if (window.history.state?.esportsNavigation?.id !== historyId) {
      window.history.replaceState(marker(0), '');
      for (let depth = 1; depth <= current.current.depth; depth += 1)
        window.history.pushState(marker(depth), '');
    }
    const onPop = (event: PopStateEvent) => {
      // A player opened above this retained utility owns Back until that
      // overlay closes. Only the visible eSports host may consume it.
      const element = host.current as unknown as HTMLElement | null;
      if (!element?.getClientRects().length || element.closest('[inert], [aria-hidden="true"]'))
        return false;
      const entry = event.state?.esportsNavigation;
      const pendingDepth = pendingBrowserBack.current;
      if (pendingDepth === undefined && (entry?.id !== historyId || !Number.isInteger(entry.depth)))
        return false;
      pendingBrowserBack.current = undefined;
      const previous = current.current;
      const depth = pendingDepth ?? entry.depth;
      if (depth < 0 || depth >= previous.scenes.length) return false;
      updateNavigation({ ...previous, depth });
      return true;
    };
    return subscribeLocalBrowserNavigation(onPop);
  }, [historyId, updateNavigation]);
  const push = useCallback(
    (scene: Scene) => {
      const previous = current.current;
      const depth = previous.depth + 1;
      updateNavigation({ scenes: [...previous.scenes.slice(0, depth), scene], depth });
      if (Platform.OS === 'web')
        window.history.pushState(
          {
            ...window.history.state,
            esportsNavigation: { id: historyId, depth },
          },
          '',
        );
    },
    [historyId, updateNavigation],
  );
  const back = useCallback(() => {
    const previous = current.current;
    if (previous.depth === 0) onBack();
    else if (Platform.OS === 'web') {
      // Restore the retained parent immediately. The runtime consumes the
      // ensuing history event before it can reopen this URL as a new utility.
      pendingBrowserBack.current = previous.depth - 1;
      updateNavigation({ ...previous, depth: previous.depth - 1 });
      window.history.back();
    } else updateNavigation({ ...previous, depth: previous.depth - 1 });
  }, [onBack, updateNavigation]);
  return (
    <View ref={host} style={{ flex: 1 }}>
      <EsportsSceneLevel
        scenes={navigation.scenes}
        depth={navigation.depth}
        level={0}
        push={push}
        back={back}
      />
    </View>
  );
}

function EsportsSceneLevel({
  scenes,
  depth,
  level,
  push,
  back,
}: {
  scenes: Scene[];
  depth: number;
  level: number;
  push: (scene: Scene) => void;
  back: () => void;
}) {
  const theme = useCKTheme();
  const scene = scenes[level]!;
  const child = scenes[level + 1];
  const page = (
    <EsportsScenePage
      scene={scene}
      push={push}
      back={back}
    />
  );
  const detail = child ? (
    <EsportsSceneLevel
      scenes={scenes}
      depth={depth}
      level={level + 1}
      push={push}
      back={back}
    />
  ) : null;
  if (Platform.OS === 'web') {
    return (
      <View style={{ flex: 1 }}>
        <View style={{ flex: 1, display: depth === level ? 'flex' : 'none' }}>{page}</View>
        {detail ? (
          <View style={{ flex: 1, display: depth > level ? 'flex' : 'none' }}>{detail}</View>
        ) : null}
      </View>
    );
  }
  // Each drill-down owns a native Detail route. Keeping forward scenes in
  // memory preserves the parent list, filters and scroll on swipe or Back.
  return (
    <DestinationStack
      focused={depth > level}
      onCloseDetail={back}
      grid={page}
      detail={detail}
      backgroundColor={theme.background}
    />
  );
}

function EsportsScenePage({
  scene,
  push,
  back,
}: {
  scene: Scene;
  push: (scene: Scene) => void;
  back: () => void;
}) {
  const { locale } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  return (
    <SafeAreaView
      style={{ flex: 1, backgroundColor: theme.background }}
      // Artwork-led pages own their top inset so the image reaches behind the
      // status bar. Text-only scenes retain the normal safe-area content inset.
      edges={
        scene.kind === 'esports'
          ? ['left', 'right', 'bottom']
          : ['top', 'left', 'right', 'bottom']
      }
    >
      {/* Absolute children ignore SafeAreaView's content padding. Keep Back
          below the status bar while retaining the artwork beneath it. */}
      <InlineBackControl onBack={back}>
        <View pointerEvents="box-none" style={[styles.header, { top: insets.top + 6 }]}>
          <Pressable
            onPress={back}
            accessibilityRole="button"
            accessibilityLabel={materialBackLabel(locale)}
            style={[
              styles.back,
              {
                backgroundColor:
                  '#100b14aa',
              },
            ]}
          >
            <ArrowLeft
              color="#fff"
            />
          </Pressable>
        </View>
      </InlineBackControl>
      {scene.kind === 'esports' ? (
        <EsportsLanding push={push} />
      ) : scene.kind === 'ccnTeam' ? (
        <EsportsTeam id={scene.id} push={push} />
      ) : scene.kind === 'ccnPlayer' ? (
        <EsportsPlayer tag={scene.tag} />
      ) : null}
    </SafeAreaView>
  );
}


const styles = StyleSheet.create({ header: { position: 'absolute', left: 16, zIndex: 4 }, back: { padding: 10, borderRadius: 24 } });
