import * as Updates from 'expo-updates';
import { createContext, useContext, useEffect, useRef, useState, type ReactNode } from 'react';
import { Platform } from 'react-native';

import {
  captureStartupReloadScreen,
  isResumingStartupUpdate,
  markStartupUpdateReload,
} from './startup-update-handoff';
import { useCKTheme } from '../../ui';
import { reportException } from '../observability/observability';
const StartupUpdateContext = createContext({
  ready: true,
  downloading: false,
  progress: 0,
  continueInBackground: () => {},
});

export const useStartupUpdate = () => useContext(StartupUpdateContext);

export interface StartupUpdateRuntime {
  check(): Promise<{ isAvailable: boolean; isRollBackToEmbedded: boolean }>;
  fetch(): Promise<{ isNew: boolean; isRollBackToEmbedded: boolean }>;
  reload(): Promise<void>;
}

export async function loadStartupUpdate(
  runtime: StartupUpdateRuntime,
  callbacks: { downloading(): void; shouldReload(): boolean },
) {
  const result = await runtime.check();
  if (!result.isAvailable && !result.isRollBackToEmbedded) return;
  callbacks.downloading();
  // Keep quick downloads readable without adding time to slower downloads.
  // Start the minimum alongside the fetch; an explicit background choice still
  // releases the screen immediately and prevents the later automatic reload.
  const minimumDisplay = new Promise<void>((resolve) => setTimeout(resolve, 3000));
  let downloaded;
  try {
    downloaded = await runtime.fetch();
  } finally {
    await minimumDisplay;
  }
  if ((downloaded.isNew || downloaded.isRollBackToEmbedded) && callbacks.shouldReload()) {
    await runtime.reload();
  }
}

/** The store build checks once before bootstrap; Metro and web are never blocked. */
export function StartupUpdateGate({ children }: { children: ReactNode }) {
  const theme = useCKTheme();
  const reloadBackground = useRef(theme.surface);
  useEffect(() => {
    reloadBackground.current = theme.surface;
  }, [theme.surface]);
  const enabled =
    !isResumingStartupUpdate() && Platform.OS !== 'web' && !__DEV__ && Updates.isEnabled;
  const [released, setReleased] = useState(!enabled);
  const [downloading, setDownloading] = useState(false);
  const mayReload = useRef(true);
  const { downloadProgress } = Updates.useUpdates();

  useEffect(() => {
    if (!enabled) return;
    let active = true;
    mayReload.current = true;
    const release = () => {
      mayReload.current = false;
      if (active) setReleased(true);
    };
    // A slow manifest request must not prevent someone opening the installed app.
    const checkDeadline = setTimeout(release, 5000);
    void loadStartupUpdate(
      {
        check: Updates.checkForUpdateAsync,
        fetch: Updates.fetchUpdateAsync,
        reload: async () => {
          await markStartupUpdateReload().catch(() => undefined);
          // Expo otherwise inserts a white native screen between JS runtimes.
          // Hold the existing splash across that gap; the new bundle resumes
          // with settled branding rather than replaying the entrance animation.
          const image = await captureStartupReloadScreen();
          await Updates.reloadAsync({
            reloadScreenOptions: {
              backgroundColor: reloadBackground.current,
              image,
              imageFullScreen: true,
              imageResizeMode: 'stretch',
              spinner: { enabled: false },
              fade: true,
            },
          });
        },
      },
      {
        downloading: () => {
          clearTimeout(checkDeadline);
          if (active) setDownloading(true);
        },
        shouldReload: () => active && mayReload.current,
      },
    )
      .catch((error) => reportException(error, 'startup.update'))
      .finally(() => {
        clearTimeout(checkDeadline);
        if (active) setReleased(true);
      });
    return () => {
      active = false;
      mayReload.current = false;
      clearTimeout(checkDeadline);
    };
  }, [enabled]);

  // Keep the application and its one startup cover mounted across the update
  // check. Bootstrap waits for ready, rather than replacing the branding tree.
  return (
    <StartupUpdateContext.Provider
      value={{
        ready: released,
        downloading,
        progress: downloadProgress ?? 0,
        continueInBackground: () => {
          mayReload.current = false;
          setReleased(true);
        },
      }}
    >
      {children}
    </StartupUpdateContext.Provider>
  );
}
