import { fireEvent, render, waitFor } from '@testing-library/react-native';
import { Button, StyleSheet, View } from 'react-native';
import { useState } from 'react';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import { WarCwl, WarInfo } from '../../war/models';
import type { Player } from '../models';
import {
  JoinLeaveClan,
  JoinLeaveEvent,
  PlayerAchievement,
  PlayerBattlelogData,
  PlayerClanOverview,
  PlayerJoinLeavePage,
  PlayerJoinLeaveTotal,
} from '../models';
import type {
  PlayerDetailPresentationActions,
  PlayerDetailPresentationModel,
} from './player-detail-contracts';
import { PlayerDetailRoot } from './player-detail-root';
import { playerHeaderClanIdentity } from './player-detail-components';
import {
  PlayerDetailScreen,
  isPlayerDetailTabRefreshable,
  refreshPlayerDetailTab,
} from './player-detail-screen';

const player = {
  name: 'Alpha',
  tag: '#ALPHA',
  townHallLevel: 17,
  townHallPic: 'th.png',
  builderHallLevel: 10,
  trophies: 5600,
  league: 'Legend League',
  leagueUrl: 'league.png',
  builderBaseTrophies: 5000,
  builderBaseLeague: 'Diamond League',
  builderBaseLeagueUrl: 'builder-league.png',
  warPreference: 'in',
  warPreferenceImage: 'war-preference.png',
  warStars: 1200,
  donations: 200,
  donationsReceived: 100,
  clanCapitalContributions: 4000,
  expLevel: 250,
  bestTrophies: 5900,
  clanOverview: new PlayerClanOverview('#CLAN', 'Clash Kings', 20, {
    small: '',
    medium: 'badge.png',
    large: '',
  }),
  heroes: [],
  bbHeroes: [],
  equipments: [],
  troops: [],
  superTroops: [],
  bbTroops: [],
  spells: [],
  siegeMachines: [],
  pets: [],
  achievements: [],
  warStats: null,
} as unknown as Player;

const actions = (): PlayerDetailPresentationActions => ({
  goBack: jest.fn(),
  loadTab: jest.fn(async () => undefined),
  loadActivity: jest.fn(async () => undefined),
  loadMoreJoinLeave: jest.fn(async () => undefined),
  toggleBookmark: jest.fn(async () => undefined),
  openInGame: jest.fn(),
  copyTag: jest.fn(async () => undefined),
  openClan: jest.fn(),
  openWar: jest.fn(),
  openCwl: jest.fn(),
  openPlayer: jest.fn(),
  openRanked: jest.fn(),
  openAchievements: jest.fn(),
  updateWarFilter: jest.fn(async () => undefined),
  exportWarStats: jest.fn(async () => 'war-stats.xlsx'),
  loadWarFilterPresets: jest.fn(async () => []),
  saveWarFilterPresets: jest.fn(async () => undefined),
  showMessage: jest.fn(),
});

const wrap = (child: React.ReactElement) =>
  render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">{child}</CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );

