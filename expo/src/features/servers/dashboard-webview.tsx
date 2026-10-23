import { useRef } from 'react';
import { Linking } from 'react-native';
import { WebView } from 'react-native-webview';
import { PageSkeleton, useCKTheme } from '../../ui';

export interface DashboardWebViewProps {
  url: string;
  handoff: { code: string; codeVerifier: string };
  onExpired: () => void;
}

export function DashboardWebView({ url, handoff, onExpired }: DashboardWebViewProps) {
  const theme = useCKTheme();
  const ref = useRef<WebView<object>>(null),
    origin = new URL(url).origin;
  return (
    <WebView<object>
      ref={ref}
      source={{ uri: url }}
      style={{ flex: 1, backgroundColor: theme.background }}
      containerStyle={{ backgroundColor: theme.background }}
      startInLoadingState
      renderLoading={() => <PageSkeleton kind="form" />}
      bounces={false}
      overScrollMode="never"
      decelerationRate="normal"
      automaticallyAdjustContentInsets={false}
      contentInsetAdjustmentBehavior="never"
      // Color the document before its CSS arrives; native and HTML backgrounds
      // must agree at load/scroll boundaries, not default to opaque white.
      injectedJavaScriptBeforeContentLoaded={`document.documentElement.style.backgroundColor=${JSON.stringify(theme.background)};true;`}
      sharedCookiesEnabled
      thirdPartyCookiesEnabled
      javaScriptEnabled
      domStorageEnabled
      allowFileAccess={false}
      allowUniversalAccessFromFileURLs={false}
      originWhitelist={[origin]}
      mixedContentMode="never"
      onShouldStartLoadWithRequest={(request) => {
        try {
          const next = new URL(request.url);
          if (next.origin === origin) return true;
          if (next.protocol === 'https:' || next.protocol === 'http:')
            void Linking.openURL(request.url);
          return false;
        } catch {
          return false;
        }
      }}
      onMessage={(event) => {
        try {
          if (new URL(event.nativeEvent.url).origin !== origin) return;
          const message = JSON.parse(event.nativeEvent.data);
          if (
            message.type === 'dashboard-ready' &&
            new URL(event.nativeEvent.url).pathname.replace(/\/$/, '') === '/access'
          )
            ref.current?.injectJavaScript(
              `window.__clashkingDashboardHandoff?.(${JSON.stringify(handoff)});true;`,
            );
          if (message.type === 'dashboard-session-expired') onExpired();
        } catch {
          /* Untrusted page messages are not native commands. */
        }
      }}
    />
  );
}
