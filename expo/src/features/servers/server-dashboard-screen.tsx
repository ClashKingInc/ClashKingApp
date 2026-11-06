import { useAdaptiveLayout } from '../../ui/adaptive-layout';
import { useNativeRailBack } from '../../ui/native-back-context';
import { useCallback, useEffect, useState, useRef } from 'react';
import { BackHandler, Pressable, View, useWindowDimensions } from 'react-native';
import { ChevronLeft } from 'lucide-react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Effect } from 'effect';
import * as Crypto from 'expo-crypto';
import { DashboardGrantEndpoint } from '@clashking/api-contracts/expo';
import { useAppRuntime } from '../../core/app/runtime-context';
import { CKText, LoadingIndicator, useCKTheme, useCKThemeMode } from '../../ui';
import { materialBackLabel, useI18n } from '../../i18n';
import { DashboardWebView } from './dashboard-webview';
import type { DashboardServer } from './servers-root';

export function ServerDashboardScreen({
  server,
  onBack,
}: {
  server: DashboardServer;
  onBack: () => void;
}) {
  const runtime = useAppRuntime(),
    theme = useCKTheme(),
    { t, locale } = useI18n();
  const selected = server;
  const layout = useAdaptiveLayout();
  const nativeBack = useNativeRailBack(onBack);
  const { width, height } = useWindowDimensions();
  // Use the short edge so rotating a phone cannot enable the tablet header.
  const showNavigationBar = layout.isExpanded || (Math.min(width, height) >= 600 && width > height);
  const [handoff, setHandoff] = useState<{
      code: string;
      codeVerifier: string;
      locale: string;
      theme: string;
    }>(),
    [error, setError] = useState(false),
    [generation, setGeneration] = useState(0);
  const renewals = useRef(0);
  const mode = useCKThemeMode();
  const dashboardOrigin =
    runtime.configuration.environment === 'production'
      ? 'https://dash.clashk.ing'
      : 'https://local-dash.clashk.ing';
  useEffect(() => {
    let active = true;
    void (async () => {
      const codeVerifier = Crypto.randomUUID() + Crypto.randomUUID();
      const digest = await Crypto.digestStringAsync(
        Crypto.CryptoDigestAlgorithm.SHA256,
        codeVerifier,
        { encoding: Crypto.CryptoEncoding.BASE64 },
      );
      const pkceChallenge = digest.replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '');
      const grant = await Effect.runPromise(
        runtime.contractApi.execute(DashboardGrantEndpoint, {
          path: { serverId: selected.id },
          query: {},
          body: { source: 'app', pkceChallenge },
        }),
      );
      if (active) setHandoff({ code: grant.code, codeVerifier, locale, theme: mode });
    })().catch(() => {
      if (active) setError(true);
    });
    return () => {
      active = false;
    };
  }, [runtime, selected, generation, locale, mode]);
  const expired = useCallback(() => {
    if (renewals.current++ < 2) {
      setHandoff(undefined);
      setGeneration((value) => value + 1);
    } else setError(true);
  }, []);
  useEffect(() => {
    let subscription: ReturnType<typeof BackHandler.addEventListener> | undefined;
    // Android keeps underlying navigators mounted. Register after their effects
    // so the visible dashboard owns Back, not a hidden navigator's history.
    const frame = requestAnimationFrame(() => {
      subscription = BackHandler.addEventListener('hardwareBackPress', () => {
        onBack();
        return true;
      });
    });
    return () => {
      cancelAnimationFrame(frame);
      subscription?.remove();
    };
  }, [onBack]);
  return (
    <SafeAreaView
      edges={['top', 'left', 'right', 'bottom']}
      style={{ flex: 1, backgroundColor: theme.background }}
    >
      {showNavigationBar ? (
        <View
          style={{
            flexDirection: 'row',
            alignItems: 'center',
            paddingHorizontal: layout.isExpanded ? 16 : 8,
            minHeight: layout.isExpanded ? 64 : undefined,
          }}
        >
          {!nativeBack ? (
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={materialBackLabel(locale)}
              onPress={onBack}
              style={{
                minWidth: 44,
                minHeight: 44,
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <ChevronLeft color={theme.onSurface} size={24} />
            </Pressable>
          ) : null}
          <CKText
            role={layout.isExpanded ? 'titleSmall' : 'labelLarge'}
            numberOfLines={1}
            style={{ flex: 1 }}
          >
            {server.name}
          </CKText>
        </View>
      ) : null}
      {error ? (
        <Pressable
          onPress={() => {
            renewals.current = 0;
            setError(false);
            setHandoff(undefined);
            setGeneration((value) => value + 1);
          }}
          style={{ padding: 24 }}
        >
          <CKText>{t('generalRetry')}</CKText>
        </Pressable>
      ) : handoff ? (
        <DashboardWebView
          key={`${selected.id}:${generation}`}
          url={`${dashboardOrigin}/access?embedded=1&guildId=${selected.id}&locale=${handoff.locale}&theme=${handoff.theme}`}
          handoff={handoff}
          onExpired={expired}
        />
      ) : (
        <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', gap: 12 }}>
          <CKText role="titleMedium">{server.name}</CKText>
          <LoadingIndicator label={t('generalLoading')} />
        </View>
      )}
    </SafeAreaView>
  );
}