describe('PlayerDetailScreen', () => {
  it('uses the safe-area photo hero and hides add-bookmark for a linked player', async () => {
    const screen = await wrap(
      <PlayerDetailScreen
        model={{
          player,
          bookmarked: false,
          linkedAccount: true,
          verifiedTracking: true,
        }}
        actions={actions()}
      />,
    );
    const headerStyle = StyleSheet.flatten(screen.getByTestId('player-header-mobile').props.style);
    expect(headerStyle.minHeight).toBeUndefined();
    expect(headerStyle.maxWidth).toBeUndefined();
    expect(headerStyle.paddingTop).toBe(47);
    expect(
      StyleSheet.flatten(screen.getByTestId('player-header-content').props.style),
    ).toMatchObject({
      width: '100%',
      maxWidth: 1120,
      alignSelf: 'center',
    });
    expect(
      StyleSheet.flatten(screen.getByTestId('player-header-backdrop').props.style),
    ).toMatchObject({
      position: 'absolute',
      top: 0,
      right: 0,
      bottom: 0,
      left: 0,
    });
    expect(screen.getByText(/Clash Kings/)).toBeTruthy();
    expect(screen.queryByLabelText('Add bookmark')).toBeNull();
    expect(screen.getByLabelText('Back')).toBeTruthy();
    expect(screen.getByTestId('player-primary-quick-stats').props.children).toHaveLength(4);
    expect(screen.getByTestId('player-secondary-quick-stats').props.children).toHaveLength(3);
    expect(
      StyleSheet.flatten(screen.getByTestId('player-detail-navigation').props.style),
    ).toMatchObject({
      minHeight: 54,
      paddingHorizontal: 12,
      paddingTop: 8,
      paddingBottom: 2,
    });
    expect(
      StyleSheet.flatten(screen.getByTestId('player-detail-navigation').props.style)
        .borderBottomWidth,
    ).toBeUndefined();
    expect(
      StyleSheet.flatten(screen.getByTestId('destination-picker-control').props.style).minHeight,
    ).toBe(44);
    expect(screen.getByTestId('destination-picker-position')).toBeTruthy();
    expect(screen.getByText('1/8')).toBeTruthy();
    const detailScroll = screen.getByTestId('player-detail-scroll');
    expect(detailScroll.props.stickyHeaderIndices).toEqual([1]);
    expect(detailScroll.props.horizontal).not.toBe(true);
    expect(detailScroll.props.onMoveShouldSetResponderCapture).toBeUndefined();
    expect(screen.getByTestId('player-detail-header-scroll-child')).toBeTruthy();
    expect(screen.getByTestId('player-detail-navigation')).toBeTruthy();
    expect(screen.getByTestId('player-retained-tab-home')).toBeTruthy();
    expect(screen.queryByTestId('player-retained-tab-cwl')).toBeNull();
  });

  it('restores the persisted clan action when live player clan fields are empty', async () => {
    const fallbackPlayer = {
      ...player,
      clan: null,
      clanTag: '',
      clanOverview: PlayerClanOverview.empty(),
    } as Player;
    const screenActions = actions();
    const service = {
      apiV2Url: 'https://api.test',
      loadCachedClanTag: jest.fn(async () => '#CACHED'),
      loadPlayerBattlelog: jest.fn(async () => undefined),
      loadPlayerActivity: jest.fn(async () => undefined),
      loadPlayerCwlHistory: jest.fn(async () => undefined),
      loadPlayerWarStatsWithFilter: jest.fn(async () => undefined),
      loadPlayerJoinLeave: jest.fn(async () => undefined),
      loadPlayerJoinLeaveTotals: jest.fn(async () => undefined),
      loadWarFilterPresets: jest.fn(async () => []),
      saveWarFilterPresets: jest.fn(async () => undefined),
    };
    const screen = await wrap(
      <PlayerDetailRoot
        player={fallbackPlayer}
        service={service as never}
        actions={screenActions}
      />,
    );

    await waitFor(() => expect(screen.getByText('#CACHED')).toBeTruthy());
    expect(service.loadCachedClanTag).toHaveBeenCalledWith('#ALPHA');
    expect(playerHeaderClanIdentity(fallbackPlayer, '#CACHED')).toMatchObject({
      tag: '#CACHED',
      name: '#CACHED',
      badgeUrl: '',
    });
    expect(screen.queryByText('|')).toBeNull();
    await fireEvent.press(screen.getByText('#CACHED'));
    expect(screenActions.openClan).toHaveBeenCalledWith('#CACHED');
  });

  it('updates the bookmark icon immediately while persistence completes', async () => {
    let finish!: () => void;
    const pending = new Promise<void>((resolve) => {
      finish = resolve;
    });
    const screenActions = actions();
    screenActions.toggleBookmark = jest.fn(() => pending);
    const service = {
      apiV2Url: 'https://api.test',
      loadCachedClanTag: jest.fn(async () => ''),
      loadPlayerBattlelog: jest.fn(async () => undefined),
      loadPlayerActivity: jest.fn(async () => undefined),
      loadPlayerCwlHistory: jest.fn(async () => undefined),
      loadPlayerWarStatsWithFilter: jest.fn(async () => undefined),
      loadPlayerJoinLeave: jest.fn(async () => undefined),
      loadPlayerJoinLeaveTotals: jest.fn(async () => undefined),
      loadWarFilterPresets: jest.fn(async () => []),
      saveWarFilterPresets: jest.fn(async () => undefined),
    };
    const screen = await wrap(
      <PlayerDetailRoot
        player={player}
        service={service as never}
        actions={screenActions}
        bookmarked={false}
      />,
    );

    await fireEvent.press(screen.getByLabelText('Bookmark player'));
    expect(screen.getByLabelText('Remove player bookmark')).toBeTruthy();
    finish();
    await pending;
  });

  it('exposes every Flutter destination and routes header actions through the contract', async () => {
    const screenActions = actions();
    const model: PlayerDetailPresentationModel = {
      player,
      bookmarked: false,
      verifiedTracking: true,
    };
    const screen = await wrap(<PlayerDetailScreen model={model} actions={screenActions} />);

    await fireEvent.press(screen.getByLabelText('#ALPHA'));
    await fireEvent.press(screen.getByLabelText('Open in game'));
    await fireEvent.press(screen.getByLabelText('Home Base'));
    expect(screen.getByText('Builder Base')).toBeTruthy();
    expect(screen.getByText('Battles')).toBeTruthy();
    expect(screen.getByText('History')).toBeTruthy();
    expect(screen.getByText('War Stats')).toBeTruthy();
    expect(screen.getByText('CWL History')).toBeTruthy();
    expect(screen.getByText('Achievements')).toBeTruthy();
    expect(screen.getByText('Join / Leave')).toBeTruthy();
    expect(screen.getAllByRole('radio')).toHaveLength(8);
    expect(screenActions.copyTag).toHaveBeenCalledWith('#ALPHA');
    expect(screenActions.openInGame).toHaveBeenCalledWith('#ALPHA');
  });

  it('warms every Flutter stateful history tab through the root service adapter', async () => {
    const screenActions = actions();
    const service = {
      loadCachedClanTag: jest.fn(async () => ''),
      loadPlayerBattlelog: jest.fn(async () => new PlayerBattlelogData([], true, true)),
      loadPlayerActivity: jest.fn(),
      loadPlayerCwlHistory: jest.fn(),
      loadPlayerWarStatsWithFilter: jest.fn(),
      loadRankedLeagueData: jest.fn(),
      loadPlayerJoinLeave: jest.fn(),
      loadPlayerJoinLeaveTotals: jest.fn(),
    };
    const screen = await wrap(
      <PlayerDetailRoot
        player={player}
        service={service as never}
        actions={screenActions}
        initialTab="battles"
      />,
    );
    await waitFor(() => expect(service.loadPlayerBattlelog).toHaveBeenCalledWith('#ALPHA', false));
    expect(service.loadPlayerActivity).toHaveBeenCalledWith('#ALPHA', 'troop_level', false);
    expect(service.loadPlayerCwlHistory).toHaveBeenCalledWith('#ALPHA', false);
    expect(service.loadPlayerJoinLeave).toHaveBeenCalledWith('#ALPHA');
    expect(service.loadPlayerJoinLeaveTotals).toHaveBeenCalledWith('#ALPHA');
    expect(screen.getByText('No battles found')).toBeTruthy();
  });

  it('remounts service state when navigation reuses the root for a different player', async () => {
    const beta = { ...player, name: 'Beta', tag: '#BETA' } as Player;
    const service = {
      loadCachedClanTag: jest.fn(async () => ''),
      loadPlayerBattlelog: jest.fn(async () => new PlayerBattlelogData([], true, true)),
      loadPlayerActivity: jest.fn(async () => undefined),
      loadPlayerCwlHistory: jest.fn(async () => undefined),
      loadPlayerWarStatsWithFilter: jest.fn(async () => undefined),
      loadRankedLeagueData: jest.fn(async () => undefined),
      loadPlayerJoinLeave: jest.fn(async () => undefined),
      loadPlayerJoinLeaveTotals: jest.fn(async () => undefined),
    };
    function Harness() {
      const [active, setActive] = useState<Player>(player);
      return (
        <View>
          <Button title="Switch player" onPress={() => setActive(beta)} />
          <PlayerDetailRoot
            player={active}
            service={service as never}
            actions={actions()}
            initialTab="battles"
          />
        </View>
      );
    }
    const screen = await wrap(<Harness />);
    await waitFor(() => expect(service.loadPlayerBattlelog).toHaveBeenCalledWith('#ALPHA', false));
    fireEvent.press(screen.getByText('Switch player'));
    await waitFor(() => expect(service.loadPlayerBattlelog).toHaveBeenCalledWith('#BETA', false));
    expect(service.loadPlayerActivity).toHaveBeenCalledWith('#BETA', 'troop_level', false);
    expect(service.loadPlayerCwlHistory).toHaveBeenCalledWith('#BETA', false);
    expect(service.loadPlayerJoinLeave).toHaveBeenCalledWith('#BETA');
    expect(screen.getByLabelText('#BETA')).toBeTruthy();
  });

  it('only exposes Flutter pull-to-refresh tabs and force reloads the active dataset', async () => {
    const homeActions = actions();
    const home = await wrap(
      <PlayerDetailScreen
        model={{ player, bookmarked: false, verifiedTracking: true }}
        actions={homeActions}
      />,
    );
    expect(home.getByTestId('player-detail-scroll').props.refreshControl).toBeUndefined();
    const battleActions = actions();
    await refreshPlayerDetailTab('battles', battleActions);
    expect(battleActions.loadTab).toHaveBeenCalledWith('battles', true);
    expect(isPlayerDetailTabRefreshable('home')).toBe(false);
    expect(isPlayerDetailTabRefreshable('history')).toBe(true);
  });

  it('keeps visited tab interaction state attached like Flutter', async () => {
    const screen = await wrap(
      <PlayerDetailScreen
        model={{
          player,
          bookmarked: false,
          verifiedTracking: true,
          battlelog: new PlayerBattlelogData([], true, true),
        }}
        actions={actions()}
        initialTab="battles"
      />,
    );

    await fireEvent.press(screen.getByText('Farming'));
    expect(screen.getByText('Farming overview')).toBeTruthy();
    await fireEvent.press(screen.getByLabelText('Battles'));
    await fireEvent.press(screen.getByRole('radio', { name: 'Home Base' }));
    await fireEvent.press(screen.getByLabelText('Home Base'));
    await fireEvent.press(screen.getByRole('radio', { name: 'Battles' }));
    expect(screen.getByText('Farming overview')).toBeTruthy();
  });

  it('keeps player achievement rows informational like Flutter', async () => {
    const screenActions = actions();
    const achievement = new PlayerAchievement(
      'Conqueror',
      2,
      100,
      250,
      'Win multiplayer battles',
      '',
      'home',
    );
    const achievementPlayer = Object.assign(
      Object.create(Object.getPrototypeOf(player)) as Player,
      player,
      { achievements: [achievement] },
    );
    const model: PlayerDetailPresentationModel = {
      player: achievementPlayer,
      bookmarked: false,
      verifiedTracking: true,
    };
    const screen = await wrap(
      <PlayerDetailScreen model={model} actions={screenActions} initialTab="achievements" />,
    );

    expect(screen.getByText('Conqueror')).toBeTruthy();
    expect(screen.queryByRole('button', { name: /Conqueror/ })).toBeNull();
    expect(screenActions.openAchievements).not.toHaveBeenCalled();
  });

  it('groups completion counts and applies Flutter special achievement stars', async () => {
    const special = new PlayerAchievement(
      'Dragon Slayer',
      0,
      1,
      1,
      'Defeat the dragon',
      '',
      'home',
    );
    const builder = new PlayerAchievement('Builder', 3, 10, 10, 'Build things', '', 'builderBase');
    const achievementPlayer = Object.assign(
      Object.create(Object.getPrototypeOf(player)) as Player,
      player,
      { achievements: [special, builder] },
    );
    const screen = await wrap(
      <PlayerDetailScreen
        model={{ player: achievementPlayer, bookmarked: false, verifiedTracking: true }}
        actions={actions()}
        initialTab="achievements"
      />,
    );
    expect(screen.getByText('Home Base · 1/1')).toBeTruthy();
    expect(screen.getByText('Others · 1/1')).toBeTruthy();
    expect(screen.getByLabelText('3 of 3 stars')).toBeTruthy();
    expect(screen.getByText('1 / 1')).toBeTruthy();
  });

  it('shows join leave summaries, sorting, filters, and pagination', async () => {
    const screenActions = actions();
    const clan = new JoinLeaveClan('Alpha Clan', '#C1', 'badge.png');
    const page = new PlayerJoinLeavePage(3, [
      new JoinLeaveEvent('join', clan, new Date('2026-08-01'), '#P1', 'Alpha', 17),
    ]);
    const totals = [new PlayerJoinLeaveTotal(clan, 2, 1500)];
    const screen = await wrap(
      <PlayerDetailScreen
        model={{
          player,
          bookmarked: false,
          verifiedTracking: true,
          joinLeave: page,
          joinLeaveTotals: totals,
        }}
        actions={screenActions}
        initialTab="joinLeave"
      />,
    );
    expect(screen.getByText('3')).toBeTruthy();
    expect(screen.getByText('Events')).toBeTruthy();
    expect(screen.getByText('1')).toBeTruthy();
    expect(screen.getByText('Clans')).toBeTruthy();
    await fireEvent.scroll(screen.getByTestId('player-detail-scroll'), {
      nativeEvent: {
        contentOffset: { y: 600 },
        contentSize: { height: 1200 },
        layoutMeasurement: { height: 400 },
      },
    });
    expect(screenActions.loadMoreJoinLeave).toHaveBeenCalled();
    await fireEvent.press(screen.getByRole('button', { name: 'History' }));
    await fireEvent.press(screen.getByRole('radio', { name: 'Clan totals' }));
    await fireEvent.press(screen.getByRole('button', { name: 'Filters' }));
    expect(screen.getByText('Time spent')).toBeTruthy();
    expect(screen.getAllByText('Visits').length).toBeGreaterThan(0);
  });

  it('opens the exact current war snapshot, including CWL wars without a tag', async () => {
    const screenActions = actions();
    const currentWar = new WarInfo('inWar', null, 15, 1, null, null, null, null, null, 'cwl');
    const model: PlayerDetailPresentationModel = {
      player,
      bookmarked: false,
      verifiedTracking: true,
      currentWar,
    };
    const screen = await wrap(<PlayerDetailScreen model={model} actions={screenActions} />);

    await fireEvent.press(screen.getByLabelText('Ongoing War'));

    expect(screenActions.openWar).toHaveBeenCalledWith(currentWar);
  });

  it('opens the full CWL context when the clan is in league but not an active war', async () => {
    const screenActions = actions();
    const currentCwl = {
      summary: new WarCwl('#CLAN', false, true, new WarInfo('notInWar'), null, []),
      clanTag: '#CLAN',
      warLeagueName: 'Champion League I',
    };
    const model: PlayerDetailPresentationModel = {
      player,
      bookmarked: false,
      verifiedTracking: true,
      currentCwl,
    };
    const screen = await wrap(<PlayerDetailScreen model={model} actions={screenActions} />);

    await fireEvent.press(screen.getByLabelText('Ongoing CWL'));

    expect(screenActions.openCwl).toHaveBeenCalledWith(currentCwl);
  });
});
