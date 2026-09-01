import { useLocalSearchParams, useNavigation } from 'expo-router';
import { useEffect, useSyncExternalStore } from 'react';
import { StyleSheet, View } from 'react-native';

import {
  nativeSecondaryContent,
  notifyNativeSecondaryRemoved,
  subscribeNativeSecondaryLayer,
} from '../core/app/native-secondary-navigation';
import { useCKTheme } from '../ui';

export default function NativeSecondaryRoute() {
  const navigation = useNavigation();
  const theme = useCKTheme();
  const params = useLocalSearchParams<{ layer?: string | string[] }>();
  const key = Array.isArray(params.layer) ? params.layer[0] : params.layer;
  const content = useSyncExternalStore(
    (listener) => (key ? subscribeNativeSecondaryLayer(key, listener) : () => undefined),
    () => (key ? nativeSecondaryContent(key) : null),
    () => null,
  );

  useEffect(() => {
    if (!key) return;
    return navigation.addListener('beforeRemove', () => notifyNativeSecondaryRemoved(key));
  }, [key, navigation]);

  return <View style={[styles.root, { backgroundColor: theme.background }]}>{content}</View>;
}

const styles = StyleSheet.create({ root: { flex: 1 } });
