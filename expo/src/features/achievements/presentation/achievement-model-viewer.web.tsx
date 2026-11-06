import { createElement, useEffect, useState } from 'react';
import { StyleSheet, View } from 'react-native';
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
  return createElement('iframe', {
    'aria-label': request.semanticLabel,
    sandbox: 'allow-scripts allow-same-origin',
    srcDoc: buildAchievementModelDocument(source, request),
    style: {
      width: '100%',
      height: '100%',
      border: 0,
      background: 'transparent',
      pointerEvents: request.interactive ? 'auto' : 'none',
    },
  });
}

const styles = StyleSheet.create({
  loading: { flex: 1, alignItems: 'center', justifyContent: 'center' },
});
