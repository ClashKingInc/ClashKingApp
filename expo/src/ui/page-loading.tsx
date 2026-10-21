import { createContext, useContext, useEffect, useState, useSyncExternalStore } from 'react';
import { Modal, Platform, ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaInsetsContext } from 'react-native-safe-area-context';
import { PageSkeleton, type PageSkeletonKind } from './feedback';
import { useCKTheme } from './theme';

const LoadingHostContext = createContext(false);
export const PageLoadingHost = LoadingHostContext.Provider;
const requests = new Map<symbol, PageSkeletonKind>();
const listeners = new Set<() => void>();
const snapshot = () => [...requests.values()].at(-1) ?? null;
function setRequest(id: symbol, kind: PageSkeletonKind | null) {
  const previous = snapshot();
  if (kind) requests.set(id, kind);
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
export function PageLoading({
  visible,
  kind = 'profile',
}: {
  visible: boolean;
  kind?: PageSkeletonKind;
}) {
  const hosted = useContext(LoadingHostContext);
  const [id] = useState(() => Symbol('page-loading'));
  useEffect(() => {
    setRequest(id, hosted && visible ? kind : null);
    return () => setRequest(id, null);
  }, [hosted, id, kind, visible]);
  return hosted ? null : <PageLoadingOverlay visible={visible} kind={kind} />;
}

export function PageLoadingOverlay({
  visible,
  kind = 'profile',
}: {
  visible: boolean;
  kind?: PageSkeletonKind;
}) {
  const theme = useCKTheme();
  const insets = useContext(SafeAreaInsetsContext);
  if (!visible) return null;
  const content = (
    <View
      style={[styles.cover, { backgroundColor: theme.background }]}
      accessibilityViewIsModal
      importantForAccessibility="yes"
      onStartShouldSetResponder={() => true}
    >
      <ScrollView
        contentContainerStyle={{ paddingTop: insets?.top ?? 0, paddingBottom: insets?.bottom ?? 0 }}
      >
        <PageSkeleton kind={kind} showHeader />
      </ScrollView>
    </View>
  );
  // Never present a UIKit modal while a native destination is being pushed.
  return Platform.OS === 'web' ? (
    <Modal visible transparent animationType="none">
      {content}
    </Modal>
  ) : (
    content
  );
}
const styles = StyleSheet.create({
  cover: { position: 'absolute', inset: 0, zIndex: 1000, elevation: 1000 },
});
