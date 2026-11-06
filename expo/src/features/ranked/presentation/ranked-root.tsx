import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { View } from 'react-native';

import { useAppRuntime } from '../../../core/app/runtime-context';
import { canonicalTag } from '../../../core/domain/tags';
import { useI18n } from '../../../i18n';
import { ClashHandoffDialog, Snackbar } from '../../../ui';
import { useClashGameHandoff } from '../../../ui/use-clash-game-handoff';
import type { Player, RankedLeagueData, RankedLeagueBattlelog } from '../../player/models';
import { RankedScreen } from './ranked-screen';

export interface RankedRootProps {
  readonly player: Player;
  readonly onBack: () => void;
  readonly openPlayer: (player: Player) => void;
  readonly openPlayerTag?: (tag: string) => void;
  readonly openInGame: (tag: string) => void;
  readonly allowAccountSwitch?: boolean;
}

export function RankedRoot({
  player: initialPlayer,
  onBack,
  openPlayer,
  openPlayerTag: openTag,
  openInGame,
  allowAccountSwitch = false,
}: RankedRootProps) {
  const runtime = useAppRuntime();
  const { t } = useI18n();
  const [player, setPlayer] = useState(initialPlayer);
  const [data, setData] = useState<RankedLeagueData | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string>();
  const handoff = useClashGameHandoff(openInGame);
  const [revision, setRevision] = useState(0);
  const generation = useRef(0);
  const [seasonLogs, setSeasonLogs] = useState<ReadonlyMap<number, RankedLeagueBattlelog>>(
    new Map(),
  );
  const [loadingSeason, setLoadingSeason] = useState<number>();
  const [settledSeasons, setSettledSeasons] = useState<ReadonlySet<number>>(() => new Set());
  const [seasonError, setSeasonError] = useState<string>();
  const seasonRequests = useRef(new Set<string>());
  const seasonGeneration = useRef(0);
  const activeSeason = useRef<number | undefined>(undefined);
  useEffect(
    () => () => {
      seasonGeneration.current += 1;
    },
    [],
  );

  const loadSeason = useCallback(
    async (season: number) => {
      activeSeason.current = season;
      setSeasonError(undefined);
      if (data?.battlelogForSeason(season) || seasonLogs.has(season)) {
        setLoadingSeason(undefined);
        return;
      }
      const key = `${player.tag}:${season}`;
      setLoadingSeason(season);
      if (seasonRequests.current.has(key)) return;
      seasonRequests.current.add(key);
      const request = seasonGeneration.current;
      try {
        // Let the date and new-week skeleton commit before starting work. This
        // is a frame boundary, not an artificial minimum loading duration.
        await new Promise<void>((resolve) => requestAnimationFrame(() => setTimeout(resolve, 0)));
        if (request !== seasonGeneration.current) return;
        const log = await runtime.players.loadRankedSeasonBattlelog(
          player.tag,
          season,
          (battles) => {
            if (request !== seasonGeneration.current) return;
            setSeasonLogs((old) => new Map(old).set(season, battles));
            setLoadingSeason((current) => (current === season ? undefined : current));
          },
        );
        if (request !== seasonGeneration.current) return;
        if (log) setSeasonLogs((old) => new Map(old).set(season, log));
      } catch (caught) {
        if (request === seasonGeneration.current && activeSeason.current === season)
          setSeasonError(
            t('generalRefreshFailed', {
              error: caught instanceof Error ? caught.message : String(caught),
            }),
          );
      } finally {
        seasonRequests.current.delete(key);
        if (request === seasonGeneration.current) {
          setSettledSeasons((current) => new Set(current).add(season));
          setLoadingSeason((current) => (current === season ? undefined : current));
        }
      }
    },
    [data, player.tag, runtime, seasonLogs, t],
  );

  useEffect(() => {
    const changed = () => setRevision((value) => value + 1);
    return combine([
      runtime.accounts.subscribe(changed),
      runtime.players.subscribe(changed),
      runtime.bookmarks.subscribe(changed),
      runtime.playerCardPreferences.subscribe(changed),
    ]);
  }, [runtime]);

  const load = useCallback(
    async (forceRefresh: boolean, silent = false) => {
      const request = ++generation.current;
      if (!silent) {
        if (forceRefresh) setRefreshing(true);
        else setLoading(true);
        setError(null);
      }
      try {
        const next = await runtime.players.loadRankedLeagueData(player.tag, forceRefresh, true);
        if (
          request !== generation.current ||
          canonicalTag(next.playerTag) !== canonicalTag(player.tag)
        )
          return;
        setData(next);
        // Detailed opponent TH/army metadata enriches the visible page later;
        // it must not hold the page or week selector behind another request.
        void runtime.players.loadRankedBattleDetails(player.tag).then((details) => {
          if (request !== generation.current || !details.length) return;
          setData((current) => current?.withBattleDetails(details) ?? current);
        });
      } catch (caught) {
        if (request !== generation.current) return;
        if (!silent) {
          const detail = caught instanceof Error ? caught.message : String(caught);
          setError(t('generalRefreshFailed', { error: detail }));
        }
      } finally {
        if (request === generation.current && !silent) {
          setLoading(false);
          setRefreshing(false);
        }
      }
      return request === generation.current;
    },
    [player.tag, runtime, t],
  );

  useEffect(() => {
    void (async () => {
      const stillCurrent = await load(false);
      if (stillCurrent) await load(true, true);
    })();
    return () => {
      generation.current += 1;
    };
  }, [load]);

  const accounts = useMemo(() => {
    const verified = new Set(
      runtime.accounts.verifiedAccounts.map((item) => canonicalTag(item.playerTag)),
    );
    return allowAccountSwitch
      ? runtime.players.profiles.filter(
          (profile) =>
            verified.has(canonicalTag(profile.tag)) &&
            runtime.playerCardPreferences.isRankedShownOnHome(profile.tag),
        )
      : [];
    // Runtime revisions invalidate all service-owned arrays and maps.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [allowAccountSwitch, revision, runtime]);
  const linked = runtime.accounts.accounts.some(
    (item) => canonicalTag(item.playerTag) === canonicalTag(player.tag),
  );
  const bookmarked = runtime.bookmarks.isPlayerBookmarked(player.tag);
  const switchPlayer = (next: Player) => {
    seasonGeneration.current += 1;
    generation.current += 1;
    setPlayer(next);
    setData(null);
    setLoading(true);
    setSeasonLogs(new Map());
    setSettledSeasons(new Set());
    setLoadingSeason(undefined);
    setSeasonError(undefined);
  };
  const openPlayerTag = async (tag: string) => {
    if (openTag) return openTag(tag);
    try {
      openPlayer(await runtime.players.getPlayerAndClanData(tag));
    } catch (caught) {
      setMessage(
        t('generalRefreshFailed', {
          error: caught instanceof Error ? caught.message : String(caught),
        }),
      );
    }
  };
  const toggleBookmark = async () => {
    try {
      await runtime.bookmarks.togglePlayer(player);
    } catch (caught) {
      setMessage(
        t('generalRefreshFailed', {
          error: caught instanceof Error ? caught.message : String(caught),
        }),
      );
    }
  };

  return (
    <View style={{ flex: 1 }}>
      <RankedScreen
        player={player}
        data={data}
        loading={loading}
        refreshing={refreshing}
        error={error}
        seasonLogs={seasonLogs}
        loadingSeason={loadingSeason}
        settledSeasons={settledSeasons}
        seasonError={seasonError}
        onLoadSeason={loadSeason}
        accounts={accounts}
        bookmarked={bookmarked}
        linked={linked}
        onBack={onBack}
        onRefresh={async () => {
          await load(true);
        }}
        onSwitchPlayer={switchPlayer}
        onToggleBookmark={toggleBookmark}
        onOpenInGame={() => handoff.request(player.tag)}
        onOpenPlayerTag={openPlayerTag}
      />
      <Snackbar message={message} onDismiss={() => setMessage(undefined)} />
      <ClashHandoffDialog
        visible={handoff.visible}
        onCancel={handoff.cancel}
        onConfirm={handoff.confirm}
        allowRemember
      />
    </View>
  );
}

function combine(unsubscribers: readonly (() => void)[]) {
  return () => unsubscribers.forEach((unsubscribe) => unsubscribe());
}
