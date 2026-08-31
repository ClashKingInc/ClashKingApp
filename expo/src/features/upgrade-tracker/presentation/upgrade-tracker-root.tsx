import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import * as Linking from 'expo-linking';

import { useAppRuntime } from '../../../core/app/runtime-context';
import { useI18n } from '../../../i18n';
import { Snackbar } from '../../../ui';
import { UpgradePlanPreferences, type UpgradeTrackerSnapshot } from '../models';
import { UpgradeTrackerFormatError, UpgradeTrackerRepository } from '../data';
import type { UpgradeTrackerRootProps } from './upgrade-tracker-contracts';
import { UpgradeTrackerScreen, type UpgradeTrackerAccountOption } from './upgrade-tracker-screen';
import { buildUpgradeTrackerAccountOptions } from './upgrade-tracker-logic';

export function UpgradeTrackerRoot({
  initialTag,
  onBack,
  repository: injectedRepository,
  widgetSync: injectedWidgetSync,
  accounts: injectedAccounts,
  players: injectedPlayers,
  accountId,
}: UpgradeTrackerRootProps) {
  const runtime = useAppRuntime();
  const { t } = useI18n();
  const repository = injectedRepository ?? runtime.upgrades;
  const widgetSync = injectedWidgetSync ?? runtime.upgradeWidgets;
  const rawLinked = injectedAccounts ?? runtime.accounts.verifiedAccounts;
  const players = injectedPlayers ?? runtime.players.profiles;
  const linkedKey = rawLinked
    .map((account) => `${account.playerTag}:${account.isVerified}`)
    .join('|');
  // Service getters return fresh arrays, so retain identity until their account content changes.
  // eslint-disable-next-line react-hooks/exhaustive-deps
  const linked = useMemo(() => rawLinked, [linkedKey]);
  const verifiedTags = useMemo(
    () => linked.filter((account) => account.isVerified).map((account) => account.playerTag),
    [linked],
  );
  const [selectedTag, setSelectedTag] = useState<string | null>(null);
  const [snapshot, setSnapshot] = useState<UpgradeTrackerSnapshot | null>(null);
  const [saved, setSaved] = useState<readonly UpgradeTrackerAccountOption[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string>();
  const [goldPassPercent, setGoldPassPercent] = useState(0);
  const [preferences, setPreferences] = useState(new UpgradePlanPreferences());
  const generation = useRef(0);

  useEffect(() => {
    repository.configureRemote({
      accountId: accountId ?? runtime.auth.state.currentUser?.userId ?? null,
      verifiedPlayerTags: verifiedTags,
    });
  }, [accountId, repository, runtime.auth.state.currentUser?.userId, verifiedTags]);

  const refreshMetadata = useCallback(async () => {
    const records = await repository.savedSnapshotAccounts();
    setSaved(
      records.map((record) => ({
        tag: UpgradeTrackerRepository.normalizeTag(record.tag),
        name: record.name,
        townHallLevel: Number(record.townHallLevel) || 0,
        builderHallLevel: Number(record.builderHallLevel) || 0,
        ...(record.capturedAt ? { capturedAt: new Date(record.capturedAt) } : null),
      })),
    );
  }, [repository]);

  const resolvePreferences = useCallback(
    async (next: UpgradeTrackerSnapshot) => {
      const raw = await repository.loadPlanPreferences(next.tag);
      const detected = Math.max(
        next.boosts.builderCostReductionPercent,
        next.boosts.builderTimeReductionPercent,
        next.boosts.labCostReductionPercent,
        next.boosts.labTimeReductionPercent,
      );
      const stored = Number(raw?.gold_pass_percent);
      return {
        goldPassPercent: Number.isFinite(stored) ? Math.max(0, Math.min(100, stored)) : detected,
        preferences: UpgradePlanPreferences.fromJson(
          isRecord(raw?.heuristics) ? raw.heuristics : null,
        ),
      };
    },
    [repository],
  );

  const scheduleWidgetSync = useCallback(
    (normalized: string) => {
      void repository
        .loadSavedSnapshots(verifiedTags)
        .then((snapshots) =>
          widgetSync.sync(snapshots, {
            linkedAccounts: linked.map((account) => ({
              tag: account.playerTag,
              name:
                playerForTag(players, account.playerTag)?.name ??
                linkedAccountName(account) ??
                account.playerTag,
              townHallLevel:
                playerForTag(players, account.playerTag)?.townHallLevel ??
                linkedAccountHallLevel(account, 'townHallLevel'),
              builderHallLevel:
                playerForTag(players, account.playerTag)?.builderHallLevel ??
                linkedAccountHallLevel(account, 'builderHallLevel'),
            })),
            selectedTag: runtime.accounts.selectedTag ?? normalized,
          }),
        )
        .catch(() => {
          // Flutter schedules widget synchronization independently from tracker
          // loading. Native widget failures must not replace valid screen data.
        });
    },
    [linked, players, repository, runtime.accounts.selectedTag, verifiedTags, widgetSync],
  );

  const load = useCallback(
    async (tag: string, force = false) => {
      const normalized = UpgradeTrackerRepository.normalizeTag(tag);
      const current = ++generation.current;
      setSelectedTag(normalized);
      const cached = repository.peekCached(normalized);
      setSnapshot(cached);
      setLoading(cached === null);
      setError(null);
      if (cached) {
        setGoldPassPercent(
          Math.max(
            cached.boosts.builderCostReductionPercent,
            cached.boosts.builderTimeReductionPercent,
            cached.boosts.labCostReductionPercent,
            cached.boosts.labTimeReductionPercent,
          ),
        );
        setPreferences(new UpgradePlanPreferences());
      }
      try {
        if (cached) {
          const cachedPreferences = await resolvePreferences(cached);
          if (current !== generation.current) return;
          setGoldPassPercent(cachedPreferences.goldPassPercent);
          setPreferences(cachedPreferences.preferences);
        }
        const next = await repository.load(normalized, force || cached !== null);
        if (current !== generation.current) return;
        const nextPreferences = next ? await resolvePreferences(next) : null;
        if (current !== generation.current) return;
        setSnapshot(next);
        if (nextPreferences) {
          setGoldPassPercent(nextPreferences.goldPassPercent);
          setPreferences(nextPreferences.preferences);
        } else {
          setGoldPassPercent(0);
          setPreferences(new UpgradePlanPreferences());
        }
        await refreshMetadata().catch(() => undefined);
        if (current !== generation.current) return;
        setLoading(false);
        scheduleWidgetSync(normalized);
      } catch (cause) {
        if (current !== generation.current) return;
        setLoading(false);
        if (!cached) {
          setSnapshot(null);
          setError(cause instanceof Error ? cause.message : String(cause));
        }
      }
    },
    [refreshMetadata, repository, resolvePreferences, scheduleWidgetSync],
  );

  useEffect(() => {
    // Initialization intentionally enters the repository state machine once per account set.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    void refreshMetadata();
    const requested = initialTag ? UpgradeTrackerRepository.normalizeTag(initialTag) : null;
    const initial =
      verifiedTags.find((tag) => UpgradeTrackerRepository.normalizeTag(tag) === requested) ??
      verifiedTags[0] ??
      null;
    if (initial) void load(initial);
    else setLoading(false);
  }, [initialTag, load, refreshMetadata, verifiedTags]);

  const accounts = useMemo(() => {
    return buildUpgradeTrackerAccountOptions(saved, verifiedTags, [
      ...linked.map((account) => ({
        tag: account.playerTag,
        name: linkedAccountName(account) ?? account.playerTag,
        townHallLevel: linkedAccountHallLevel(account, 'townHallLevel'),
        builderHallLevel: linkedAccountHallLevel(account, 'builderHallLevel'),
      })),
      ...players.map((player) => ({
        tag: player.tag,
        name: player.name,
        townHallLevel: player.townHallLevel,
        builderHallLevel: player.builderHallLevel,
      })),
    ]) as readonly UpgradeTrackerAccountOption[];
  }, [linked, players, saved, verifiedTags]);

  const savePreferences = useCallback(
    (next: UpgradePlanPreferences, goldPass = goldPassPercent) => {
      setPreferences(next);
      if (selectedTag)
        void repository
          .savePlanPreferences(selectedTag, goldPass, 'balanced', next)
          .catch((cause) => setMessage(String(cause)));
    },
    [goldPassPercent, repository, selectedTag],
  );

  return (
    <>
      <UpgradeTrackerScreen
        snapshot={snapshot}
        accounts={accounts}
        selectedTag={selectedTag}
        loading={loading}
        error={error}
        goldPassPercent={goldPassPercent}
        preferences={preferences}
        onBack={onBack}
        onSelectAccount={(tag) => void load(tag)}
        onRefresh={() => (selectedTag ? load(selectedTag, true) : Promise.resolve())}
        onImport={async (json) => {
          try {
            const next = await repository.importSnapshotBytes(new TextEncoder().encode(json), {
              allowedTags: new Set(verifiedTags),
              linkedNamesByTag: Object.fromEntries(
                accounts.map((account) => [account.tag, account.name]),
              ),
            });
            await load(next.tag, true);
            setMessage(t('upgradeTrackerImportSuccess', { player: next.name }));
          } catch (cause) {
            if (
              cause instanceof UpgradeTrackerFormatError &&
              cause.reason === 'invalid-account-json'
            ) {
              const message = t('upgradeTrackerSnapshotUnreadable');
              setMessage(message);
              throw new UpgradeTrackerFormatError(message);
            }
            setMessage(
              t('upgradeTrackerImportFailed', {
                error: cause instanceof Error ? cause.message : String(cause),
              }),
            );
            throw cause;
          }
        }}
        onGoldPassChange={(value) => {
          setGoldPassPercent(value);
          savePreferences(preferences, value);
        }}
        onPreferencesChange={savePreferences}
        onOpenGameSettings={() =>
          void Linking.openURL('https://link.clashofclans.com/?action=OpenMoreSettings').catch(() =>
            setMessage(t('accountsCouldNotOpenClash')),
          )
        }
      />
      <Snackbar message={message} onDismiss={() => setMessage(undefined)} />
    </>
  );
}

function playerForTag(players: readonly { tag: string }[], tag: string) {
  const normalized = UpgradeTrackerRepository.normalizeTag(tag);
  return players.find(
    (player) => UpgradeTrackerRepository.normalizeTag(player.tag) === normalized,
  ) as
    | ((typeof players)[number] & {
        name?: string;
        townHallLevel?: number;
        builderHallLevel?: number;
      })
    | undefined;
}
function linkedAccountName(account: { raw: Readonly<Record<string, unknown>> }) {
  const value = account.raw.name;
  return typeof value === 'string' && value.trim() ? value.trim() : null;
}
function linkedAccountHallLevel(
  account: { raw: Readonly<Record<string, unknown>> },
  kind: 'townHallLevel' | 'builderHallLevel',
) {
  const snake = kind === 'townHallLevel' ? 'town_hall_level' : 'builder_hall_level';
  for (const value of [account.raw[kind], account.raw[snake]]) {
    const parsed = typeof value === 'number' ? value : Number(value);
    if (Number.isFinite(parsed) && parsed > 0) return Math.trunc(parsed);
  }
  return 0;
}
function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}
