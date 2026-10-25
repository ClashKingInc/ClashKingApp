import { useEffect, useRef, useState } from 'react';
import { Linking, Platform, View } from 'react-native';
import { WebView } from 'react-native-webview';
import { CKText, PressableSurface, useCKTheme } from '../../ui';
import { useI18n } from '../../i18n';

export interface DashboardWebViewProps {
  url: string;
  handoff: { code: string; codeVerifier: string };
  onExpired: () => void;
}

export function DashboardWebView({ url, handoff, onExpired }: DashboardWebViewProps) {
  const theme = useCKTheme();
  const { t } = useI18n();
  const [failed, setFailed] = useState(false);
  const [ready, setReady] = useState(false);
  const [attempt, setAttempt] = useState(0);
  useEffect(() => {
    if (ready || failed) return;
    const timer = setTimeout(() => setFailed(true), 25_000);
    return () => clearTimeout(timer);
  }, [ready, failed, attempt]);
  const ref = useRef<WebView<object>>(null),
    origin = new URL(url).origin;
  if (failed)
    return (
      <View
        style={{ flex: 1, justifyContent: 'center', alignItems: 'center', padding: 24, gap: 16 }}
      >
        <CKText>{t('apiErrorServer')}</CKText>
        <PressableSurface
          onPress={() => {
            setFailed(false);
            setReady(false);
            setAttempt((value) => value + 1);
            onExpired();
          }}
        >
          <CKText>{t('generalRetry')}</CKText>
        </PressableSurface>
      </View>
    );
  return (
    <WebView<object>
      key={attempt}
      ref={ref}
      source={{ uri: url }}
      style={{ flex: 1, backgroundColor: theme.background }}
      containerStyle={{ backgroundColor: theme.background }}
      // The embedded dashboard owns its loading UI; a native skeleton would
      // flash a second, unrelated layout before the web page's own loader.
      startInLoadingState={false}
      bounces={false}
      overScrollMode="never"
      // Fabric's Android delegate expects a Double; WebView 14 forwards the
      // public string alias unchanged on Android and crashes before mounting.
      decelerationRate={Platform.OS === 'android' ? 0.985 : 0.998}
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
      onError={() => setFailed(true)}
      onHttpError={(event) => {
        if (event.nativeEvent.url.startsWith(origin + '/access')) setFailed(true);
      }}
      onRenderProcessGone={() => setFailed(true)}
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
          if (message.type === 'dashboard-ready') {
            // Android 14.x WebView messages provide an origin, not a full URL.
            // Validate the live document inside the injection as well, so a
            // delayed message cannot hand credentials to another same-origin page.
            setReady(true);
            ref.current?.injectJavaScript(
              `if(location.origin===${JSON.stringify(origin)}&&(location.pathname==='/access'||location.pathname==='/access/')){window.__clashkingDashboardHandoff?.(${JSON.stringify(handoff)});}true;`,
            );
          }
          if (message.type === 'dashboard-session-expired') onExpired();
        } catch {
          /* Untrusted page messages are not native commands. */
        }
      }}
    />
  );
}
