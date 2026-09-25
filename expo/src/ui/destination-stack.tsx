import { createNativeStackNavigator, type NativeStackScreenProps } from 'expo-router/native-stack';
import {
  createContext,
  useContext,
  useLayoutEffect,
  useRef,
  type MutableRefObject,
  type ReactNode,
} from 'react';
import { Platform } from 'react-native';

import { useCKTheme } from './theme';

type DestinationRoutes = {
  Grid: undefined;
  Detail: undefined;
};

export type DestinationStackProps = {
  focused: boolean;
  onCloseDetail: () => void;
  grid: ReactNode;
  detail: ReactNode;
};

const Stack = createNativeStackNavigator<DestinationRoutes>();
type DestinationContextValue = DestinationStackProps & {
  dismissedByNativeBackRef: MutableRefObject<boolean>;
  closingFromOwnerRef: MutableRefObject<boolean>;
};

const DestinationContext = createContext<DestinationContextValue | null>(null);

function useDestination() {
  const destination = useContext(DestinationContext);
  if (!destination) throw new Error('DestinationStack screens must be inside DestinationStack');
  return destination;
}

function GridRoute({ navigation }: NativeStackScreenProps<DestinationRoutes, 'Grid'>) {
  const { focused, grid, dismissedByNativeBackRef, closingFromOwnerRef } = useDestination();

  useLayoutEffect(() => {
    const state = navigation.getState();
    const detailIsActive = state.routes[state.index]?.name === 'Detail';
    if (!focused) {
      dismissedByNativeBackRef.current = false;
      if (detailIsActive) {
        closingFromOwnerRef.current = true;
        navigation.pop();
      } else {
        closingFromOwnerRef.current = false;
      }
    } else if (!detailIsActive && !dismissedByNativeBackRef.current) {
      closingFromOwnerRef.current = false;
      navigation.navigate('Detail');
    }
  }, [closingFromOwnerRef, dismissedByNativeBackRef, focused, navigation]);

  // The native stack retains this route while Detail is presented. Its React
  // content (and any provider state above the stack) is not reconstructed on back.
  return grid;
}

function DetailRoute({ navigation }: NativeStackScreenProps<DestinationRoutes, 'Detail'>) {
  const { focused, onCloseDetail, detail, dismissedByNativeBackRef, closingFromOwnerRef } =
    useDestination();

  useLayoutEffect(
    () =>
      navigation.addListener('beforeRemove', () => {
        // A header back button clears `focused` first. Native swipe / hardware
        // back removes the route first, so only that path needs to sync its owner.
        if (focused && !closingFromOwnerRef.current) {
          dismissedByNativeBackRef.current = true;
          onCloseDetail();
        }
      }),
    [closingFromOwnerRef, dismissedByNativeBackRef, focused, navigation, onCloseDetail],
  );

  return detail;
}

export function DestinationStack(props: DestinationStackProps) {
  const theme = useCKTheme();
  const dismissedByNativeBackRef = useRef(false);
  const closingFromOwnerRef = useRef(false);
  if (Platform.OS === 'web') return props.focused ? props.detail : props.grid;

  return (
    <DestinationContext.Provider
      value={{ ...props, dismissedByNativeBackRef, closingFromOwnerRef }}
    >
      <Stack.Navigator
        initialRouteName="Grid"
        screenOptions={{
          headerShown: false,
          gestureEnabled: true,
          fullScreenGestureEnabled: false,
          freezeOnBlur: false,
          contentStyle: { backgroundColor: theme.background },
        }}
      >
        <Stack.Screen name="Grid" component={GridRoute} options={{ gestureEnabled: false }} />
        <Stack.Screen name="Detail" component={DetailRoute} />
      </Stack.Navigator>
    </DestinationContext.Provider>
  );
}
