import { useEffect, useMemo, useRef, useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { WebView } from 'react-native-webview';
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
  const viewer = useRef<WebView>(null);
  const [failedSource, setFailedSource] = useState<number>();
  const document = useMemo(
    () =>
      model.uri
        ? {
            html: buildModelViewerDocument(model.uri, {
              label,
              eager: true,
              animated: true,
              cameraOrbit,
              cameraTarget,
            }),
            baseUrl: 'https://assets.clashk.ing/',
          }
        : undefined,
    [model.uri, label, cameraOrbit, cameraTarget],
  );
  const updatePlayback = () =>
    viewer.current?.postMessage(JSON.stringify({ type: 'ck-model-playback', playing }));
  useEffect(() => {
    viewer.current?.postMessage(JSON.stringify({ type: 'ck-model-playback', playing }));
  }, [playing, document]);
  return (
    <View
      accessible
      accessibilityRole="image"
      accessibilityLabel={label}
      pointerEvents="none"
      style={styles.stage}
    >
      {model.failed || failedSource === source ? null : document ? (
        <WebView
          ref={viewer}
          accessibilityElementsHidden
          importantForAccessibility="no-hide-descendants"
          source={document}
          style={styles.stage}
          javaScriptEnabled
          cacheEnabled
          bounces={false}
          scrollEnabled={false}
          pointerEvents="none"
          androidLayerType="hardware"
          originWhitelist={['https://*', 'data:*']}
          setSupportMultipleWindows={false}
          allowsInlineMediaPlayback
          onLoadEnd={updatePlayback}
          onError={() => setFailedSource(source)}
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
