import { useEffect } from 'react';

import { useAppRuntime } from '../../../core/app/runtime-context';
import { AchievementsScreen } from './achievements-screen';

export function AchievementsRoot({ onBack }: { readonly onBack?: () => void }) {
  const runtime = useAppRuntime();
  const sessionUserId = runtime.auth.state.currentUser?.userId ?? null;
  useEffect(() => runtime.achievements.bindSession(sessionUserId), [runtime, sessionUserId]);

  return <AchievementsScreen onBack={onBack} repository={runtime.achievements} />;
}
