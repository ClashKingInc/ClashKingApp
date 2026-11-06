import { useEffect, useMemo, useRef } from 'react';
import { StyleSheet, View } from 'react-native';
import { Skeleton } from './feedback';
import { useBundledModelSource, type BundledModelSceneProps } from './bundled-model-source';
import { buildModelViewerDocument } from './model-viewer-document';

export type { BundledModelSceneProps } from './bundled-model-source';

export function BundledModelScene({
  source,
  label,
  playing,
  cameraOrbit,
  cameraTarget,
}: BundledModelSceneProps) {
  const model = useBundledModelSource(source);
  const viewer = useRef<HTMLIFrameElement>(null);
  const document = useMemo(
    () =>
      model.uri
        ? buildModelViewerDocument(model.uri, {
            label,
            eager: true,
            animated: true,
            cameraOrbit,
            cameraTarget,
          })
        : undefined,
    [model.uri, label, cameraOrbit, cameraTarget],
  );
  const updatePlayback = () =>
    viewer.current?.contentWindow?.postMessage({ type: 'ck-model-playback', playing }, '*');
  useEffect(() => {
    viewer.current?.contentWindow?.postMessage({ type: 'ck-model-playback', playing }, '*');
  }, [playing, document]);
  return (
    <View
      accessible
      accessibilityRole="image"
      accessibilityLabel={label}
      pointerEvents="none"
      style={styles.stage}
    >
      {model.failed ? null : document ? (
        <iframe
          ref={viewer}
          title={label}
          aria-hidden
          tabIndex={-1}
          sandbox="allow-scripts allow-same-origin"
          srcDoc={document}
          onLoad={updatePlayback}
          style={{
            width: '100%',
            height: '100%',
            border: 0,
            display: 'block',
            background: 'transparent',
            pointerEvents: 'none',
          }}
        />
      ) : (
        <Skeleton height="100%" radius={16} />
      )}
    </View>
  );
}
const styles = StyleSheet.create({
  stage: { flex: 1, width: '100%', height: '100%', backgroundColor: 'transparent' },
});
