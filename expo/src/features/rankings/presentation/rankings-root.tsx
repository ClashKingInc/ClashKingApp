import { useEffect, useMemo, useState } from 'react';
import { View } from 'react-native';

import { useAppRuntime } from '../../../core/app/runtime-context';
import type { Clan } from '../../clan/models';
import type { Player } from '../../player/models';
import { Snackbar } from '../../../ui';
import type { RankingEntry } from '../models';
import { RankingsScreen } from './rankings-screen';
import { useLinkParameters, linkChoice } from '../../../core/deep-links/link-parameters';
import { rankingBoards } from '../models';

export interface RankingsRootProps {
  readonly onBack: () => void;
  readonly openPlayer: (player: Player) => void;
  readonly openClan: (clan: Clan) => void;
}

export function RankingsRoot({ onBack, openPlayer, openClan }: RankingsRootProps) {
  const runtime = useAppRuntime();
  const link = useLinkParameters();
  const provider = useMemo(() => {
    const value = runtime.createRankingsProvider();
    value.audience = linkChoice(link.type, ['players', 'clans'], 'players');
    const board = rankingBoards.find(
      (item) => item.name === link.board && item.audience === value.audience,
    );
    if (board) {
      if (value.audience === 'players') value.playerBoard = board;
      else value.clanBoard = board;
    }
    if (value.board.supportsHistory) {
      value.period = linkChoice(
        link.period,
        ['current', 'history'],
        link.day || link.season ? 'history' : 'current',
      );
      if (link.day || link.season)
        value.historyDate = new Date(`${link.day ?? `${link.season}-01`}T00:00:00`);
    }
    return value;
  }, [runtime, link]);
  const [revision, setRevision] = useState(0);
  const [message, setMessage] = useState<string>();
  useEffect(() => {
    const unsubscribe = provider.subscribe(() => setRevision((value) => value + 1));
    let active = true;
    void provider.initialize().then(async () => {
      if (!active || !link.location) return;
      const location = provider.locations.find(
        (item) =>
          String(item.id) === link.location || item.countryCode === link.location?.toUpperCase(),
      );
      if (location) await provider.selectLocation(location);
    });
    return () => {
      unsubscribe();
      active = false;
      provider.dispose();
    };
  }, [provider, link.location]);

  const openEntry = async (entry: RankingEntry) => {
    if (entry.audience === 'players')
      openPlayer(await runtime.players.getPlayerAndClanData(entry.tag));
    else openClan(await runtime.clans.getClanAndWarData(entry.tag));
  };

  return (
    <View style={{ flex: 1 }}>
      <RankingsScreen
        provider={provider}
        revision={revision}
        onBack={onBack}
        onOpenEntry={openEntry}
        onMessage={setMessage}
      />
      <Snackbar message={message} onDismiss={() => setMessage(undefined)} />
    </View>
  );
}
