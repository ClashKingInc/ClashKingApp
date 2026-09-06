import { useEffect, useMemo, useState } from 'react';

import { useAppRuntime } from '../../../core/app/runtime-context';
import { StatsProvider, StatsRepository } from '../data';
import { StatsScreen } from './stats-screen';
import { useLinkParameters, linkChoice } from '../../../core/deep-links/link-parameters';
import { StatsDateFilter, type StatsSectionValue } from '../models';

export interface StatsRootProps {
  readonly onBack: () => void;
}

export function StatsRoot({ onBack }: StatsRootProps) {
  const runtime = useAppRuntime();
  const link = useLinkParameters();
  const provider = useMemo(() => {
    const value = new StatsProvider(new StatsRepository(runtime.contractApi));
    value.audience = linkChoice(link.audience, ['battle', 'world'], 'battle');
    const sections: readonly StatsSectionValue[] =
      value.audience === 'battle'
        ? ['ranked', 'armies', 'items', 'war', 'cwl']
        : ['overview', 'players', 'clans'];
    value.section = linkChoice(link.section, sections, sections[0]!);
    if (link.start && link.end) {
      const dates = new StatsDateFilter(
        new Date(`${link.start}T00:00:00`),
        new Date(`${link.end}T00:00:00`),
      );
      if (dates.inclusiveDays >= 1 && dates.inclusiveDays <= 90) value.dates = dates;
    }
    return value;
  }, [runtime, link]);
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
