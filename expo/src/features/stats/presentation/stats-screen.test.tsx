import { useEffect, useSyncExternalStore } from 'react';
import { act, fireEvent, render, waitFor, within } from '@testing-library/react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { Dimensions, Image, StyleSheet } from 'react-native';
import { captureRef } from 'react-native-view-shot';
import * as Clipboard from 'expo-clipboard';

import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import {
  gameDataState,
  replaceGameDataSection,
  resetGameDataStateForTesting,
} from '../../../core/game-data/game-data-state';
import { StatsLoadStatus, StatsProvider, type StatsRepositoryContract } from '../data';
import {
  StatsAudience,
  StatsClanCountsResponse,
  StatsDateFilter,
  StatsDateRange,
  StatsGroupedCount,
  StatsLegendCohort,
  StatsLegendDay,
  StatsLegendItemUse,
  StatsLegendPetAssignmentUse,
  StatsLegendResponse,
  StatsTroopStatsResponse,
  StatsMetrics,
  StatsPerformanceResponse,
  StatsPlayerCountsResponse,
  StatsSection,
} from '../models';
import { StatsScreen } from './stats-screen';

jest.mock('react-native-view-shot', () => ({ captureRef: jest.fn(async () => 'png-data') }));
jest.mock('expo-clipboard', () => ({ setImageAsync: jest.fn(async () => {}) }));

afterEach(() => resetGameDataStateForTesting());

function ReactiveStatsScreen({ provider }: { provider: StatsProvider }) {
  const revision = useSyncExternalStore(
    (listener) => provider.subscribe(listener),
    provider.getSnapshot,
    provider.getSnapshot,
  );
  useEffect(() => {
    provider.ensureLoaded();
    return () => provider.dispose();
  }, [provider]);
  return <StatsScreen provider={provider} revision={revision} onBack={jest.fn()} />;
}

test('reacts to a real provider notification from loading to empty', async () => {
  let resolve!: (value: StatsPerformanceResponse) => void;
  const war = new Promise<StatsPerformanceResponse>((done) => (resolve = done));
  const repository: StatsRepositoryContract = {
    loadPlayerCounts: jest.fn(async () => new StatsPlayerCountsResponse([], [])),
    loadClanCounts: jest.fn(),
    loadArmies: jest.fn(),
    loadArmySetups: jest.fn(),
    loadArmySetupTimeline: jest.fn(),
    loadItems: jest.fn(),
    loadRanked: jest.fn(),
    loadWar: jest.fn(() => war),
    loadCwl: jest.fn(),
  };
  const provider = new StatsProvider(repository);
  const view = await render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <ReactiveStatsScreen provider={provider} />
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );

  expect(view.getByLabelText('Loading...')).toBeTruthy();
  await act(async () => {
    resolve(
      new StatsPerformanceResponse(
        new StatsDateRange(null, null),
        new StatsMetrics(false, 0, 0, 0, 0, 0, 0, 0, []),
        [],
      ),
    );
    await war;
  });
  expect(await waitFor(() => view.getByText('No battle data yet'))).toBeTruthy();
  expect(view.queryByRole('button', { name: 'Filters' })).toBeNull();
});

test('shows Legend League 1 Ranked rates without a Town Hall filter', async () => {
  const provider = {
    audience: StatsAudience.battle,
    section: StatsSection.ranked,
    dates: new StatsDateFilter(new Date(2026, 7, 1), new Date(2026, 7, 30)),
    rankedTownHall: 18,
    rankedLeagueTier: 105000033,
    armiesMinimumSample: 100,
    armiesInclude: [],
    armiesExclude: [],
    cwlSeasons: [],
    currentState: {
      status: StatsLoadStatus.data,
      data: new StatsLegendResponse(StatsLegendCohort.legend, [
        new StatsLegendDay('2026-08-30', 10, 3, [0, 1, 4, 5], 90, 95, [], [], [], []),
      ]),
      isRefreshing: false,
    },
    selectSection: jest.fn(),
    updateRankedFilters: jest.fn(),
    setDates: jest.fn(async () => undefined),
  } as unknown as StatsProvider;
  const view = await render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <StatsScreen provider={provider} onBack={jest.fn()} />
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );

  expect(view.getAllByText('Legend League 1').length).toBeGreaterThan(0);
  expect(view.queryByRole('button', { name: 'Filters' })).toBeNull();
  expect(view.queryByText('TH18')).toBeNull();
  expect(view.queryByText('Star rates')).toBeNull();
  expect(view.getAllByText('0 Star').length).toBeGreaterThan(0);
});

