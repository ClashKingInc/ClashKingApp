import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  type ReactNode,
} from 'react';
import { View } from 'react-native';

type ChartInteractions = {
  register: (dismiss: () => void) => () => void;
  dismiss: () => void;
};

const ChartInteractionContext = createContext<ChartInteractions | null>(null);

/** Observe touches without claiming the responder or blocking the pressed control. */
export function ChartInteractionBoundary({ children }: { children: ReactNode }) {
  const listeners = useRef(new Set<() => void>());
  const interactions = useMemo<ChartInteractions>(
    () => ({
      register(dismiss) {
        listeners.current.add(dismiss);
        return () => {
          listeners.current.delete(dismiss);
        };
      },
      dismiss() {
        for (const dismiss of listeners.current) dismiss();
      },
    }),
    [],
  );
  return (
    <ChartInteractionContext.Provider value={interactions}>
      <View
        testID="chart-interaction-boundary"
        style={{ flex: 1 }}
        onStartShouldSetResponderCapture={() => {
          interactions.dismiss();
          return false;
        }}
      >
        {children}
      </View>
    </ChartInteractionContext.Provider>
  );
}

export function useChartDismissal(clearSelection: () => void) {
  const interactions = useContext(ChartInteractionContext);
  useEffect(() => interactions?.register(clearSelection), [interactions, clearSelection]);
  return useCallback(() => interactions?.dismiss(), [interactions]);
}
