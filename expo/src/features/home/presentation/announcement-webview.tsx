import { useMemo, useRef, useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { WebView, type WebViewNavigation } from 'react-native-webview';

import { useCKTheme } from '../../../ui';
import {
  ANNOUNCEMENT_STORY_BRIDGE_JAVASCRIPT,
  announcementNavigationDecision,
  announcementStoryMessageFromNavigation,
  type AnnouncementWebViewProps,
} from './announcement-webview-contract';

export function AnnouncementWebView({
  html,
  url,
  fileUri,
  trustedStory = false,
  onStoryMessage,
  onPageFinished,
  pageFinishedJavaScript,
  showLoadingProgress = true,
}: AnnouncementWebViewProps) {
  const theme = useCKTheme();
  const webView = useRef<WebView>(null);
  const [progress, setProgress] = useState(0);
  const isTrustedLocalStory = Boolean(fileUri && trustedStory && onStoryMessage);
  const source = useMemo(() => {
    if (fileUri) return { uri: fileUri };
    if (url) return { uri: url };
    return { html: html ?? '' };
  }, [fileUri, html, url]);

  const shouldNavigate = (request: WebViewNavigation): boolean => {
    const storyMessage = announcementStoryMessageFromNavigation({
      requestedUrl: request.url,
      isTrustedLocalStory,
    });
    if (storyMessage !== null) {
      onStoryMessage?.(storyMessage);
      return false;
    }
    return (
      announcementNavigationDecision({
        requestedUrl: request.url,
        initialUrl: url,
        loadsLocalFile: Boolean(fileUri),
      }) === 'navigate'
    );
  };

  return (
    <View style={styles.container}>
      <WebView
        ref={webView}
        javaScriptEnabled={isTrustedLocalStory}
        onLoadEnd={({ nativeEvent }) => {
          if (isTrustedLocalStory) {
            webView.current?.injectJavaScript(ANNOUNCEMENT_STORY_BRIDGE_JAVASCRIPT);
          }
          if (pageFinishedJavaScript) webView.current?.injectJavaScript(pageFinishedJavaScript);
          onPageFinished?.(nativeEvent.url);
        }}
        onLoadProgress={({ nativeEvent }) => setProgress(nativeEvent.progress)}
        onMessage={
          isTrustedLocalStory ? ({ nativeEvent }) => onStoryMessage?.(nativeEvent.data) : undefined
        }
        onShouldStartLoadWithRequest={shouldNavigate}
        originWhitelist={['about:*', 'data:*', 'file:*', 'https://*', 'clashking-story://*']}
        setSupportMultipleWindows={false}
        source={source}
        style={[styles.webView, { backgroundColor: 'transparent' }]}
      />
      {showLoadingProgress && progress < 1 ? (
        <View style={[styles.progressTrack, { backgroundColor: theme.surfaceContainerHighest }]}>
          <View
            style={[
              styles.progress,
              { backgroundColor: theme.primary, width: `${Math.max(0, progress) * 100}%` },
            ]}
          />
        </View>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  webView: { flex: 1 },
  progressTrack: { position: 'absolute', left: 0, right: 0, top: 0, height: 3 },
  progress: { height: 3 },
});