test('expands, copies, and collapses a Town Hall without covering its chevron', async () => {
  jest.spyOn(Image, 'prefetch').mockResolvedValue(true);
  jest.mocked(captureRef).mockResolvedValue('png-data');
  jest.mocked(Clipboard.setImageAsync).mockResolvedValue();
  const data = new StatsPerformanceResponse(
    new StatsDateRange(new Date(2026, 7, 1), new Date(2026, 7, 30)),
    new StatsMetrics(true, 10, 2.5, 90, 0, 0, 0.5, 0.5, []),
    [],
    [],
    [
      {
        period: '2026-08-30',
        townHall: 18,
        attacks: 10,
        stars: [
          { stars: 0, count: 0 },
          { stars: 1, count: 0 },
          { stars: 2, count: 5 },
          { stars: 3, count: 5 },
        ],
        averageStars: 2.5,
        averageDestruction: 90,
        averageDuration: 120,
      },
    ],
    [
      {
        period: '2026-08-30',
        wars: 6,
        accounts: 45,
        townHalls: [{ level: 18, count: 40 }],
        draws: 0,
        missedAttacks: 2,
      },
    ],
    [5, 10, 15, 20, 25, 30].map((warSize) => ({
      period: '2026-08-30',
      warSize,
      wars: 1,
      accounts: 45,
      townHalls: [{ level: 18, count: 40 }],
      draws: 0,
    })),
  );
  const provider = {
    section: StatsSection.war,
    dates: new StatsDateFilter(new Date(2026, 7, 1), new Date(2026, 7, 30)),
    currentState: { status: StatsLoadStatus.data, data, isRefreshing: false },
    selectSection: jest.fn(),
  } as unknown as StatsProvider;
  const view = await render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <StatsScreen provider={provider} onBack={jest.fn()} />
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );
  const headerStyle = StyleSheet.flatten(view.getByTestId('stats-header').props.style);
  expect(headerStyle.height).toBeUndefined();
  expect(headerStyle.paddingTop).toBe(47);
  expect(view.getByTestId('profile-page-header-backdrop')).toBeTruthy();
  expect(view.queryByTestId('stats-section-picker')).toBeNull();
  expect(view.queryByText('Stats')).toBeNull();
  expect(view.queryByText('Summary')).toBeNull();
  expect(view.getByText('War')).toBeTruthy();
  expect(view.queryByTestId('townhall-18-share-copy')).toBeNull();
  expect(view.getByTestId('townhall-18-expand-caret')).toBeTruthy();
  expect(view.getByText('Missed attacks')).toBeTruthy();
  expect(view.getByText('War sizes')).toBeTruthy();
  expect(view.getByText('15v15')).toBeTruthy();
  expect(view.getByText('30v30')).toBeTruthy();
  const townHall = view.getByRole('button', { name: /TH18/ });
  await act(async () => {
    fireEvent.press(townHall);
  });
  expect(view.getByTestId('townhall-18-share-copy')).toBeTruthy();
  expect(view.getByTestId('townhall-18-collapse-caret')).toBeTruthy();
  expect(view.queryByTestId('townhall-18-expand-caret')).toBeNull();
  const copyStyle = StyleSheet.flatten(view.getByTestId('townhall-18-share-copy').props.style);
  expect(copyStyle.alignSelf).toBe('flex-end');
  expect(copyStyle.position).toBeUndefined();
  expect(view.queryByText('Star rates')).toBeNull();
  expect(view.getAllByText('0 Star').length).toBeGreaterThan(0);
  expect(view.queryByRole('button', { name: 'Filters' })).toBeNull();
  await act(async () => fireEvent.press(view.getByTestId('townhall-18-share-copy')));
  const exported = view.getByTestId('stats-chart-export', { includeHiddenElements: true });
  expect(
    within(exported).getAllByText('Average destruction', { includeHiddenElements: true }).length,
  ).toBeGreaterThan(0);
  await act(async () =>
    fireEvent(exported, 'layout', {
      nativeEvent: { layout: { width: 390, height: 500 } },
    }),
  );
  await waitFor(() => expect(Clipboard.setImageAsync).toHaveBeenCalledWith('png-data'));
  await act(async () => fireEvent.press(view.getByRole('button', { name: /TH18/ })));
  expect(view.queryByTestId('townhall-18-share-copy')).toBeNull();
  expect(view.getByTestId('townhall-18-expand-caret')).toBeTruthy();
  expect(view.queryByTestId('townhall-18-collapse-caret')).toBeNull();
  jest.restoreAllMocks();
});

