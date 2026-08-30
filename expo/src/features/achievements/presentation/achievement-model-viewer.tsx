import { useEffect, useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { WebView } from 'react-native-webview';

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

  if (source === undefined) return <View style={styles.fill} />;
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
        baseUrl: 'https://assets.clashk.ing/',
      }}
      style={styles.webView}
    />
  );
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  webView: { flex: 1, backgroundColor: 'transparent' },
});
