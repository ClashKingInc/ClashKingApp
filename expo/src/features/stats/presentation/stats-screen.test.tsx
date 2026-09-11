import { fireEvent, render, waitFor } from '@testing-library/react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import {
  gameDataState,
  replaceGameDataSection,
  resetGameDataStateForTesting,
} from '../../../core/game-data/game-data-state';
import { StatsLoadStatus, type StatsProvider } from '../data';
import {
  StatsArmiesResponse,
  StatsArmyResult,
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
  StatsMetrics,
  StatsSection,
} from '../models';
import { StatsScreen } from './stats-screen';

afterEach(() => resetGameDataStateForTesting());

test('renders an army family and its representative share code', async () => {
  const metrics = new StatsMetrics(true, 1200, 2.4, 88, 0.02, 0.08, 0.3, 0.6, [], 0.14);
  const data = new StatsArmiesResponse(
    new StatsDateRange(new Date(2026, 7, 1), new Date(2026, 7, 30)),
    [new StatsArmyResult('123', 'Root Rider', 'u1x10-s1x2', 250, 10_000, 120, metrics)],
    1,
  );
  const provider = {
    audience: StatsAudience.battle,
    section: StatsSection.armies,
    dates: new StatsDateFilter(new Date(2026, 7, 1), new Date(2026, 7, 30)),
    armiesTownHall: 18,
    armiesLeagueTier: undefined,
    armiesMinimumSample: 100,
    armiesLimit: 25,
    armiesSortBy: 'usage',
    armiesInclude: [],
    armiesExclude: [],
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

  expect(
    view.getByText(
      'Automated discovery should surface similar loadout clusters for human naming; it should not infer tactics from composition alone.',
    ),
  ).toBeTruthy();
  expect(view.getByText('Root Rider')).toBeTruthy();
  expect(view.getByText('Army share code: u1x10-s1x2')).toBeTruthy();
});

test('renders Legend daily stats and applies the selected cohort filter', async () => {
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
    ),
  ]);
  const provider = {
    audience: StatsAudience.battle,
    section: StatsSection.items,
    dates: new StatsDateFilter(new Date(2026, 7, 1), new Date(2026, 7, 30)),
    legendCohort: StatsLegendCohort.legend,
    currentState: {
      status: StatsLoadStatus.data,
      data,
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

  expect(view.getAllByText('Legend League').length).toBeGreaterThan(0);
  expect(view.getByTestId('legend-stats-summary')).toBeTruthy();
  expect(view.getAllByText('#100').length).toBeGreaterThan(0);

  fireEvent.press(view.getByLabelText('Filters'));
  const cohort = await waitFor(() => view.getByLabelText('Legend League: Legend League'));
  fireEvent.press(cohort);
  fireEvent.press(await waitFor(() => view.getByText('Top 200')));
  await waitFor(() => view.getByLabelText('Legend League: Top 200'));
  fireEvent.press(view.getByText('Apply'));
  await waitFor(() =>
    expect(provider.updateLegendCohort).toHaveBeenCalledWith(StatsLegendCohort.top200),
  );
  expect(provider.setDates).toHaveBeenCalled();
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
      data: new StatsClanCountsResponse([], [new StatsGroupedCount(48_000_018, 12)], []),
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