test('renders troop-overlap Army groups from measured setup observations', async () => {
  const data = {
    firstDay: '2026-09-15',
    lastDay: '2026-09-20',
    completedDays: ['2026-09-15'],
    totalAttacks: 1000,
    classifiedAttacks: 900,
    leagueTierId: 105000036,
    rankLimit: null,
    items: [
      {
        groupKey: '[4000010]',
        variantKey: '',
        coreTroops: [4000010],
        conditions: [],
        shareCode: 'u1x10',
        attacks: 250,
        starCounts: { zero: 1, one: 2, two: 3, three: 244 },
        usageRate: 0.25,
        threeStarRate: 0.976,
        averageDestruction: 98,
        observedDays: 1,
      },
    ],
  };
  const provider = {
    audience: StatsAudience.battle,
    section: StatsSection.armies,
    dates: new StatsDateFilter(new Date(2026, 7, 1), new Date(2026, 7, 30)),
    armyRankLimit: undefined,
    armySetupSort: 'usage',
    currentState: {
      status: StatsLoadStatus.data,
      data,
      isRefreshing: false,
      updatedAt: new Date(),
    },
    selectAudience: jest.fn(),
    selectSection: jest.fn(),
    refresh: jest.fn(async () => undefined),
    load: jest.fn(async () => undefined),
  } as unknown as StatsProvider;

  const view = await render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <StatsScreen provider={provider} onBack={jest.fn()} />
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );

  expect(view.queryByText('Attacks 1,000 · 1 Days')).toBeNull();
  expect(view.getAllByText('25.0%').length).toBeGreaterThan(0);
  expect(view.queryByText('Minimum sample')).toBeNull();
});

test('keeps Army controls visible while a new cohort loads without prior rows', async () => {
  const provider = {
    section: StatsSection.armies,
    dates: new StatsDateFilter(new Date(2026, 7, 1), new Date(2026, 7, 30)),
    armyRankLimit: 200,
    armySetupSort: 'usage',
    currentState: { status: StatsLoadStatus.loading, isRefreshing: false },
    selectSection: jest.fn(),
    updateArmySetupFilters: jest.fn(),
  } as unknown as StatsProvider;
  const view = await render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <StatsScreen provider={provider} onBack={jest.fn()} />
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );
  expect(view.getByRole('tab', { name: 'Top 200' }).props.accessibilityState).toMatchObject({
    selected: true,
  });
  expect(view.getByRole('button', { name: 'Usage' })).toBeTruthy();
  expect(view.queryByTestId('legend-item-troops-401')).toBeNull();
  expect(view.queryByText('Try a wider date range or less restrictive filters.')).toBeNull();
  expect(view.getByLabelText('Loading...')).toBeTruthy();
});

