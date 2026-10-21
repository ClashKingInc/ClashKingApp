import { useMemo, useRef, useState } from 'react';
import { Linking, Platform, StyleSheet, View } from 'react-native';
import { WebView, type WebViewNavigation } from 'react-native-webview';

import { ErrorState, useCKTheme } from '../../../ui';
import { useI18n } from '../../../i18n';
import {
  ANNOUNCEMENT_STORY_BRIDGE_JAVASCRIPT,
  ANNOUNCEMENT_STORY_VIEWPORT_JAVASCRIPT,
  announcementNavigationDecision,
  announcementStoryMessageFromNavigation,
  externalArticleLink,
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
  const { t } = useI18n();
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
    const externalUrl = externalArticleLink(request, {
      trustedStory,
      platform: Platform.OS,
      initialUrl: url,
    });
    if (externalUrl) {
      void Linking.openURL(externalUrl).catch(() => undefined);
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
        testID="announcement-webview"
        ref={webView}
        scalesPageToFit={isTrustedLocalStory ? false : undefined}
        setBuiltInZoomControls={!isTrustedLocalStory}
        setDisplayZoomControls={false}
        bounces={!isTrustedLocalStory}
        injectedJavaScriptBeforeContentLoaded={
          isTrustedLocalStory
            ? ANNOUNCEMENT_STORY_BRIDGE_JAVASCRIPT + ANNOUNCEMENT_STORY_VIEWPORT_JAVASCRIPT
            : undefined
        }
        javaScriptEnabled={isTrustedLocalStory}
        onLoadEnd={({ nativeEvent }) => {
          if (isTrustedLocalStory) {
            webView.current?.injectJavaScript(
              ANNOUNCEMENT_STORY_BRIDGE_JAVASCRIPT + ANNOUNCEMENT_STORY_VIEWPORT_JAVASCRIPT,
            );
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
        renderError={() => (
          <View
            style={[
              styles.container,
              { backgroundColor: theme.background, justifyContent: 'center' },
            ]}
          >
            <ErrorState
              title={t('generalError')}
              body={t('generalTryAgain')}
              actionLabel={t('generalRetry')}
              onAction={() => webView.current?.reload()}
            />
          </View>
        )}
        style={[styles.webView, { backgroundColor: theme.background }]}
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
