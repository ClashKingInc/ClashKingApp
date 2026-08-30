import { fireEvent, render } from '@testing-library/react-native';
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
  StatsItemSelector,
  StatsItemType,
  StatsItemsResponse,
  StatsMetrics,
  StatsSection,
} from '../models';
import { StatsScreen } from './stats-screen';

afterEach(() => resetGameDataStateForTesting());

test('renders Flutter army discovery copy, exact composition, and share code', async () => {
  const metrics = new StatsMetrics(true, 1200, 2.4, 88, 0.02, 0.08, 0.3, 0.6, [], 0.14);
  const data = new StatsArmiesResponse(
    new StatsDateRange(new Date(2026, 7, 1), new Date(2026, 7, 30)),
    [new StatsArmyResult('u1x10-s1x2', ['Root Rider'], { 'Root Rider': 10 }, metrics)],
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
    armiesSortBy: 'usage_rate',
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
  expect(view.getByText('Exact composition')).toBeTruthy();
  expect(view.getByText('10× Root Rider')).toBeTruthy();
  expect(view.getByText('Army share code: u1x10-s1x2')).toBeTruthy();
});

test('reloads item stats after removing a selector instead of leaving the section idle', async () => {
  const selector = new StatsItemSelector('Fireball', StatsItemType.equipment, 'Grand Warden');
  const provider = {
    audience: StatsAudience.battle,
    section: StatsSection.items,
    dates: new StatsDateFilter(new Date(2026, 7, 1), new Date(2026, 7, 30)),
    itemsTownHall: 18,
    itemsLeagueTier: 1,
    itemSelectors: [selector],
    currentState: {
      status: StatsLoadStatus.data,
      data: new StatsItemsResponse(
        new StatsDateRange(new Date(2026, 7, 1), new Date(2026, 7, 30)),
        [],
        0,
      ),
      isRefreshing: false,
    },
    selectAudience: jest.fn(),
    selectSection: jest.fn(),
    refresh: jest.fn(async () => undefined),
    load: jest.fn(async () => undefined),
    setItemSelectors: jest.fn(),
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

  fireEvent.press(view.getByText('Fireball ×'));

  expect(provider.setItemSelectors).toHaveBeenCalledWith([]);
  expect(provider.load).toHaveBeenCalledWith(StatsSection.items);
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
