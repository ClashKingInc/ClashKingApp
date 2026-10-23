import { useState } from 'react';

import {
  disableGameHandoffWarning,
  shouldShowGameHandoffWarning,
} from '../core/game-handoff-preference';

export function useClashGameHandoff(open: (target: string) => void) {
  const [pending, setPending] = useState<string>();

  const request = (target: string) => {
    void shouldShowGameHandoffWarning().then((showWarning) => {
      if (showWarning) setPending(target);
      else {
        setPending(undefined);
        open(target);
      }
    });
  };
  const cancel = () => setPending(undefined);
  const confirm = (dontShowAgain: boolean) => {
    const target = pending;
    setPending(undefined);
    if (!target) return;
    void (async () => {
      if (dontShowAgain) {
        try {
          await disableGameHandoffWarning();
        } catch {
          // A storage failure leaves the warning enabled for the next handoff.
        }
      }
      open(target);
    })();
  };

  return { visible: pending !== undefined, request, cancel, confirm };
}
