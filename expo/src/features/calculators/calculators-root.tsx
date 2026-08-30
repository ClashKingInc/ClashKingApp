import { useEffect, useMemo, useState, useSyncExternalStore } from 'react';

import { useAppRuntime } from '../../core/app/runtime-context';
import { gameDataState } from '../../core/game-data/game-data-state';
import {
  DamageCatalog,
  DamageCalculatorSession,
  type DamageAccountPreset,
} from '../damage-calculator';
import {
  UpgradePlanPreferences,
  type UpgradeTrackerSnapshot,
} from '../upgrade-tracker/models/upgrade-tracker-models';
import type { UpgradeTrackerRepository } from '../upgrade-tracker/data/upgrade-tracker-repository';
import { verifiedDamageAccountPresets } from './calculator-logic';
import { CalculatorsScreen } from './calculators-screen';

export interface CalculatorsRootProps {
  readonly onBack: () => void;
  readonly catalog?: DamageCatalog;
  readonly accountPresets?: readonly DamageAccountPreset[];
  readonly initialTrackerSnapshot?: UpgradeTrackerSnapshot;
  readonly trackerRepository?: UpgradeTrackerRepository;
  readonly onOpenUpgradeTracker?: (tag: string | null) => void;
}

/** Live one-for-one replacement for Flutter's CalculatorsPage. */
export function CalculatorsRoot({
  onBack,
  catalog,
  accountPresets,
  initialTrackerSnapshot,
  trackerRepository,
  onOpenUpgradeTracker = () => undefined,
}: CalculatorsRootProps) {
  const runtime = useAppRuntime();
  const accounts = useSyncExternalStore(
    (listener) => runtime.accounts.subscribe(listener),
    () => runtime.accounts.accounts,
  );
  const profiles = useSyncExternalStore(
    (listener) => runtime.players.subscribe(listener),
    () => runtime.players.profiles,
  );
  const presets = useMemo(
    () =>
      accountPresets ??
      verifiedDamageAccountPresets(
        accounts.filter((account) => account.isVerified).map((account) => account.playerTag),
        profiles,
      ),
    [accountPresets, accounts, profiles],
  );
  const activeCatalog = useMemo(
    () => catalog ?? DamageCatalog.fromBundle(gameDataState.bundleData),
    [catalog],
  );
  const session = useMemo(() => {
    const value = new DamageCalculatorSession(activeCatalog);
    const initial =
      presets.find((preset) => preset.tag === runtime.accounts.selectedTag) ?? presets[0];
    if (initial) value.applyPreset(initial);
    return value;
  }, [activeCatalog, presets, runtime.accounts.selectedTag]);
  const repository = trackerRepository ?? runtime.upgrades;
  const initialFarmTag =
    presets.find((preset) => preset.tag === runtime.accounts.selectedTag)?.tag ??
    presets[0]?.tag ??
    null;
  const [farmTag, setFarmTag] = useState<string | null>(initialFarmTag);
  const initialCachedSnapshot =
    !initialTrackerSnapshot && initialFarmTag ? repository.peekCached(initialFarmTag) : null;
  const [trackerSnapshot, setTrackerSnapshot] = useState<UpgradeTrackerSnapshot | null>(
    initialTrackerSnapshot ?? initialCachedSnapshot,
  );
  const [trackerPreferences, setTrackerPreferences] = useState(new UpgradePlanPreferences());
  const [trackerGoldPassPercent, setTrackerGoldPassPercent] = useState(0);
  const [trackerLoading, setTrackerLoading] = useState(
    Boolean(
      initialFarmTag &&
      !initialTrackerSnapshot &&
      !initialCachedSnapshot &&
      (accountPresets === undefined || trackerRepository !== undefined),
    ),
  );

  useEffect(() => {
    if (!farmTag || initialTrackerSnapshot) return;
    const cached = repository.peekCached(farmTag);
    if (accountPresets !== undefined && trackerRepository === undefined && !cached) return;
    let active = true;
    void Promise.all([repository.load(farmTag), repository.loadPlanPreferences(farmTag)])
      .then(([snapshot, draft]) => {
        if (!active) return;
        setTrackerSnapshot(snapshot);
        setTrackerPreferences(
          UpgradePlanPreferences.fromJson(
            draft?.heuristics && typeof draft.heuristics === 'object'
              ? (draft.heuristics as Record<string, unknown>)
              : undefined,
          ),
        );
        const detected = snapshot
          ? Math.max(
              snapshot.boosts.builderCostReductionPercent,
              snapshot.boosts.builderTimeReductionPercent,
              snapshot.boosts.labCostReductionPercent,
              snapshot.boosts.labTimeReductionPercent,
            )
          : 0;
        const saved = Number(draft?.gold_pass_percent);
        setTrackerGoldPassPercent(
          Number.isFinite(saved) ? Math.max(0, Math.min(100, saved)) : detected,
        );
      })
      .catch(() => {
        if (active) setTrackerSnapshot(null);
      })
      .finally(() => {
        if (active) setTrackerLoading(false);
      });
    return () => {
      active = false;
    };
  }, [accountPresets, farmTag, initialTrackerSnapshot, repository, trackerRepository]);

  return (
    <CalculatorsScreen
      session={session}
      accountPresets={presets}
      trackerSnapshot={trackerSnapshot}
      trackerLoading={trackerLoading}
      trackerPreferences={trackerPreferences}
      trackerGoldPassPercent={trackerGoldPassPercent}
      onFarmAccountChanged={(tag) => {
        setFarmTag(tag);
        const cached = tag ? repository.peekCached(tag) : null;
        setTrackerSnapshot(tag ? (initialTrackerSnapshot ?? cached) : null);
        setTrackerLoading(
          Boolean(
            tag &&
            !initialTrackerSnapshot &&
            !cached &&
            (accountPresets === undefined || trackerRepository !== undefined),
          ),
        );
      }}
      onOpenUpgradeTracker={onOpenUpgradeTracker}
      onBack={onBack}
    />
  );
}
