import { ASSET_ORIGIN } from '../../../core/assets/asset-origin';
import { useEffect, useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { WebView } from 'react-native-webview';
import { Skeleton } from '../../../ui';

import {
  sharedAchievementModelCache,
  type AchievementModelCache,
} from '../data/achievement-model-cache';
import type { AchievementModelRequest } from './contracts';
import { buildAchievementModelDocument } from './model-viewer-document';

export interface AchievementModelViewerProps extends AchievementModelRequest {
  readonly cache?: AchievementModelCache;
}

export function AchievementModelViewer({
  cache = sharedAchievementModelCache,
  ...request
}: AchievementModelViewerProps) {
  const modelUrl = request.achievement.modelUrl;
  const [resolved, setResolved] = useState(() => ({
    modelUrl,
    source: cache.peek(modelUrl),
  }));
  const source = resolved.modelUrl === modelUrl ? resolved.source : cache.peek(modelUrl);

  useEffect(() => {
    let active = true;
    void cache.resolve(modelUrl).then((nextSource) => {
      if (active) setResolved({ modelUrl, source: nextSource });
    });
    return () => {
      active = false;
    };
  }, [cache, modelUrl]);

  if (source === undefined)
    return (
      <View style={styles.loading}>
        <Skeleton height="100%" radius={16} />
      </View>
    );
  return (
    <WebView
      accessibilityElementsHidden={!request.interactive}
      accessibilityLabel={request.semanticLabel}
      allowsInlineMediaPlayback
      androidLayerType="hardware"
      bounces={false}
      cacheEnabled
      javaScriptEnabled
      originWhitelist={['https://*', 'data:*']}
      pointerEvents={request.interactive ? 'auto' : 'none'}
      scrollEnabled={false}
      setSupportMultipleWindows={false}
      source={{
        html: buildAchievementModelDocument(source, request),
        baseUrl: `${ASSET_ORIGIN}/`,
      }}
      style={styles.webView}
    />
  );
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  loading: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  webView: { flex: 1, backgroundColor: 'transparent' },
});