test('switches Troop Stats cohorts without stale items or loading placeholders', async () => {
  const data = new StatsLegendResponse(StatsLegendCohort.legend, [
    new StatsLegendDay(
      '2026-08-30',
      10,
      3,
      [0, 1, 4, 5],
      90,
      95,
      [new StatsLegendItemUse(100, 10, 5)],
      [new StatsLegendItemUse(200, 8, 4)],
      [new StatsLegendItemUse(300, 6, 3)],
      [new StatsLegendPetAssignmentUse(200, 100, 8, 4)],
      [
        new StatsLegendItemUse(400, 7, 3),
        new StatsLegendItemUse(401, 3, 1),
        new StatsLegendItemUse(402, 2, 1),
        new StatsLegendItemUse(403, 2, 1),
        new StatsLegendItemUse(404, 2, 1),
        new StatsLegendItemUse(405, 1, 0),
      ],
      [new StatsLegendItemUse(500, 6, 2)],
      [new StatsLegendItemUse(600, 4, 2)],
      [{ heroId: 100, equipmentIds: [300, 301], uses: 5, triples: 3 }],
      [{ petIds: [200, 201], uses: 4, triples: 2 }],
    ),
    new StatsLegendDay('2026-08-29', 10, 2, [1, 2, 4, 3], 92, 91, [], [], [], []),
  ]);
  const top1000 = new StatsLegendResponse(StatsLegendCohort.top1000, [
    new StatsLegendDay(
      '2026-08-30',
      20,
      3,
      [0, 0, 10, 10],
      90,
      95,
      [],
      [],
      [],
      [],
      [new StatsLegendItemUse(401, 4, 3)],
    ),
    new StatsLegendDay('2026-08-29', 20, 3, [0, 0, 20, 0], 90, 95, [], [], [], []),
  ]);
  const provider = {
    audience: StatsAudience.battle,
    section: StatsSection.items,
    dates: new StatsDateFilter(new Date(2026, 7, 1), new Date(2026, 7, 30)),
    legendCohort: StatsLegendCohort.legend,
    currentState: {
      status: StatsLoadStatus.data,
      data: new StatsTroopStatsResponse(data, top1000, null),
      isRefreshing: false,
    },
    selectAudience: jest.fn(),
    selectSection: jest.fn(),
    refresh: jest.fn(async () => undefined),
    load: jest.fn(async () => undefined),
    updateLegendCohort: jest.fn(),
    setDates: jest.fn(async () => undefined),
  } as unknown as StatsProvider;

  const view = await render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <StatsScreen provider={provider} onBack={jest.fn()} />
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );

  expect(view.getAllByText('Troop Stats').length).toBeGreaterThan(0);
  expect(view.getAllByText('Legend League 1').length).toBeGreaterThan(0);
  expect(view.getByTestId('legend-category-troops')).toBeTruthy();
  expect(view.getAllByText('#400').length).toBeGreaterThan(0);
  expect(view.getByText('Usage across cohorts')).toBeTruthy();
  expect(view.getAllByText('35.0%').length).toBeGreaterThan(0);
  expect(within(view.getByTestId('legend-cohort-overall-401')).getByText('15.0%')).toBeTruthy();
  expect(within(view.getByTestId('legend-cohort-top1000-401')).getByText('10.0%')).toBeTruthy();
  expect(within(view.getByTestId('legend-cohort-top200-401')).getByText('—')).toBeTruthy();
  expect(within(view.getByTestId('legend-item-troops-400')).getByText('42.9%')).toBeTruthy();
  expect(
    within(view.getByTestId('legend-item-troops-400')).getByLabelText('Attacks: 7'),
  ).toBeTruthy();
  expect(view.getByTestId('legend-triple-rate-400').props.accessibilityLabel).toBe(
    'Three-star rate: 42.9%',
  );
  expect(view.getByTestId('troop-league-compare-row').props.style.flexDirection).toBe('row');
  expect(view.getByTestId('profile-tabs-underline-scroll').props.horizontal).toBe(true);
  expect(view.queryByTestId('troop-category-grid')).toBeNull();
  expect(view.getByRole('tab', { name: 'Troops' }).props.accessibilityState.selected).toBe(true);
  expect(view.getByRole('tab', { name: 'Equipment pairs' })).toBeTruthy();
  expect(view.getByRole('tab', { name: 'Pet combinations' })).toBeTruthy();
  const categoryStrip = view.getByTestId('profile-tabs-underline-scroll');
  const rankingList = view.getByTestId('troop-ranking-list');
  const pageHeader = view.getByTestId('stats-header');
  // Native scroll offsets belong to these two mounted nodes; changing a key remounts and loses both.
  expect(view.queryByText('#400 · Daily trend')).toBeNull();
  expect(view.getByTestId('legend-cohort-top200-401').props.accessibilityState.disabled).toBe(true);
  await act(async () => fireEvent.press(view.getByTestId('legend-cohort-top1000-401')));
  expect(view.getByTestId('profile-tabs-underline-scroll')).toBe(categoryStrip);
  expect(view.getByTestId('troop-ranking-list')).toBe(rankingList);
  expect(view.getByTestId('stats-header')).toBe(pageHeader);
  expect(view.queryByRole('button', { name: '#400' })).toBeNull();
  expect(view.getByTestId('legend-triple-rate-401').props.accessibilityLabel).toBe(
    'Three-star rate: 75.0%',
  );
  expect(view.getByTestId('legend-item-toggle-troops-401').props.accessibilityState.expanded).toBe(
    false,
  );
  expect(view.queryByText('#401 · Daily trend')).toBeNull();
  expect(provider.load as jest.Mock).not.toHaveBeenCalled();
  await act(async () => fireEvent.press(view.getByRole('tab', { name: 'Spells' })));
  expect(view.getByTestId('profile-tabs-underline-scroll')).toBe(categoryStrip);
  expect(view.getByTestId('troop-ranking-list')).toBe(rankingList);
  expect(view.getByTestId('stats-header')).toBe(pageHeader);
  expect(view.getByText('No data available.')).toBeTruthy();
  await act(async () => fireEvent.press(view.getByRole('button', { name: 'All' })));
  expect(view.getByTestId('profile-tabs-underline-scroll')).toBe(categoryStrip);
  expect(view.getByTestId('troop-ranking-list')).toBe(rankingList);
  expect(view.getByTestId('stats-header')).toBe(pageHeader);
  expect(view.getByTestId('legend-category-spells')).toBeTruthy();
  await act(async () => fireEvent.press(view.getByRole('tab', { name: 'Troops' })));
  await act(async () => fireEvent.press(view.getByTestId('legend-cohort-overall-401')));
  expect(view.getByRole('button', { name: '#400' })).toBeTruthy();
  expect(view.getByTestId('legend-triple-rate-401').props.accessibilityLabel).toBe(
    'Three-star rate: 33.3%',
  );
  const secondTroop = view.getByRole('button', { name: '#401' });
  await act(async () => {
    fireEvent.press(secondTroop);
  });
  expect(view.getByText('#401 · Daily trend')).toBeTruthy();
  expect(view.getByTestId('legend-item-toggle-troops-401').props.accessibilityState).toMatchObject({
    expanded: true,
  });
  expect(view.getByText('vs. overall 40.0% (−6.7 percentage points)')).toBeTruthy();
  expect(view.queryByLabelText('Loading...')).toBeNull();
  expect(view.getByRole('button', { name: '#400' })).toBeTruthy();
  expect(view.getAllByText('10.0%').length).toBeGreaterThan(0);
  await act(async () => {
    fireEvent.press(view.getByRole('button', { name: 'Compare items' }));
  });
  expect(view.getByText('Select up to 5 items to compare.')).toBeTruthy();
  expect(view.queryByTestId('legend-item-comparison')).toBeNull();
  for (const id of [400, 401, 402, 403, 404]) {
    await act(async () => {
      fireEvent.press(view.getByRole('checkbox', { name: `#${id}` }));
    });
  }
  expect(view.getByTestId('legend-item-comparison')).toBeTruthy();
  expect(view.getByRole('button', { name: 'Done' }).props.accessibilityHint).toBe('5/5');
  expect(view.getByRole('checkbox', { name: '#405' }).props.accessibilityState).toMatchObject({
    disabled: true,
  });
  await act(async () => fireEvent.press(view.getByRole('button', { name: 'Clear Compare items' })));
  expect(view.getByRole('button', { name: 'Done' }).props.accessibilityHint).toBe('0/5');
  expect(view.queryByTestId('legend-item-comparison')).toBeNull();
  expect(view.getByRole('checkbox', { name: '#405' }).props.accessibilityState).toMatchObject({
    disabled: false,
  });
  await act(async () => fireEvent.press(view.getByTestId('legend-cohort-top1000-401')));
  expect(view.getByTestId('legend-item-toggle-troops-401').props.accessibilityState.expanded).toBe(
    false,
  );
  expect(view.queryByRole('checkbox', { name: '#401' })).toBeNull();
  expect(view.getByRole('button', { name: 'Compare items' })).toBeTruthy();
  await act(async () => fireEvent.press(view.getByTestId('legend-cohort-overall-401')));
  await act(async () => fireEvent.press(view.getByRole('button', { name: 'Compare items' })));
  await act(async () => fireEvent.press(view.getByRole('button', { name: 'Done' })));
  expect(view.queryByRole('checkbox', { name: '#405' })).toBeNull();
  expect(view.getByRole('button', { name: 'Compare items' })).toBeTruthy();
  expect(view.queryByRole('button', { name: 'Filters' })).toBeNull();
});

