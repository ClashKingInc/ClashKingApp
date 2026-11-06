import { createContext, useContext, useEffect, useMemo, type PropsWithChildren } from 'react';
import { useStore } from 'zustand';
import { AppState } from 'react-native';

import { I18nProvider } from '../../i18n';
import { CKThemeProvider } from '../../ui';
import type { AppStateSnapshot } from './app-state';
import { getAppRuntime, type AppRuntime } from './runtime';

const AppRuntimeContext = createContext<AppRuntime | null>(null);

export function AppRuntimeProvider({
  children,
  runtime = getAppRuntime(),
}: PropsWithChildren<{ runtime?: AppRuntime }>) {
  const state = useStore(runtime.appState);
  const runtimeValue = useMemo(() => runtime, [runtime]);
  useEffect(() => {
    const subscription = AppState.addEventListener('change', (state) => {
      if (state === 'active')
        void runtime.appState
          .getState()
          .refreshSystemLocale()
          .catch(() => undefined);
    });
    return () => subscription.remove();
  }, [runtime]);
  return (
    <AppRuntimeContext.Provider value={runtimeValue}>
      <I18nProvider locale={state.locale}>
        <CKThemeProvider preference={state.themePreference}>{children}</CKThemeProvider>
      </I18nProvider>
    </AppRuntimeContext.Provider>
  );
}

export function useAppRuntime(): AppRuntime {
  const runtime = useContext(AppRuntimeContext);
  if (runtime === null) throw new Error('useAppRuntime must be used inside AppRuntimeProvider.');
  return runtime;
}

export function useAppState(): AppStateSnapshot {
  const runtime = useAppRuntime();
  return useStore(runtime.appState);
}
