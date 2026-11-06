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
  const webView = useRef<WebView<object>>(null);
  const [progress, setProgress] = useState(0);
  const sourceKey = fileUri ?? url ?? html ?? '';
  const [failedSource, setFailedSource] = useState<string | null>(null);
  const loadFailed = failedSource === sourceKey;
  const isTrustedLocalStory = Boolean(
    fileUri?.startsWith('file:') && trustedStory && onStoryMessage,
  );
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
        initialUrl: fileUri ?? url,
        loadsLocalFile: isTrustedLocalStory,
      }) === 'navigate'
    );
  };

  return (
    <View style={styles.container}>
      <WebView<object>
        testID="announcement-webview"
        ref={webView}
        // Android disables file reads by default. Only our prepared story gets
        // local access; never grant a file page access to other files or origins.
        allowFileAccess={isTrustedLocalStory}
        allowFileAccessFromFileURLs={false}
        allowUniversalAccessFromFileURLs={false}
        allowingReadAccessToURL={isTrustedLocalStory ? (fileUri ?? undefined) : undefined}
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
        onError={() => setFailedSource(sourceKey)}
        onMessage={
          isTrustedLocalStory ? ({ nativeEvent }) => onStoryMessage?.(nativeEvent.data) : undefined
        }
        onShouldStartLoadWithRequest={shouldNavigate}
        originWhitelist={['about:*', 'data:*', 'file:*', 'https://*', 'clashking-story://*']}
        setSupportMultipleWindows={false}
        source={source}
        renderError={() => <View />}
        style={[styles.webView, { backgroundColor: theme.background }, loadFailed && styles.hidden]}
      />
      {loadFailed ? (
        <View style={[styles.error, { backgroundColor: theme.background }]}>
          <ErrorState
            title={t('generalError')}
            body={t('generalTryAgain')}
            actionLabel={t('generalRetry')}
            onAction={() => {
                setFailedSource(null);
              setProgress(0);
              webView.current?.reload();
            }}
          />
        </View>
      ) : null}
      {showLoadingProgress && !loadFailed && progress < 1 ? (
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
  hidden: { opacity: 0 },
  error: { position: 'absolute', top: 0, right: 0, bottom: 0, left: 0, justifyContent: 'center' },
  progressTrack: { position: 'absolute', left: 0, right: 0, top: 0, height: 3 },
  progress: { height: 3 },
});
