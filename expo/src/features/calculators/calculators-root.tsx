import { useMemo, useSyncExternalStore } from 'react';
import { useAppRuntime } from '../../core/app/runtime-context';
import { gameDataState, subscribeToGameDataRevision } from '../../core/game-data/game-data-state';
import {
  DamageCatalog,
  DamageCalculatorSession,
  type DamageAccountPreset,
} from '../damage-calculator';
import type { UpgradeTrackerSnapshot } from '../upgrade-tracker/models/upgrade-tracker-models';
import type { UpgradeTrackerRepository } from '../upgrade-tracker/data/upgrade-tracker-repository';
import { verifiedDamageAccountPresets } from './calculator-logic';
import { CalculatorHub } from './calculator-hub';

export interface CalculatorsRootProps {
  readonly onBack: () => void;
  readonly catalog?: DamageCatalog;
  readonly accountPresets?: readonly DamageAccountPreset[];
  readonly initialTrackerSnapshot?: UpgradeTrackerSnapshot;
  readonly trackerRepository?: UpgradeTrackerRepository;
  readonly onOpenUpgradeTracker?: (tag: string | null) => void;
}

export function CalculatorsRoot({ onBack, catalog, accountPresets }: CalculatorsRootProps) {
  const runtime = useAppRuntime();
  const accounts = useSyncExternalStore(
    (listener) => runtime.accounts.subscribe(listener),
    () => runtime.accounts.accounts,
  );
  const profiles = useSyncExternalStore(
    (listener) => runtime.players.subscribe(listener),
    () => runtime.players.profiles,
  );
  const revision = useSyncExternalStore(
    subscribeToGameDataRevision,
    () => gameDataState.revision,
    () => gameDataState.revision,
  );
  const verifiedTags = new Set(
    accounts.filter((account) => account.isVerified).map((account) => account.playerTag),
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
  const activeCatalog = useMemo(() => {
    // The bundle is mutated in place; its revision is the cache invalidation key.
    void revision;
    return catalog ?? DamageCatalog.fromBundle(gameDataState.bundleData);
  }, [catalog, revision]);
  const session = useMemo(() => new DamageCalculatorSession(activeCatalog), [activeCatalog]);
  // Farming is disabled. Merely opening this public tool must never request a
  // private upgrade snapshot or fetch saved upgrade preferences.
  return (
    <CalculatorHub
      session={session}
      accountPresets={presets}
      players={profiles.filter((player) => verifiedTags.has(player.tag))}
      onBack={onBack}
    />
  );
}
