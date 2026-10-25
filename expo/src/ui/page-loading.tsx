import { createContext, useContext, useEffect, useState, useSyncExternalStore } from 'react';
import { StyleSheet, View } from 'react-native';
import { SafeAreaInsetsContext } from 'react-native-safe-area-context';
import { LoadingIndicator } from './feedback';
import { useCKTheme } from './theme';

const LoadingHostContext = createContext(false);
export const PageLoadingHost = LoadingHostContext.Provider;
const requests = new Set<symbol>();
const listeners = new Set<() => void>();
const snapshot = () => requests.size > 0;
function setRequest(id: symbol, active: boolean) {
  const previous = snapshot();
  if (active) requests.add(id);
  else requests.delete(id);
  if (previous !== snapshot()) listeners.forEach((listener) => listener());
}
function subscribe(listener: () => void) {
  listeners.add(listener);
  return () => {
    listeners.delete(listener);
  };
}
export function usePageLoadingRequest() {
  return useSyncExternalStore(subscribe, snapshot, snapshot);
}

/** Retained pages register loading; the top native route alone renders it. */
export function PageLoading({ visible }: { visible: boolean }) {
  const hosted = useContext(LoadingHostContext);
  const [id] = useState(() => Symbol('page-loading'));
  useEffect(() => {
    setRequest(id, hosted && visible);
    return () => setRequest(id, false);
  }, [hosted, id, visible]);
  return hosted ? null : <PageLoadingOverlay visible={visible} />;
}

export function PageLoadingOverlay({ visible }: { visible: boolean }) {
  const theme = useCKTheme();
  const insets = useContext(SafeAreaInsetsContext);
  if (!visible) return null;
  return (
    <View
      style={[styles.status, { top: (insets?.top ?? 0) + 8 }]}
      pointerEvents="none"
      importantForAccessibility="yes"
    >
      <View style={[styles.indicator, { backgroundColor: theme.background }]}>
        <LoadingIndicator />
      </View>
    </View>
  );
}
const styles = StyleSheet.create({
  // Destination data is loaded before navigation. Keep the actual source page
  // on screen; a guessed full-page skeleton hid its content and scroll state.
  status: { position: 'absolute', alignSelf: 'center', zIndex: 1000, elevation: 1000 },
  indicator: { padding: 10, borderRadius: 24 },
});
