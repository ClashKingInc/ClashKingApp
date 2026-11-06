import { createNativeStackNavigator } from '@react-navigation/native-stack';
import {
  DarkTheme,
  DefaultTheme,
  NavigationContainer,
  NavigationIndependentTree,
  StackActions,
  useIsFocused,
  useNavigationContainerRef,
} from '@react-navigation/native';
import {
  createContext,
  useContext,
  useLayoutEffect,
  useMemo,
  useRef,
  useCallback,
  useState,
  type ReactNode,
} from 'react';
import { Platform } from 'react-native';

import { useCKTheme, useCKThemeMode } from './theme';
import { NativeBackScope } from './native-back-context';

type DestinationRoutes = {
  Grid: undefined;
  Detail: undefined;
};

export type DestinationStackProps = {
  focused: boolean;
  /** Changes for every explicit new selection, including the same tile again. */
  selectionKey?: number | string;
  onCloseDetail: () => void;
  grid: ReactNode;
  detail: ReactNode;
  backgroundColor?: string;
  gestureEnabled?: boolean;
};

const Stack = createNativeStackNavigator<DestinationRoutes>();
const DestinationContext = createContext<DestinationStackProps | null>(null);

function useDestination() {
  const destination = useContext(DestinationContext);
  if (!destination) throw new Error('DestinationStack screens must be inside DestinationStack');
  return destination;
}

function GridRoute() {
  // The native stack owns hit testing during the swipe. An extra owner-state
  // blocker here discards taps after Grid is visible but before JS catches up.
  const focused = useIsFocused();
  return <NativeBackScope active={focused}>{useDestination().grid}</NativeBackScope>;
}

function DetailRoute() {
  const { focused, detail } = useDestination();
  const routeFocused = useIsFocused();
  const [lastDetail, setLastDetail] = useState(detail);
  // Owner-driven Back clears the selection before UIKit finishes closing.
  // Keep the outgoing screen instead of swapping it for an unrelated detail.
  if (focused && lastDetail !== detail) setLastDetail(detail);
  return (
    <NativeBackScope active={routeFocused && focused}>
      {focused ? detail : lastDetail}
    </NativeBackScope>
  );
}

export function DestinationStack(props: DestinationStackProps) {
  const theme = useCKTheme();
  const mode = useCKThemeMode();
  const navigationTheme = useMemo(() => {
    const base = mode === 'dark' ? DarkTheme : DefaultTheme;
    return {
      ...base,
      colors: {
        ...base.colors,
        background: props.backgroundColor ?? theme.background,
        card: props.backgroundColor ?? theme.background,
        text: theme.onSurface,
        primary: theme.primary,
      },
    };
  }, [mode, props.backgroundColor, theme]);
  const navigation = useNavigationContainerRef<DestinationRoutes>();
  const desiredFocus = useRef(props.focused);
  const desiredSelection = useRef(props.selectionKey);
  const presentedSelection = useRef(props.selectionKey);
  const onCloseDetail = useRef(props.onCloseDetail);
  const hadDetail = useRef(false);
  const transitioning = useRef(false);
  const arrivedRoute = useRef<string | undefined>(undefined);
  const ownerPopPending = useRef(false);
  const syncOwnerWithState = useCallback((state: { routes: readonly { name: string }[] }) => {
    const hasDetail = state.routes.some((route) => route.name === 'Detail');
    const removedDetail = hadDetail.current && !hasDetail;
    hadDetail.current = hasDetail;
    if (!removedDetail) return;
    const wasOwnerPop = ownerPopPending.current;
    ownerPopPending.current = false;
    // A tile press while native Back is finishing belongs to the next page.
    // Do not let the old removal erase that new request, even for the same tile.
    if (
      !wasOwnerPop &&
      desiredFocus.current &&
      desiredSelection.current === presentedSelection.current
    ) {
      desiredFocus.current = false;
      onCloseDetail.current();
    }
  }, []);
  const reconcile = useCallback(() => {
    if (!navigation.isReady() || transitioning.current) return;
    const state = navigation.getRootState();
    if (!state) return;
    syncOwnerWithState(state);
    const detailIsActive = state.routes[state.index]?.name === 'Detail';
    if (desiredFocus.current === detailIsActive) {
      if (detailIsActive) presentedSelection.current = desiredSelection.current;
      return;
    }
    transitioning.current = true;
    arrivedRoute.current = undefined;
    if (desiredFocus.current) {
      presentedSelection.current = desiredSelection.current;
      navigation.navigate('Detail');
    } else {
      ownerPopPending.current = true;
      navigation.dispatch(StackActions.pop());
    }
  }, [navigation, syncOwnerWithState]);
  const finishTransition = useCallback(() => {
    const state = navigation.getRootState();
    if (!state) return;
    // getRootState can already show Grid before onStateChange delivers that
    // removal. Consume native Back first, or reconciliation would re-push Detail
    // from the owner's stale focused=true and bounce the user straight back in.
    syncOwnerWithState(state);
    if (!arrivedRoute.current || arrivedRoute.current !== state.routes[state.index]?.key) return;
    // UIKit appearance and JS stack removal can arrive in either order. Keep
    // the arrival until both agree, rather than dropping the first event.
    arrivedRoute.current = undefined;
    transitioning.current = false;
    reconcile();
  }, [navigation, reconcile, syncOwnerWithState]);
  useLayoutEffect(() => {
    onCloseDetail.current = props.onCloseDetail;
  }, [props.onCloseDetail]);
  useLayoutEffect(() => {
    desiredFocus.current = props.focused;
    desiredSelection.current = props.selectionKey;
    reconcile();
  }, [props.focused, props.selectionKey, reconcile]);
  if (Platform.OS === 'web') return props.focused ? props.detail : props.grid;

  return (
    <DestinationContext.Provider value={props}>
      {/* These local Grid/Detail routes are not filesystem routes. SDK 58's
          Expo navigator requires globally seeded route state, so use React
          Navigation's isolated tree for this retained, state-driven stack.
          All hooks/events below must come from that same navigation package. */}
      <NavigationIndependentTree>
        <NavigationContainer
          ref={navigation}
          theme={navigationTheme}
          onReady={reconcile}
          onStateChange={() => {
            // Read the latest state rather than a possibly queued snapshot from
            // before an arrival callback. Both event paths share the same sync.
            const state = navigation.getRootState();
            if (state) syncOwnerWithState(state);
            finishTransition();
          }}
        >
          <Stack.Navigator
            initialRouteName="Grid"
            screenListeners={({ route }) => ({
              transitionStart: (event) => {
                transitioning.current = true;
                if (!event.data.closing) arrivedRoute.current = undefined;
              },
              transitionEnd: (event) => {
                if (!event.data.closing) {
                  arrivedRoute.current = route.key;
                  finishTransition();
                }
              },
              gestureCancel: () => {
                arrivedRoute.current = undefined;
                transitioning.current = false;
                reconcile();
              },
            })}
            screenOptions={{
              headerShown: false,
              gestureEnabled: props.gestureEnabled ?? true,
              fullScreenGestureEnabled: false,
              freezeOnBlur: false,
              contentStyle: { backgroundColor: props.backgroundColor ?? theme.background },
            }}
          >
            <Stack.Screen name="Grid" component={GridRoute} options={{ gestureEnabled: false }} />
            <Stack.Screen name="Detail" component={DetailRoute} />
          </Stack.Navigator>
        </NavigationContainer>
      </NavigationIndependentTree>
    </DestinationContext.Provider>
  );
}
