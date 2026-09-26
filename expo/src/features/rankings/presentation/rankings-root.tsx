import { useEffect, useMemo, useRef, useState, useSyncExternalStore } from 'react';
import { Pressable, ScrollView, View, useWindowDimensions } from 'react-native';
import { ArrowLeft } from 'lucide-react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

import { useAppRuntime } from '../../../core/app/runtime-context';
import {
  gameDataState,
  subscribeToGameDataRevision,
} from '../../../core/game-data/game-data-state';
import type { Clan } from '../../clan/models';
import type { Player } from '../../player/models';
import { CKText, Snackbar, useCKTheme } from '../../../ui';
import { DestinationStack } from '../../../ui/destination-stack';
import { DestinationGrid } from '../../../ui/destination-grid';
import {
  RankingAudience,
  rankingBoardArtwork,
  rankingBoards,
  type RankingBoardValue,
  type RankingEntry,
  type RankingLocation,
} from '../models';
import { RankingsScreen, boardLabel, rankingBackground } from './rankings-screen';
import { useLinkParameters, linkChoice } from '../../../core/deep-links/link-parameters';
import { useI18n, materialBackLabel } from '../../../i18n';
import {
  emptyLocationPreferences,
  readLocationPreferences,
  selectRecentLocation,
  toggleStarredLocation,
  writeLocationPreferences,
  type LocationPreferences,
} from './location-preferences';

export interface RankingsRootProps {
  readonly onBack: () => void;
  readonly openPlayer: (player: Player) => void;
  readonly openClan: (clan: Clan) => void;
}

