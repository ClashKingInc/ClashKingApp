import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { View } from 'react-native';

import { useAppRuntime } from '../../../core/app/runtime-context';
import { canonicalTag } from '../../../core/domain/tags';
import { useI18n } from '../../../i18n';
import { Snackbar } from '../../../ui';
import type { Player, RankedLeagueData } from '../../player/models';
import { RankedScreen } from './ranked-screen';

export interface RankedRootProps {
  readonly player: Player;
  readonly onBack: () => void;
  readonly openPlayer: (player: Player) => void;
  readonly openInGame: (tag: string) => void;
  readonly allowAccountSwitch?: boolean;
}

export function RankedRoot({
  player: initialPlayer,
  onBack,
  openPlayer,
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
  const [revision, setRevision] = useState(0);
  const generation = useRef(0);

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
    generation.current += 1;
    setPlayer(next);
    setData(null);
    setLoading(true);
  };
  const openPlayerTag = async (tag: string) => {
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
        accounts={accounts}
        bookmarked={bookmarked}
        linked={linked}
        onBack={onBack}
        onRefresh={async () => {
          await load(true);
        }}
        onSwitchPlayer={switchPlayer}
        onToggleBookmark={toggleBookmark}
        onOpenInGame={() => openInGame(player.tag)}
        onOpenPlayerTag={openPlayerTag}
      />
      <Snackbar message={message} onDismiss={() => setMessage(undefined)} />
    </View>
  );
}

function combine(unsubscribers: readonly (() => void)[]) {
  return () => unsubscribers.forEach((unsubscribe) => unsubscribe());
}
