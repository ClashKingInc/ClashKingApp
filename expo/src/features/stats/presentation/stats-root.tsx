import { useEffect, useMemo, useState } from 'react';

import { useAppRuntime } from '../../../core/app/runtime-context';
import { StatsProvider, StatsRepository } from '../data';
import { StatsScreen } from './stats-screen';

export interface StatsRootProps {
  readonly onBack: () => void;
}

export function StatsRoot({ onBack }: StatsRootProps) {
  const runtime = useAppRuntime();
  const provider = useMemo(() => new StatsProvider(new StatsRepository(runtime.api)), [runtime]);
  const [, setRevision] = useState(0);
  useEffect(() => {
    const unsubscribe = provider.subscribe(() => setRevision((value) => value + 1));
    provider.ensureLoaded();
    return () => {
      unsubscribe();
      provider.dispose();
    };
  }, [provider]);
  return <StatsScreen provider={provider} onBack={onBack} />;
}
