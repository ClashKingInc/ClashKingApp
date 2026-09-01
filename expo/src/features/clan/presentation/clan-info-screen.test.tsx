import { fireEvent, render, waitFor, within } from '@testing-library/react-native';
import { StyleSheet } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import {
  Clan,
  ClanBadgeUrls,
  ClanJoinLeave,
  ClanLeaderboardHistory,
  ClanLeaderboardHistoryEntry,
  ClanLeaderboardHistorySummary,
  ClanLeaderboardSeasonSummary,
  ClanLegendHistory,
  ClanLegendHistorySummary,
  ClanProfileHistory,
  ClanRecords,
  ClanWarLog,
  ClanWarStats,
  CwlRankingHistoryEntry,
  JoinLeaveEvent,
} from '../models';
import type { ClanInfoPresentationActions, ClanInfoPresentationModel } from './clan-info-contracts';
import { ClanLeaderboardHistoryTab } from './clan-history-tabs';
import { ClanInfoScreen } from './clan-info-screen';

const testClan = new Clan(
  '#CLAN',
  'Clash Kings',
  'inviteOnly',
  'Join discord.gg/Clash123',
  null,
  true,
  new ClanBadgeUrls('badge-small.png', 'badge-medium.png', 'badge-large.png'),
  20,
  50_000,
  45_000,
  2_000,
  null,
  0,
  'always',
  4,
  100,
  2,
  3,
  true,
  null,
  0,
  [],
  [],
  0,
  0,
  null,
  null,
);

const actions = (): ClanInfoPresentationActions =>
  ({
    goBack: jest.fn(),
    copyClanTag: jest.fn(async () => undefined),
    toggleClanBookmark: jest.fn(async () => undefined),
    openClanInGame: jest.fn(),
    openDiscord: jest.fn(async () => undefined),
    openWar: jest.fn(),
    openHistoricalWar: jest.fn(),
    openCwl: jest.fn(),
    openCapital: jest.fn(),
    showMessage: jest.fn(),
    loadPlayer: jest.fn(),
    openPlayer: jest.fn(),
    loadJoinLeave: jest.fn(() => neverSettles<ClanJoinLeave>()),
    loadMoreJoinLeave: jest.fn(() => neverSettles<ClanJoinLeave>()),
    loadWarLog: jest.fn(() => neverSettles<ClanWarLog>()),
    loadWarStats: jest.fn(() => neverSettles<ClanWarStats>()),
    loadCwlHistory: jest.fn(() => neverSettles<readonly never[]>()),
    loadLeaderboardSummary: jest.fn(() => neverSettles<ClanLeaderboardHistorySummary>()),
    loadLeaderboardHistory: jest.fn(() => neverSettles<ClanLeaderboardHistory>()),
    loadLegendSummary: jest.fn(() => neverSettles<ClanLegendHistorySummary>()),
    loadLegendHistory: jest.fn(() => neverSettles<ClanLegendHistory>()),
    loadRecords: jest.fn(() => neverSettles<ClanRecords>()),
    loadProfileHistory: jest.fn(() => neverSettles<ClanProfileHistory>()),
  }) as ClanInfoPresentationActions;

function neverSettles<T>(): Promise<T> {
  return new Promise(() => undefined);
}

function renderScreen(
  model: ClanInfoPresentationModel,
  screenActions: ClanInfoPresentationActions,
  initialTab = 0,
) {
  return render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <ClanInfoScreen model={model} actions={screenActions} initialTab={initialTab} />
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );
}

