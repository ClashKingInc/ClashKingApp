import { act, fireEvent, render, waitFor } from '@testing-library/react-native';
import { StyleSheet } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import {
  StatsDateFilter,
  type StatsArmySetupResponse,
  type StatsArmySetupTimelineResponse,
} from '../models';
import type { StatsProvider } from '../data';
import { ArmySetupSection } from './army-setup-section';

const overview: StatsArmySetupResponse = {
  firstDay: '2026-09-15',
  lastDay: '2026-09-16',
  completedDays: ['2026-09-15', '2026-09-16'],
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
      shareCode: 'u1x10i1x51',
      attacks: 250,
      starCounts: { zero: 1, one: 2, two: 3, three: 244 },
      usageRate: 0.25,
      threeStarRate: 0.976,
      averageDestruction: 98,
      observedDays: 2,
      sieges: [
        { id: 4000051, attacks: 150, usageRate: 0.6 },
        { id: 4000052, attacks: 0, usageRate: 0 },
        { id: 4000062, attacks: 1, usageRate: 0.00001 },
      ],
      dailyRank: 2,
      previousDayRank: 4,
      rankChange: 2,
      comparisons: [
        {
          rankLimit: null,
          attacks: 250,
          totalAttacks: 1000,
          usageRate: 0.25,
          threeStarRate: 0.976,
        },
        { rankLimit: 1000, attacks: 90, totalAttacks: 500, usageRate: 0.18, threeStarRate: 0.8 },
        { rankLimit: 200, attacks: 36, totalAttacks: 300, usageRate: 0.12, threeStarRate: 0.75 },
      ],
    },
  ],
};
const variant = {
  ...overview.items[0]!,
  variantKey: '[{"kind":"spell","id":26000001,"minimum":2}]',
  conditions: [{ kind: 'spell', id: 26000001, minimum: 2 }],
  attacks: 100,
  usageRate: 0.1,
  shareCode: 'u1x10s2x1',
};
const variants: StatsArmySetupResponse = { ...overview, items: [variant] };
const timeline: StatsArmySetupTimelineResponse = {
  ...overview,
  items: [
    {
      day: '2026-09-15',
      totalAttacks: 500,
      observation: null,
      rank: null,
      previousDayRank: null,
      rankChange: null,
    },
    {
      day: '2026-09-16',
      totalAttacks: 500,
      observation: overview.items[0]!,
      rank: 2,
      previousDayRank: null,
      rankChange: null,
    },
  ],
};

test('expands troop groups and setup charts without replacing the army list', async () => {
  const actEnvironment = globalThis as typeof globalThis & { IS_REACT_ACT_ENVIRONMENT?: boolean };
  const previousActEnvironment = actEnvironment.IS_REACT_ACT_ENVIRONMENT;
  actEnvironment.IS_REACT_ACT_ENVIRONMENT = true;
  const loadArmySetupVariants = jest.fn(async () => variants);
  const loadArmySetupTimeline = jest.fn(async () => timeline);
  const provider = {
    dates: new StatsDateFilter(new Date(2026, 8, 15), new Date(2026, 8, 16)),
    armyRankLimit: undefined,
    armySetupSort: 'usage',
    updateArmySetupFilters: jest.fn(),
    loadArmySetupVariants,
    loadArmySetupTimeline,
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
          <ArmySetupSection provider={provider} data={overview} />
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );

  expect(view.getByText('Legend League 1')).toBeTruthy();
  expect(view.getByText('All')).toBeTruthy();
  expect(view.getByText('#1')).toBeTruthy();
  expect(view.queryByText('#2')).toBeNull();
  expect(view.getByText('↑2')).toBeTruthy();
  expect(view.getAllByText('Usage').length).toBeGreaterThan(0);

  await act(async () => {
    fireEvent.press(view.getByText('25.0%'));
  });
  await waitFor(() => expect(loadArmySetupVariants).toHaveBeenCalledWith('[4000010]'));
  expect(view.getByText('18.0%')).toBeTruthy();
  expect(view.getByText('12.0%')).toBeTruthy();
  expect(view.getAllByRole('tab')).toHaveLength(3);
  expect(view.getAllByText('Siege Machines')).toHaveLength(1);
  expect(view.getByText('60.0%')).toBeTruthy();
  expect(view.queryByText('0.0%')).toBeNull();
  await waitFor(() => expect(view.getByRole('button', { name: 'Army' })).toBeTruthy());
  expect(view.getAllByText('25.0%').length).toBeGreaterThan(0);
  expect(view.queryByText('Samples')).toBeNull();
  await act(async () => {
    fireEvent.press(view.getByRole('button', { name: 'Army' }));
  });
  await act(async () => fireEvent.press(view.getByText('s_26000001 ×2')));
  await waitFor(() =>
    expect(loadArmySetupTimeline).toHaveBeenCalledWith('[4000010]', variant.variantKey),
  );
  actEnvironment.IS_REACT_ACT_ENVIRONMENT = previousActEnvironment;
});

test('keeps rank and artwork centered while the name and star rate can wrap at narrow width', async () => {
  const provider = {
    dates: new StatsDateFilter(new Date(2026, 8, 15), new Date(2026, 8, 16)),
    armyRankLimit: undefined,
    armySetupSort: 'usage',
    updateArmySetupFilters: jest.fn(),
    loadArmySetupVariants: jest.fn(),
    loadArmySetupTimeline: jest.fn(),
  } as unknown as StatsProvider;
  const view = await render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 320, height: 640 },
        insets: { top: 0, right: 0, bottom: 0, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="dark">
          <ArmySetupSection provider={provider} data={overview} />
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );

  const row = view.getByTestId('army-setup-card-row');
  const rank = view.getByTestId('army-setup-rank');
  const artwork = view.getByTestId('army-setup-artwork');
  const usage = view.getByTestId('army-setup-usage');
  const tripleRate = view.getByTestId('army-setup-triple-rate');
  expect(row.children[0]).toBe(rank);
  expect(row.children[1]).toBe(artwork);
  expect(row.children[2]).toBe(usage);
  expect(StyleSheet.flatten(row.props.style).alignItems).toBe('center');
  expect(StyleSheet.flatten(rank.props.style).justifyContent).toBe('center');
  expect(StyleSheet.flatten(artwork.props.style).minHeight).toBe(42);
  expect(StyleSheet.flatten(view.getByTestId('army-setup-troop-icon').props.style).width).toBe(42);
  expect(view.getAllByTestId('army-setup-star', { includeHiddenElements: true })).toHaveLength(3);
  expect(tripleRate.props.accessibilityLabel).toContain('Three-star rate: 97.6%');
  expect(StyleSheet.flatten(tripleRate.parent?.props.style).flexWrap).toBe('wrap');
  expect(view.getByText('97.6%')).toBeTruthy();
});
