import { router, useLocalSearchParams, useNavigation, useRoute, useIsFocused } from 'expo-router';
import {
  useCallback,
  useEffect,
  useLayoutEffect,
  useMemo,
  useRef,
  useSyncExternalStore,
  useState,
  type ReactNode,
} from 'react';
import { StyleSheet, View } from 'react-native';
import { SafeAreaProvider, useSafeAreaInsets } from 'react-native-safe-area-context';

import {
  nativeSecondaryContent,
  notifyNativeSecondaryPopped,
  removeNativeSecondaryLayer,
  subscribeNativeSecondaryLayer,
} from '../core/app/native-secondary-navigation';
import { LoadingIndicator, useCKTheme } from '../ui';
import { DuoDetailShortcuts, isDuoDevice } from '../shell/duo-navigation-actions';
import { NativeRailBack } from '../ui/native-back-context';
import { useVerticalBarEdgeIOS } from 'expo-status-bar';
import { useAdaptiveLayout } from '../ui/adaptive-layout';
import { ReservedRegionLayout } from '../ui/reserved-region-layout';
import { AdaptiveViewportContext } from '../ui/adaptive-viewport';
import { useDuoPortraitBottomBar } from '../shell/duo-navigation-mode';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';

export default function NativeSecondaryRoute() {
  const theme = useCKTheme();
  const focused = useIsFocused();
  const rail = useVerticalBarEdgeIOS();
  const portraitBottomBar = useDuoPortraitBottomBar();
  const insets = useSafeAreaInsets();
  const [viewportHeight, setViewportHeight] = useState<number | null>(null);
  // Page actions and destination shortcuts share UIKit's toolbar layout.
  // Separate native groups preserve the requested circles without coordinating
  // a second absolute-positioned rail across folding and rotation.
  const railEnabled =
    focused &&
    isDuoDevice &&
    !portraitBottomBar &&
    rail !== null &&
    Math.max(insets.left, insets.right) >= 44 &&
    // Keep page actions inline when a short window cannot fit six controls.
    // Use the actual route layout; Dimensions can lag a fold transition.
    (viewportHeight === null || viewportHeight >= 520);
  const backActions = useRef(new Map<symbol, { action: () => void; depth: number }>());
  const shareActions = useRef(
    new Map<symbol, { action: () => void; label: string; depth: number }>(),
  );
  const [share, setShare] = useState<{ action: () => void; label: string }>();
  const registerBack = useCallback((action: () => void, depth: number) => {
    const token = Symbol();
    backActions.current.set(token, { action, depth });
    return () => {
      backActions.current.delete(token);
    };
  }, []);
  const nativeBack = useCallback(() => {
    const action = deepestAction(backActions.current.values());
    if (action) action.action();
    else router.back();
  }, []);
  const registerShare = useCallback((action: () => void, label: string, depth: number) => {
    const token = Symbol();
    shareActions.current.set(token, { action, label, depth });
    setShare(deepestAction(shareActions.current.values()));
    return () => {
      shareActions.current.delete(token);
      setShare(deepestAction(shareActions.current.values()));
    };
  }, []);
  const navigation = useNavigation<NativeStackNavigationProp<Record<string, object | undefined>>>();
  const route = useRoute();
  const params = useLocalSearchParams<{ layer?: string | string[] }>();
  const key = Array.isArray(params.layer) ? params.layer[0] : params.layer;
  const content = useSyncExternalStore(
    (listener) => (key ? subscribeNativeSecondaryLayer(key, listener) : () => undefined),
    () => (key ? nativeSecondaryContent(key) : null),
    () => null,
  );

  useLayoutEffect(() => {
    if (!key) return;
    let popped = false;
    const reconcile = () => {
      const state = navigation.getState();
      if (!popped && state && !state.routes.some((entry) => entry.key === route.key)) {
        popped = true;
        // A rapid return/reopen can reuse the card's layer key before the old
        // native route unmounts. The new route now owns that retained content.
        const reopened = state.routes.some(
          (entry) => (entry.params as { layer?: string } | undefined)?.layer === key,
        );
        if (!reopened) notifyNativeSecondaryPopped(key);
      }
    };
    // Passive unmount cleanup can lag behind the completed native return and
    // leave the owner's stack blocking the next tap. Observe actual state now.
    const unsubscribe = navigation.addListener('state', reconcile);
    // Fast Refresh and effect replay also run cleanup while this route remains
    // in the stack. Only a real native removal may discard its retained layer;
    // otherwise refreshing a detail screen also closes its parent clan page.
    return () => {
      unsubscribe();
      const state = navigation.getState();
      if (state && !state.routes.some((entry) => entry.key === route.key)) {
        const reopened = state.routes.some(
          (entry) => (entry.params as { layer?: string } | undefined)?.layer === key,
        );
        if (!reopened) {
          if (!popped) notifyNativeSecondaryPopped(key);
          // The native screen has finished using its content at unmount.
          removeNativeSecondaryLayer(key);
        }
      }
    };
  }, [key, navigation, route.key]);

  useEffect(() => {
    if (content) return;
    // A restored /detail route can outlive the in-memory layer it displays.
    // Allow the app's startup link to publish its layer before recovering Home.
    const timeout = setTimeout(() => {
      if (!key || nativeSecondaryContent(key) == null) router.replace('/');
    }, 4_000);
    return () => clearTimeout(timeout);
  }, [content, key]);

  // Focus changes this route's chrome. Keep its
  // context identity stable so those events do not rerender the entire table
  // and every image on the retained Wiki page.
  const railContext = useMemo(
    () => ({ enabled: railEnabled, depth: 0, registerBack, registerShare }),
    [railEnabled, registerBack, registerShare],
  );

  return (
    <View
      style={[styles.root, { backgroundColor: theme.background }]}
      onLayout={({ nativeEvent: { layout } }) => setViewportHeight(layout.height)}
    >
      <NativeRailBack.Provider value={railContext}>
        <ReservedRegionLayout>
          <SecondaryPageContent>
            {content ?? (
              <View style={styles.loading}>
                <LoadingIndicator />
              </View>
            )}
          </SecondaryPageContent>
        </ReservedRegionLayout>
      </NativeRailBack.Provider>
      {/* In open portrait the shared bottom bar occupies its own row, so a
          detail's final controls cannot sit underneath it. In landscape this
          registers the existing native toolbar without changing the page tree. */}
      <DuoDetailShortcuts
        back={railEnabled ? nativeBack : undefined}
        share={railEnabled ? share : undefined}
      />
    </View>
  );
}

function SecondaryPageContent({ children }: { children: ReactNode }) {
  const layout = useAdaptiveLayout();
  const [size, setSize] = useState<{ width: number; height: number } | null>(null);
  if (!layout.isDuo) return <View style={styles.root}>{children}</View>;
  // Descendants measure this page once. Portrait keeps its single-column
  // behavior without an artificial phone-width gutter on the inner display.
  return (
    <View
      style={[styles.root, { width: '100%', alignSelf: 'center' }]}
      onLayout={({ nativeEvent: { layout: next } }) => {
        setSize((current) =>
          current?.width === next.width && current.height === next.height
            ? current
            : { width: next.width, height: next.height },
        );
      }}
    >
      <AdaptiveViewportContext.Provider value={size ? { ...size, constrained: true } : null}>
        <SafeAreaProvider style={styles.root}>{children}</SafeAreaProvider>
      </AdaptiveViewportContext.Provider>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  loading: { flex: 1, alignItems: 'center', justifyContent: 'center' },
});

function deepestAction<T extends { depth: number }>(actions: Iterable<T>): T | undefined {
  let selected: T | undefined;
  for (const action of actions) {
    if (!selected || action.depth >= selected.depth) selected = action;
  }
  return selected;
}
