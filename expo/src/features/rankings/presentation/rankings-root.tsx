import { useEffect, useMemo, useRef, useState, useSyncExternalStore } from 'react';
import { BackHandler, View } from 'react-native';

import { useAppRuntime } from '../../../core/app/runtime-context';
import {
  gameDataState,
  subscribeToGameDataRevision,
} from '../../../core/game-data/game-data-state';
import type { Clan } from '../../clan/models';
import type { Player } from '../../player/models';
import { Snackbar, ckColors } from '../../../ui';
import { StatsRoot } from '../../stats';
import { statsSections, type StatsSectionValue } from '../../stats/models';
import { sectionImage, sectionLabel, sectionBackdrop } from '../../stats/presentation/stats-screen';
import { DestinationStack } from '../../../ui/destination-stack';
import { DestinationHub } from '../../../ui/destination-hub';
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
import { useI18n } from '../../../i18n';
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
  readonly openPlayerTag?: (tag: string) => void;
  readonly openClanTag?: (tag: string) => void;
}

export function RankingsRoot({
  onBack,
  openPlayer,
  openClan,
  openPlayerTag,
  openClanTag,
}: RankingsRootProps) {
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
  const { t } = useI18n();
  const [revision, setRevision] = useState(0);
  const [selectionRequest, setSelectionRequest] = useState(0);
  const [message, setMessage] = useState<string>();
  const [activeStats, setActiveStats] = useState<StatsSectionValue | null>(() =>
    statsSections.includes(link.section as StatsSectionValue)
      ? (link.section as StatsSectionValue)
      : null,
  );
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
    setSelectionRequest((request) => request + 1);
    activeBoardRef.current = board;
    setLocalSelection({ linkKey, board });
    void provider.openBoard(board, locationsReadyRef.current);
  };
  const closeFocused = () => {
    if (activeStats) {
      setActiveStats(null);
      return;
    }
    activeBoardRef.current = null;
    setLocalSelection({ linkKey, board: null });
  };
  useEffect(() => {
    if (!activeBoard && !activeStats) return;
    const subscription = BackHandler.addEventListener('hardwareBackPress', () => {
      if (activeStats) {
        setActiveStats(null);
        return true;
      }
      activeBoardRef.current = null;
      setLocalSelection({ linkKey, board: null });
      return true;
    });
    return () => subscription.remove();
  }, [activeBoard, linkKey, activeStats]);

  const openEntry = async (entry: RankingEntry) => {
    if (entry.audience === 'players' && openPlayerTag) return openPlayerTag(entry.tag);
    if (entry.audience !== 'players' && openClanTag) return openClanTag(entry.tag);
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
    <DestinationHub
      title={t('homeRankingsAndStats')}
      onBack={onBack}
      groups={[
        {
          key: 'statistics',
          title: t('sideStatsTitle'),
          items: statsSections.map((section) => ({
            key: 'stats-' + section,
            label: sectionLabel(section, t),
            imageUrl: sectionImage(section),
            backgroundUrl: sectionBackdrop(section),
            accentColor: {
              war: ckColors.lossRed,
              ranked: ckColors.capitalPurple,
              cwl: ckColors.warGold,
              armies: ckColors.legendBlue,
              items: ckColors.upgradePets,
              players: ckColors.builderBlue,
              clans: ckColors.donationGreen,
            }[section],
            onPress: () => {
              setSelectionRequest((request) => request + 1);
              setActiveStats(section);
            },
          })),
        },
        {
          key: 'players',
          title: t('rankingsPlayerSection'),
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
          title: t('rankingsClanSection'),
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
  );

  return (
    <View style={{ flex: 1 }}>
      {/* Stats and leaderboards share the retained launcher stack. Replacing
          the stack with StatsRoot lets the native swipe pop the whole utility. */}
      <DestinationStack
        selectionKey={selectionRequest}
        focused={Boolean(activeBoard) || Boolean(activeStats)}
        onCloseDetail={closeFocused}
        grid={grid}
        detail={
          activeStats ? <StatsRoot initialSection={activeStats} onBack={closeFocused} /> : detail
        }
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
    case 'playerWarTripleStreak':
      return '#C4844C';
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
