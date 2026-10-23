import * as Updates from 'expo-updates';
import { useEffect, useRef, useState, type ReactNode } from 'react';
import { Platform } from 'react-native';

import { reportException } from '../observability/observability';
import { StartupLoadingScreen } from './startup-loading';

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
  const downloaded = await runtime.fetch();
  if ((downloaded.isNew || downloaded.isRollBackToEmbedded) && callbacks.shouldReload()) {
    await runtime.reload();
  }
}

/** The store build checks once before bootstrap; Metro and web are never blocked. */
export function StartupUpdateGate({ children }: { children: ReactNode }) {
  const enabled = Platform.OS !== 'web' && !__DEV__ && Updates.isEnabled;
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
        reload: Updates.reloadAsync,
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

  if (released) return children;
  return (
    <StartupLoadingScreen
      update={{ downloading, progress: downloadProgress ?? 0 }}
      onUpdateInBackground={() => {
        mayReload.current = false;
        setReleased(true);
      }}
    />
  );
}
