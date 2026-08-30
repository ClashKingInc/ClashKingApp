import { useEffect, useMemo, useState } from 'react';
import { View } from 'react-native';

import { useAppRuntime } from '../../../core/app/runtime-context';
import type { Clan } from '../../clan/models';
import type { Player } from '../../player/models';
import { Snackbar } from '../../../ui';
import type { RankingEntry } from '../models';
import { RankingsScreen } from './rankings-screen';

export interface RankingsRootProps {
  readonly onBack: () => void;
  readonly openPlayer: (player: Player) => void;
  readonly openClan: (clan: Clan) => void;
}

export function RankingsRoot({ onBack, openPlayer, openClan }: RankingsRootProps) {
  const runtime = useAppRuntime();
  const provider = useMemo(() => runtime.createRankingsProvider(), [runtime]);
  const [revision, setRevision] = useState(0);
  const [message, setMessage] = useState<string>();
  useEffect(() => {
    const unsubscribe = provider.subscribe(() => setRevision((value) => value + 1));
    void provider.initialize();
    return () => {
      unsubscribe();
      provider.dispose();
    };
  }, [provider]);

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
