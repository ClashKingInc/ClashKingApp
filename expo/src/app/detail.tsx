import { router, useLocalSearchParams, useNavigation, useRoute } from 'expo-router';
import { useEffect, useSyncExternalStore } from 'react';
import { StyleSheet, View } from 'react-native';

import {
  nativeSecondaryContent,
  notifyNativeSecondaryRemoved,
  subscribeNativeSecondaryLayer,
} from '../core/app/native-secondary-navigation';
import { PageSkeleton, useCKTheme } from '../ui';

export default function NativeSecondaryRoute() {
  const theme = useCKTheme();
  const navigation = useNavigation();
  const route = useRoute();
  const params = useLocalSearchParams<{ layer?: string | string[] }>();
  const key = Array.isArray(params.layer) ? params.layer[0] : params.layer;
  const content = useSyncExternalStore(
    (listener) => (key ? subscribeNativeSecondaryLayer(key, listener) : () => undefined),
    () => (key ? nativeSecondaryContent(key) : null),
    () => null,
  );

  useEffect(() => {
    if (!key) return;
    // Fast Refresh and effect replay also run cleanup while this route remains
    // in the stack. Only a real native removal may discard its retained layer;
    // otherwise refreshing a detail screen also closes its parent clan page.
    return () => {
      const state = navigation.getState();
      if (state && !state.routes.some((entry) => entry.key === route.key)) {
        notifyNativeSecondaryRemoved(key);
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

  return (
    <View style={[styles.root, { backgroundColor: theme.background }]}>
      {content ?? (
        <View style={styles.loading}>
          <PageSkeleton kind="profile" showHeader />
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  loading: { flex: 1, alignItems: 'center', justifyContent: 'center' },
});