test('keeps large pet-combination rankings in the top-level windowed list', async () => {
  const previousWindow = Dimensions.get('window');
  Dimensions.set({ window: { ...previousWindow, width: 320, fontScale: 1 } });
  const combos = Array.from({ length: 400 }, (_, index) => ({
    petIds: index === 0 ? [1, 1001, 2001, 3001] : [index + 1, index + 1001],
    uses: 400 - index,
    triples: index % 3,
  }));
  const legend = new StatsLegendResponse(StatsLegendCohort.legend, [
    new StatsLegendDay(
      '2026-08-30',
      500,
      20,
      [10, 20, 30, 440],
      90,
      95,
      [],
      [],
      [],
      [],
      [],
      [],
      [],
      [],
      combos,
    ),
  ]);
  const provider = {
    section: StatsSection.items,
    dates: new StatsDateFilter(new Date(2026, 7, 1), new Date(2026, 7, 30)),
    currentState: {
      status: StatsLoadStatus.data,
      data: new StatsTroopStatsResponse(legend, null, null),
      isRefreshing: false,
    },
    selectSection: jest.fn(),
    setDates: jest.fn(async () => undefined),
  } as unknown as StatsProvider;
  const renderCombo = () => render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 320, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <StatsScreen provider={provider} onBack={jest.fn()} />
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );
  const view = await renderCombo();
  const tabs = view.getByTestId('profile-tabs-underline-scroll');
  expect(tabs.props.horizontal).toBe(true);
  expect(
    view
      .getAllByRole('tab')
      .filter((tab) => tab.props.testID?.startsWith('profile-tabs-underline-tab-')),
  ).toHaveLength(9);
  await act(async () => fireEvent.press(view.getByRole('tab', { name: 'Pet combinations' })));
  expect(
    view.getByRole('tab', { name: 'Pet combinations' }).props.accessibilityState.selected,
  ).toBe(true);
  const firstKey = '1:1001:2001:3001';
  const firstName = '#1 + #1001 + #2001 + #3001';
  expect(view.getByRole('button', { name: firstName })).toBeTruthy();
  expect(view.queryByText(firstName)).toBeNull();
  expect(view.getByTestId(`legend-cohort-overall-${firstKey}`).props.style.minHeight).toBe(44);
  expect(view.getByTestId(`legend-cohort-top1000-${firstKey}`)).toBeTruthy();
  expect(view.getByTestId(`legend-cohort-top200-${firstKey}`)).toBeTruthy();
  await act(async () => fireEvent.press(view.getByRole('button', { name: 'Compare items' })));
  expect(view.getByTestId(`legend-metrics-${firstKey}`).props.style.flexDirection).toBe('column');
  expect(view.getByTestId(`legend-ranking-copy-${firstKey}`).props.style.minWidth).toBe(0);
  const petArtwork = within(view.getByTestId(`legend-artwork-${firstKey}`));
  for (let imageIndex = 0; imageIndex < 4; imageIndex += 1) {
    expect(
      petArtwork.getByTestId(`legend-artwork-image-${firstKey}-${imageIndex}`, {
        includeHiddenElements: true,
      }),
    ).toBeTruthy();
  }
  expect(petArtwork.queryByText(/^\+\d+$/)).toBeNull();
  expect(
    StyleSheet.flatten(view.getByTestId(`legend-artwork-image-${firstKey}-0`, {
      includeHiddenElements: true,
    }).props.style).width,
  ).toBe(32);
  expect(view.getByTestId(`legend-attack-icon-${firstKey}`, { includeHiddenElements: true })).toBeTruthy();
  expect(within(view.getByTestId(`legend-metrics-${firstKey}`)).queryByText('Attacks')).toBeNull();
  expect(view.getByTestId(`legend-expand-caret-${firstKey}`).props.style.flexShrink).toBe(0);
  expect(view.getByRole('checkbox', { name: firstName }).props.style).toMatchObject({
    width: 44,
    height: 44,
  });
  await act(async () => fireEvent.press(view.getByTestId(`legend-item-toggle-petCombos-${firstKey}`)));
  expect(view.getByTestId(`legend-collapse-caret-${firstKey}`).props.style.flexShrink).toBe(0);
  expect(view.queryAllByTestId(/^legend-item-petCombos-/).length).toBeLessThan(40);
  await act(async () => view.unmount());
  Dimensions.set({ window: { ...previousWindow, width: 320, fontScale: 1.8 } });
  const largeTextView = await renderCombo();
  await act(async () =>
    fireEvent.press(largeTextView.getByRole('tab', { name: 'Pet combinations' })),
  );
  await act(async () =>
    fireEvent.press(largeTextView.getByRole('button', { name: 'Compare items' })),
  );
  const largeArtwork = within(largeTextView.getByTestId(`legend-artwork-${firstKey}`));
  for (let imageIndex = 0; imageIndex < 4; imageIndex += 1) {
    expect(
      largeArtwork.getByTestId(`legend-artwork-image-${firstKey}-${imageIndex}`, {
        includeHiddenElements: true,
      }),
    ).toBeTruthy();
  }
  expect(largeArtwork.queryByText(/^\+\d+$/)).toBeNull();
  expect(
    StyleSheet.flatten(largeTextView.getByTestId(`legend-artwork-image-${firstKey}-0`, {
      includeHiddenElements: true,
    }).props.style).width,
  ).toBe(28);
  expect(largeTextView.getByTestId(`legend-metrics-${firstKey}`).props.style.flexDirection).toBe('column');
  expect(largeTextView.getByRole('checkbox', { name: firstName }).props.style).toMatchObject({
    width: 44,
    height: 44,
  });
  await act(async () => largeTextView.unmount());
  Dimensions.set({ window: previousWindow });
});

test('uses current static game data for CWL league labels beyond the fallback list', async () => {
  replaceGameDataSection(gameDataState.warLeagueData, {
    leagues: {
      titan: { _id: 48_000_019, name: 'Titan League III' },
    },
  });
  const provider = {
    audience: StatsAudience.world,
    section: StatsSection.clans,
    dates: new StatsDateFilter(new Date(2026, 7, 1), new Date(2026, 7, 30)),
    currentState: {
      status: StatsLoadStatus.data,
      data: new StatsClanCountsResponse([], [new StatsGroupedCount(48_000_019, 12)], []),
      isRefreshing: false,
    },
    selectAudience: jest.fn(),
    selectSection: jest.fn(),
    refresh: jest.fn(async () => undefined),
    load: jest.fn(async () => undefined),
  } as unknown as StatsProvider;

  const view = await render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <StatsScreen provider={provider} onBack={jest.fn()} />
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );

  expect(view.getByText('Titan League III')).toBeTruthy();
});
