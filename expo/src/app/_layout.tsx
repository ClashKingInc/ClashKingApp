import '../i18n/intl-polyfills';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import {
  ErrorBoundary as ExpoRouterErrorBoundary,
  Stack,
  type ErrorBoundaryProps,
  useNavigationContainerRef,
} from 'expo-router';
import * as SplashScreen from 'expo-splash-screen';
import { StatusBar } from 'expo-status-bar';
import { useCallback, useEffect, useRef, useState } from 'react';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { registerPlatformPushBackgroundHandler } from '../core/app/platform-push';
import {
  initializeObservability,
  registerNavigationContainer,
  reportException,
} from '../core/observability/observability';
import { AppRuntimeProvider } from '../core/app/runtime-context';
import { loadClashKingFont } from '../core/fonts/clashking-font-service';
import { hideWebLaunchScreen } from '../core/app/launch-screen-runtime';
import { useCKThemeMode } from '../ui';
import { ExpoDeepLinkRuntime } from '../core/deep-links/expo-deep-link-runtime';
import { queueAppLink } from '../core/deep-links/link-inbox';

void SplashScreen.preventAutoHideAsync();
initializeObservability();
registerPlatformPushBackgroundHandler((error) => {
  reportException(error, 'push.background_handler');
});

const queryClient = new QueryClient({
  defaultOptions: {
    queries: { retry: 1, staleTime: 30_000 },
    mutations: { retry: false },
  },
});

export default function RootLayout() {
  // Capture navigation before authentication so a sign-in does not lose the destination.
  useEffect(() => {
    const links = new ExpoDeepLinkRuntime();
    let active = true;
    let receivedEvent = false;
    const stop = links.subscribe((url) => {
      receivedEvent = true;
      queueAppLink(url);
    });
    void links
      .getInitialUrl()
      .then((url) => {
        if (active && !receivedEvent && url) queueAppLink(url);
      })
      .catch((error) => reportException(error, 'deep_link.capture'));
    return () => {
      active = false;
      stop();
    };
  }, []);
  const [fontReady, setFontReady] = useState(false);
  const launchHidden = useRef(false);
  const navigationContainerRef = useNavigationContainerRef();
  useEffect(() => {
    registerNavigationContainer(navigationContainerRef);
  }, [navigationContainerRef]);
  useEffect(() => {
    let mounted = true;
    void loadClashKingFont().finally(() => {
      if (!mounted) return;
      setFontReady(true);
    });
    return () => {
      mounted = false;
    };
  }, []);
  const handleRootLayout = useCallback(() => {
    if (!fontReady || launchHidden.current) return;
    launchHidden.current = true;
    hideWebLaunchScreen();
    void SplashScreen.hideAsync();
  }, [fontReady]);

  if (!fontReady) return null;
  return (
    <GestureHandlerRootView style={{ flex: 1 }} onLayout={handleRootLayout}>
      <SafeAreaProvider>
        <QueryClientProvider client={queryClient}>
          <AppRuntimeProvider>
            <AppStatusBar />
            <Stack screenOptions={{ headerShown: false }}>
              <Stack.Screen name="index" options={{ animation: 'none', gestureEnabled: false }} />
              <Stack.Screen name="detail" options={{ gestureEnabled: true }} />
            </Stack>
          </AppRuntimeProvider>
        </QueryClientProvider>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}

export function ErrorBoundary(props: ErrorBoundaryProps) {
  useEffect(() => reportException(props.error, 'router.error_boundary'), [props.error]);
  return <ExpoRouterErrorBoundary {...props} />;
}

function AppStatusBar() {
  const theme = useCKThemeMode();
  return <StatusBar style={theme === 'dark' ? 'light' : 'dark'} />;
}