describe('ClanInfoScreen', () => {
  it('renders the clan and excludes gated destinations from the selector', async () => {
    const screenActions = actions();
    const screen = await renderScreen(
      {
        clan: testClan,
        bookmarked: false,
        activeUserTags: new Set(),
        featureFlags: { rankings: false },
      },
      screenActions,
    );

    expect(screen.getByText('Clash Kings')).toBeTruthy();
    expect(screen.getByText('Family-friendly')).toBeTruthy();
    expect(
      StyleSheet.flatten(screen.getByTestId('clan-destination-bar').props.style),
    ).toMatchObject({
      minHeight: 54,
      paddingHorizontal: 12,
      paddingTop: 8,
      paddingBottom: 2,
    });
    expect(
      StyleSheet.flatten(screen.getByTestId('destination-picker-control').props.style).minHeight,
    ).toBe(44);
    expect(screen.getByTestId('destination-picker-position')).toBeTruthy();
    expect(screen.getByText('1/8')).toBeTruthy();
    await fireEvent.press(screen.getByLabelText('Members'));
    expect(screen.queryByText('Rankings')).toBeNull();
    expect(screen.getByText('War Log')).toBeTruthy();
    expect(screen.getByText('Join/Leave')).toBeTruthy();
    const detailScroll = screen.getByTestId('clan-info-scroll');
    expect(detailScroll.props.stickyHeaderIndices).toEqual([1]);
    expect(detailScroll.props.horizontal).not.toBe(true);
    expect(detailScroll.props.onMoveShouldSetResponderCapture).toBeUndefined();
    expect(screen.getByTestId('clan-info-header-scroll-child')).toBeTruthy();
    expect(screen.getByTestId('clan-destination-bar')).toBeTruthy();
    expect(screen.getByTestId('clan-retained-tab-members')).toBeTruthy();
    expect(screen.queryByTestId('clan-retained-tab-cwlHistory')).toBeNull();
  });

  it('routes header actions through the injected presentation contract', async () => {
    const screenActions = actions();
    const screen = await renderScreen(
      { clan: testClan, bookmarked: false, activeUserTags: new Set() },
      screenActions,
    );

    await fireEvent.press(screen.getByLabelText('Discord'));
    await fireEvent.press(screen.getByLabelText('Open in game'));
    expect(screenActions.openDiscord).toHaveBeenCalledWith('Clash123');
    expect(screenActions.openClanInGame).toHaveBeenCalledWith(testClan);
  });

  it('exposes every enabled destination through the page picker', async () => {
    const screen = await renderScreen(
      { clan: testClan, bookmarked: false, activeUserTags: new Set() },
      actions(),
    );

    await fireEvent.press(screen.getByLabelText('Members'));
    expect(screen.getAllByRole('radio')).toHaveLength(9);
    expect(screen.getByRole('radio', { name: 'Members' })).toBeTruthy();
    expect(screen.getByRole('radio', { name: 'War Log' })).toBeTruthy();
    expect(screen.getByRole('radio', { name: 'Join/Leave' })).toBeTruthy();
    expect(screen.getByRole('radio', { name: 'War Stats' })).toBeTruthy();
    expect(screen.getByRole('radio', { name: 'Rankings' })).toBeTruthy();
    expect(screen.getByRole('radio', { name: 'CWL History' })).toBeTruthy();
    expect(screen.getByRole('radio', { name: 'Leaderboard History' })).toBeTruthy();
    expect(screen.getByRole('radio', { name: 'Legend History' })).toBeTruthy();
    expect(screen.getByRole('radio', { name: 'Records & History' })).toBeTruthy();
  });

  it('keeps visited member filters attached when switching tabs', async () => {
    const screen = await renderScreen(
      { clan: testClan, bookmarked: false, activeUserTags: new Set() },
      actions(),
    );

    const search = screen.getByLabelText('Search members');
    await fireEvent.changeText(search, 'alpha');
    await fireEvent.press(screen.getByLabelText('Members'));
    await fireEvent.press(screen.getByRole('radio', { name: 'Rankings' }));
    await fireEvent.press(screen.getByLabelText('Rankings'));
    await fireEvent.press(screen.getByRole('radio', { name: 'Members' }));
    expect(screen.getByLabelText('Search members').props.value).toBe('alpha');
    expect(screen.getByTestId('clan-retained-tab-members')).toBeTruthy();
    expect(
      screen.getByTestId('clan-retained-tab-rankings', { includeHiddenElements: true }),
    ).toBeTruthy();
  });

  it('separates war stats search, dropdown controls, and summary rows', async () => {
    const screen = await renderScreen(
      { clan: testClan, bookmarked: false, activeUserTags: new Set() },
      actions(),
      3,
    );

    expect(screen.getByTestId('clan-war-stats-search-row')).toBeTruthy();
    const controls = screen.getByTestId('clan-war-stats-controls-row');
    expect(within(controls).getAllByTestId('destination-picker-control')).toHaveLength(2);
    expect(within(controls).getByText('50 wars')).toBeTruthy();
    expect(screen.getByTestId('clan-filter-trigger')).toBeTruthy();
    expect(screen.getByTestId('clan-war-stats-summary-row')).toBeTruthy();
  });

  it('starts every clan history request on entry instead of waiting for selection', async () => {
    const screenActions = actions();
    renderScreen({ clan: testClan, bookmarked: false, activeUserTags: new Set() }, screenActions);

    await waitFor(() => {
      expect(screenActions.loadCwlHistory).toHaveBeenCalledWith('#CLAN');
      expect(screenActions.loadLeaderboardSummary).toHaveBeenCalledTimes(1);
      expect(screenActions.loadLegendSummary).toHaveBeenCalledWith('#CLAN');
      expect(screenActions.loadRecords).toHaveBeenCalledWith('#CLAN');
      expect(screenActions.loadProfileHistory).toHaveBeenCalledWith('#CLAN');
    });
  });

  it('uses distinct material and shell SVG gradient references for every CWL history card', async () => {
    const screenActions = actions();
    screenActions.loadCwlHistory = jest.fn(async () => [
      new CwlRankingHistoryEntry('2026-08', 13, 'Champion League I', 1, 300, 95, 7, 0, 0, true),
      new CwlRankingHistoryEntry('2026-07', 10, 'Gold League I', 2, 250, 90, 5, 1, 1, true),
    ]);
    const screen = await renderScreen(
      { clan: testClan, bookmarked: false, activeUserTags: new Set() },
      screenActions,
      5,
    );

    await waitFor(() => {
      const materialIds = screen.container
        .queryAll((node) => String(node.props.name).startsWith('cwl-card-material-gradient-'))
        .map((node) => String(node.props.name));
      const shellIds = screen.container
        .queryAll((node) => String(node.props.name).startsWith('cwl-card-shell-gradient-'))
        .map((node) => String(node.props.name));
      const fills = screen.container
        .queryAll((node) => typeof node.props.fill?.brushRef === 'string')
        .map((node) => node.props.fill.brushRef as string)
        .filter(
          (fill) =>
            fill.startsWith('cwl-card-material-gradient-') ||
            fill.startsWith('cwl-card-shell-gradient-'),
        );
      expect(materialIds).toHaveLength(2);
      expect(shellIds).toHaveLength(2);
      expect(new Set([...materialIds, ...shellIds]).size).toBe(4);
      expect(new Set(fills)).toEqual(new Set([...shellIds, ...materialIds]));
    });
  });

  it('resets the leaderboard chart to rank when its type changes', async () => {
    const screenActions = actions();
    screenActions.loadLeaderboardSummary = jest.fn(
      async () =>
        new ClanLeaderboardHistorySummary([
          new ClanLeaderboardSeasonSummary(
            '2026-08',
            new Date('2026-08-01T00:00:00Z'),
            new Date('2026-09-01T00:00:00Z'),
            20,
            3,
            50_000,
          ),
        ]),
    );
    screenActions.loadLeaderboardHistory = jest.fn(
      async () =>
        new ClanLeaderboardHistory([
          new ClanLeaderboardHistoryEntry(new Date('2026-08-15T00:00:00Z'), 3, 50_000, 50, null),
        ]),
    );
    const screen = await render(
      <SafeAreaProvider
        initialMetrics={{
          frame: { x: 0, y: 0, width: 390, height: 844 },
          insets: { top: 47, right: 0, bottom: 34, left: 0 },
        }}
      >
        <I18nProvider locale="en">
          <CKThemeProvider preference="light">
            <ClanLeaderboardHistoryTab
              model={{ clan: testClan, bookmarked: false, activeUserTags: new Set() }}
              actions={screenActions}
            />
          </CKThemeProvider>
        </I18nProvider>
      </SafeAreaProvider>,
    );

    await waitFor(() => expect(screen.getByRole('checkbox', { name: 'Rank' })).toBeTruthy());
    await fireEvent.press(screen.getByRole('checkbox', { name: 'Clan points' }));
    expect(
      screen.getByRole('checkbox', { name: 'Clan points' }).props.accessibilityState.checked,
    ).toBe(true);
    await fireEvent.press(screen.getByRole('checkbox', { name: 'Builder Base' }));
    expect(screen.getByRole('checkbox', { name: 'Rank' }).props.accessibilityState.checked).toBe(
      true,
    );
  });

  it('requests the next clan movement page near the end of the shared scroll', async () => {
    const firstPage = new ClanJoinLeave('#CLAN', 2, 2, [
      new JoinLeaveEvent('join', null, new Date('2026-08-01T00:00:00Z'), '#P1', 'Alpha', 17),
    ]);
    const clan = Object.assign(Object.create(Object.getPrototypeOf(testClan)) as Clan, testClan, {
      joinLeave: firstPage,
    });
    const screenActions = actions();
    screenActions.loadMoreJoinLeave = jest.fn(async () => firstPage);
    const screen = await renderScreen(
      { clan, bookmarked: false, activeUserTags: new Set() },
      screenActions,
      2,
    );

    expect(StyleSheet.flatten(screen.getByTestId('clan-filter-trigger').props.style)).toMatchObject(
      {
        marginLeft: 'auto',
      },
    );
    await fireEvent.press(screen.getByTestId('clan-filter-trigger'));
    expect(StyleSheet.flatten(screen.getByTestId('clan-filter-options').props.style)).toMatchObject(
      {
        justifyContent: 'flex-end',
      },
    );

    await fireEvent.scroll(screen.getByTestId('clan-info-scroll'), {
      nativeEvent: {
        contentOffset: { y: 600 },
        contentSize: { height: 1200 },
        layoutMeasurement: { height: 400 },
      },
    });
    expect(screenActions.loadMoreJoinLeave).toHaveBeenCalledWith(clan, firstPage);
  });
});