export function RankingsRoot({ onBack, openPlayer, openClan }: RankingsRootProps) {
  'use no memo';
  const runtime = useAppRuntime();
  useSyncExternalStore(
    subscribeToGameDataRevision,
    () => gameDataState.revision,
    () => gameDataState.revision,
  );
  const link = useLinkParameters();
  const {
    type: linkType,
    board: linkBoard,
    period: linkPeriod,
    day: linkDay,
    season: linkSeason,
    location: linkLocation,
  } = link;
  const provider = useMemo(() => {
    const value = runtime.createRankingsProvider();
    value.audience = linkChoice(linkType, ['players', 'clans'], 'players');
    const board = rankingBoards.find(
      (item) => item.name === linkBoard && item.audience === value.audience,
    );
    if (board) {
      if (value.audience === 'players') value.playerBoard = board;
      else value.clanBoard = board;
    }
    if (value.board.supportsHistory) {
      value.period = linkChoice(
        linkPeriod,
        ['current', 'history'],
        linkDay || linkSeason ? 'history' : 'current',
      );
      if (linkDay || linkSeason)
        value.historyDate = new Date(`${linkDay ?? `${linkSeason}-01`}T00:00:00`);
    }
    return value;
  }, [runtime, linkType, linkBoard, linkPeriod, linkDay, linkSeason]);
  const deepLinkedBoard = rankingBoards.find(
    (item) => item.name === linkBoard && item.audience === provider.audience,
  );
  const linkKey = `${linkType ?? ''}:${linkBoard ?? ''}`;
  const [localSelection, setLocalSelection] = useState<{
    linkKey: string;
    board: RankingBoardValue | null;
  }>({ linkKey, board: deepLinkedBoard ?? null });
  const activeBoard =
    localSelection.linkKey === linkKey ? localSelection.board : (deepLinkedBoard ?? null);
  const activeBoardRef = useRef<RankingBoardValue | null>(activeBoard);
  const locationsReadyRef = useRef(false);
  const [locationPreferences, setLocationPreferences] = useState(emptyLocationPreferences);
  const locationPreferencesRef = useRef<LocationPreferences>(emptyLocationPreferences);
  const preferenceRevisionRef = useRef(0);
  const preferenceWriteRef = useRef<Promise<void>>(Promise.resolve());
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const { width } = useWindowDimensions();
  const [revision, setRevision] = useState(0);
  const [message, setMessage] = useState<string>();
  useEffect(() => {
    activeBoardRef.current = deepLinkedBoard ?? null;
    locationsReadyRef.current = false;
    const unsubscribe = provider.subscribe(() => setRevision((value) => value + 1));
    let active = true;
    void provider.initialize(false).then(async () => {
      if (!active) return;
      const preferenceRevision = preferenceRevisionRef.current;
      const preferences = await readLocationPreferences(runtime.preferences, provider.locations);
      if (!active) return;
      const effectivePreferences =
        preferenceRevisionRef.current === preferenceRevision
          ? preferences
          : locationPreferencesRef.current;
      locationPreferencesRef.current = effectivePreferences;
      setLocationPreferences(effectivePreferences);
      const location = linkLocation
        ? provider.locations.find(
            (item) =>
              String(item.id) === linkLocation || item.countryCode === linkLocation?.toUpperCase(),
          )
        : provider.locations.find((item) => item.apiPath === effectivePreferences.starred[0]);
      if (location && (provider.board.supportsWorldwide || !location.isWorldwide))
        provider.location = location;
      locationsReadyRef.current = true;
      if (activeBoardRef.current) await provider.reload();
    });
    return () => {
      unsubscribe();
      active = false;
      provider.dispose();
    };
  }, [provider, deepLinkedBoard, linkLocation, runtime.preferences]);

  const updateLocations = (update: (current: LocationPreferences) => LocationPreferences) => {
    const next = update(locationPreferencesRef.current);
    locationPreferencesRef.current = next;
    preferenceRevisionRef.current += 1;
    setLocationPreferences(next);
    preferenceWriteRef.current = preferenceWriteRef.current
      .then(() => writeLocationPreferences(runtime.preferences, next))
      .catch(() => undefined);
  };
  const selectLocation = (location: RankingLocation) => {
    updateLocations((current) => selectRecentLocation(current, location));
    void provider.selectLocation(location);
  };
  const openBoard = (board: RankingBoardValue) => {
    activeBoardRef.current = board;
    setLocalSelection({ linkKey, board });
    void provider.openBoard(board, locationsReadyRef.current);
  };
  const closeFocused = () => {
    activeBoardRef.current = null;
    setLocalSelection({ linkKey, board: null });
  };

  const openEntry = async (entry: RankingEntry) => {
    if (entry.audience === 'players')
      openPlayer(await runtime.players.getPlayerAndClanData(entry.tag));
    else openClan(await runtime.clans.getClanAndWarData(entry.tag));
  };

  const detail = (
    <RankingsScreen
      provider={provider}
      revision={revision}
      onBack={closeFocused}
      onOpenEntry={openEntry}
      onMessage={setMessage}
      locationPreferences={locationPreferences}
      onSelectLocation={selectLocation}
      onToggleStar={(location) =>
        updateLocations((current) => toggleStarredLocation(current, location))
      }
    />
  );
  const grid = (
    <SafeAreaView edges={['left', 'right']} style={{ flex: 1, backgroundColor: theme.background }}>
      <ScrollView
        contentContainerStyle={{
          paddingTop: insets.top + 8,
          paddingBottom: insets.bottom + 24,
          paddingHorizontal: Math.max(16, (width - 1120) / 2),
          gap: 12,
        }}
      >
        <View style={{ minHeight: 48, flexDirection: 'row', alignItems: 'center', gap: 8 }}>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={materialBackLabel(locale)}
            onPress={onBack}
            style={{ width: 44, height: 44, alignItems: 'center', justifyContent: 'center' }}
          >
            <ArrowLeft color={theme.onSurface} />
          </Pressable>
          <CKText role="screenTitle">{t('sideRankingsTitle')}</CKText>
        </View>
        <DestinationGrid
          initialWidth={width - 2 * Math.max(16, (width - 1120) / 2)}
          groups={[
            {
              key: 'players',
              title: t('searchTabPlayers'),
              items: rankingBoards
                .filter((board) => board.audience === RankingAudience.players)
                .map((board) => ({
                  key: board.name,
                  label: boardLabel(board, t),
                  imageUrl: rankingBoardArtwork(board),
                  backgroundUrl: rankingBackground(board),
                  accentColor: rankingBoardAccentColor(board),
                  onPress: () => openBoard(board),
                })),
            },
            {
              key: 'clans',
              title: t('searchTabClans'),
              items: rankingBoards
                .filter((board) => board.audience === RankingAudience.clans)
                .map((board) => ({
                  key: board.name,
                  label: boardLabel(board, t),
                  imageUrl: rankingBoardArtwork(board),
                  backgroundUrl: rankingBackground(board),
                  accentColor: rankingBoardAccentColor(board),
                  onPress: () => openBoard(board),
                })),
            },
          ]}
        />
      </ScrollView>
    </SafeAreaView>
  );

  return (
    <View style={{ flex: 1 }}>
      <DestinationStack
        focused={Boolean(activeBoard)}
        onCloseDetail={closeFocused}
        grid={grid}
        detail={detail}
      />
      <Snackbar message={message} onDismiss={() => setMessage(undefined)} />
    </View>
  );
}

export function rankingBoardAccentColor(board: RankingBoardValue): string {
  switch (board.name) {
    case 'playerHome':
      return '#C59648';
    case 'playerBuilder':
      return '#A98258';
    case 'playerTownHall':
      return '#B77555';
    case 'playerRanked':
      return '#AD6464';
    case 'clanHome':
      return '#7B93B0';
    case 'clanBuilder':
      return '#927FAB';
    case 'clanCapital':
      return '#C09755';
    case 'clanDonations':
      return '#83A47A';
    case 'clanWarWins':
      return '#A97661';
    case 'clanWinStreak':
      return '#C4844C';
  }
}
