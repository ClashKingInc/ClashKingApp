import { fireEvent, render, waitFor, within } from '@testing-library/react-native';
import { StyleSheet } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import {
  Player,
  PlayerLegendBattle,
  PlayerLegendBattlelog,
  PlayerLegendDaySummary,
  PlayerLegendLeagueData,
  PlayerLegendOpponentInsight,
  PlayerLegendRank,
} from '../../player/models';
import {
  PlayerBattlelogArmyCatalog,
  PlayerBattlelogArmyItem,
} from '../../player/models/player-battlelog';
import { useAppRuntime } from '../../../core/app/runtime-context';
import {
  LegendsRoot,
  LegendsScreen,
  SeasonDayTable,
  legendContributionAtPoint,
  legendHistoryTopPercent,
  groupLegendComparisons,
  legendContributionRows,
  legendLeagueDataFromPlayer,
  legendSeasonDateRange,
} from './legends-root';

test('shows daily net gains, losses and zeroes with distinct semantic colors', async () => {
  const view = await render(
    <I18nProvider locale="en">
      <CKThemeProvider preference="dark">
        <SeasonDayTable
          days={[
            new PlayerLegendDaySummary('2026-09-18', 290, -218, 72),
            new PlayerLegendDaySummary('2026-09-19', 223, -236, -13),
            new PlayerLegendDaySummary('2026-09-20', 0, 0, 0),
          ]}
        />
      </CKThemeProvider>
    </I18nProvider>,
  );
  expect(view.getByText('+/-')).toBeTruthy();
  expect(view.getByText('+72')).toBeTruthy();
  expect(view.getByText('-13')).toBeTruthy();
  expect(StyleSheet.flatten(view.getByTestId('legend-day-net-2026-09-18').props.style).color).toBe(
    '#14A37F',
  );
  expect(StyleSheet.flatten(view.getByTestId('legend-day-net-2026-09-19').props.style).color).toBe(
    '#E35D4F',
  );
  expect(StyleSheet.flatten(view.getByTestId('legend-day-net-2026-09-20').props.style).color).toBe(
    '#C5C6D0',
  );
});

test('calculates historical Top percentage from the season last-place rank', () => {
  expect(legendHistoryTopPercent(1196, 11724)).toBe(10.3);
  expect(legendHistoryTopPercent(1, 11724)).toBe(0.1);
  expect(legendHistoryTopPercent(11724, 11724)).toBe(100);
  expect(legendHistoryTopPercent(10, null)).toBeNull();
  expect(legendHistoryTopPercent(10, 0)).toBeNull();
  expect(legendHistoryTopPercent(10, 5)).toBeNull();
});

jest.mock('../../../core/app/runtime-context', () => ({ useAppRuntime: jest.fn() }));
const mockUseAppRuntime = jest.mocked(useAppRuntime);

test('labels and renders each non-automatic Legend battle army with batched opponent insights', async () => {
  const catalog = jest
    .spyOn(PlayerBattlelogArmyCatalog, 'resolve')
    .mockImplementation(
      (code) =>
        new PlayerBattlelogArmyItem(
          code,
          code,
          `https://example.com/${code}.png`,
          1,
          code.endsWith('_51'),
        ),
    );
  const day = '2026-08-15';
  const insight = new PlayerLegendOpponentInsight(5700, 24, 40);
  const battle = (shareCode: string) =>
    new PlayerLegendBattle(
      40,
      false,
      new Date('2026-08-15T06:00:00.000Z'),
      120,
      18,
      '#O1',
      'Opponent',
      18,
      3,
      100,
      shareCode,
      insight,
    );
  const data = new PlayerLegendLeagueData(
    '#P1',
    'One',
    18,
    5600,
    5900,
    new PlayerLegendBattlelog(
      '#P1',
      day,
      new Date(`${day}T05:00:00.000Z`),
      new Date('2026-08-16T05:00:00.000Z'),
      true,
      40,
      -40,
      0,
      [battle('u8x5-2x6')],
      [battle('u10x5'), new PlayerLegendBattle(-40, true)],
    ),
    [],
    day,
    new PlayerLegendRank('#P1', 'One', 5600, 24, {
      id: 32000006,
      name: 'United States',
      countryCode: 'US',
    }),
    null,
    [new PlayerLegendDaySummary(day, 320, -80, 240)],
    ['u1x1s1x2i1x51'],
    '2026-08-01T05:10:00.000Z',
    '2026-09-01T05:10:00.000Z',
    {
      attacks: 10,
      defenses: 8,
      attackTriples: 3,
      defenseTriples: 2,
      averageOffense: 31.5,
      averageDefense: -22.5,
    },
    [
      {
        cohort: 'top_1000',
        days: 14,
        attacks: 20,
        triples: 8,
        playerAttacks: 10,
        playerTriples: 3,
      },
      { cohort: 'top_200', days: 14, attacks: 0, triples: 0, playerAttacks: 0, playerTriples: 0 },
    ],
    {
      familyId: '548',
      name: 'Thrower family',
      shareCode: 'u1x1s1x2i1x51',
      items: [
        {
          cohort: 'top_200',
          days: 14,
          attacks: 20,
          triples: 8,
          playerAttacks: 10,
          playerTriples: 3,
        },
      ],
    },
  );

  const view = await render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <LegendsScreen
            api={{} as never}
            data={data}
            error={null}
            loading={false}
            refreshing={false}
            selectedDay={day}
            onBack={jest.fn()}
            onRefresh={jest.fn(async () => undefined)}
            onSelectDay={jest.fn()}
            onExport={jest.fn()}
          />
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );

  expect(view.queryByText('Your army')).toBeNull();
  expect(view.queryByText('Army used against you')).toBeNull();
  expect(view.getByLabelText('Trophies: 5,600')).toBeTruthy();
  expect(view.getByLabelText('Global rank: #24')).toBeTruthy();
  const hero = within(view.getByTestId('legends-hero'));
  expect(StyleSheet.flatten(hero.getByLabelText('Trophies: 5,600').props.style)).toMatchObject({
    gap: 5,
    paddingHorizontal: 10,
    paddingVertical: 6,
  });
  expect(StyleSheet.flatten(hero.getByText('5,600').props.style)).toMatchObject({ fontSize: 12 });
  for (const label of ['Trophies', 'Global rank', 'Location', 'Hitrate']) {
    expect(hero.queryByText(label)).toBeNull();
  }
  expect(view.queryByText(`${day} · +40`)).toBeNull();
  expect(view.queryByText('Daily trophy change · recorded battles')).toBeNull();
  expect(view.queryByText('Best Trophies')).toBeNull();
  expect(view.getByText('United States')).toBeTruthy();
  expect(view.queryByText('+31.5')).toBeNull();
  expect(view.queryByText('-22.5')).toBeNull();
  expect(view.getByLabelText('Hitrate: 30.0%')).toBeTruthy();
  expect(view.queryByText('Three-star rate 25.0%')).toBeNull();
  expect(view.getAllByText('August 15, 2026')).toHaveLength(1);
  expect(view.getAllByText('+240')).toHaveLength(1);
  await fireEvent.press(view.getByRole('tab', { name: /Defenses/ }));
  expect(view.getByText('Automatic defense')).toBeTruthy();
  expect(view.queryByTestId('legend-army')).toBeNull();
  await fireEvent.press(view.getByTestId('legend-battle-0'));
  expect(view.getByTestId('legend-army')).toBeTruthy();
  expect(view.getByRole('button', { name: 'Details' })).toBeTruthy();
  await fireEvent.press(view.getByText('By Day'));
  await fireEvent.press(view.getByRole('radio', { name: 'Season' }));
  expect(view.getByTestId('legend-recent-summary')).toBeTruthy();
  expect(view.queryByText('+31.5')).toBeNull();
  expect(view.queryByText('-22.5')).toBeNull();
  expect(view.getByText('Aug 1, 2026 – Aug 31, 2026')).toBeTruthy();
  expect(view.getByTestId('legend-contribution-calendar')).toBeTruthy();
  expect(view.getByTestId(`legend-perfect-day-${day}`)).toBeTruthy();
  expect(view.getByLabelText('Troops: u_1')).toBeTruthy();
  expect(view.getByLabelText('Spells: s_2')).toBeTruthy();
  expect(view.getByLabelText('Siege Machines: u_51')).toBeTruthy();
  expect(within(view.getByTestId('legend-popular-Troop')).queryByText('u_1')).toBeNull();
  expect(view.getByTestId('legend-performance-comparisons')).toBeTruthy();
  expect(view.getAllByText('Top 1,000')).toHaveLength(1);
  expect(view.getAllByText('Top 200')).toHaveLength(1);
  expect(view.getAllByText('30.0%').length).toBeGreaterThan(0);
  expect(view.getAllByText('40.0%').length).toBeGreaterThan(0);
  expect(view.getAllByText('3/10 · 14 days')).toHaveLength(2);
  expect(view.getAllByText('8/20 · Three-star rate').length).toBeGreaterThan(0);
  expect(view.queryByText('0.0%')).toBeNull();
  expect(view.getByTestId('legend-army-performance-comparisons')).toBeTruthy();
  expect(view.getByText('Thrower family')).toBeTruthy();
  expect(view.getByRole('button', { name: 'Armies: Thrower family' })).toBeTruthy();
  catalog.mockRestore();
});

test('flows fixed-size trophy cells across available columns while preserving missing dates', () => {
  const days = [
    { key: '2026-09-20', change: 10, attackTrophies: 40 },
    { key: '2026-09-22', change: 30, attackTrophies: 80 },
    { key: '2026-09-28', change: -10, attackTrophies: 120 },
  ];
  const rows = legendContributionRows(days, 4);
  expect(rows).toHaveLength(3);
  expect(rows[0]?.[1]).toBeNull();
  expect(rows[0]?.[2]?.key).toBe('2026-09-22');
  expect(legendContributionAtPoint(rows, 2, 2)?.key).toBe('2026-09-20');
  expect(legendContributionAtPoint(rows, 2, 54)?.key).toBe('2026-09-28');
  expect(legendContributionRows(days, 12)).toHaveLength(1);
});

test('shows the personal comparison baseline once only when cohort coverage matches', () => {
  const shared = { days: 6, playerAttacks: 48, playerTriples: 22, attacks: 100, triples: 60 };
  const groups = groupLegendComparisons([
    { ...shared, cohort: 'legend_i' },
    { ...shared, cohort: 'top_1000' },
    { ...shared, cohort: 'top_200', days: 5, playerAttacks: 40, playerTriples: 18 },
  ]);
  expect(groups.map((group) => group.length)).toEqual([2, 1]);
});

test('parses full season ISO timestamps as local calendar dates and caps the exclusive end at today', () => {
  const range = legendSeasonDateRange(
    '2026-08-25T05:10:00.000Z',
    '2026-09-28T05:10:00.000Z',
    '2026-09-01',
    '2026-09-21',
  );

  expect([range.start.getFullYear(), range.start.getMonth() + 1, range.start.getDate()]).toEqual([
    2026, 8, 25,
  ]);
  expect([range.end.getFullYear(), range.end.getMonth() + 1, range.end.getDate()]).toEqual([
    2026, 9, 21,
  ]);
});

test('keeps hero actions below the safe area and surfaces total API failure', async () => {
  const day = '2026-08-15';
  const data = new PlayerLegendLeagueData('#P1', 'One', 18, 5600, 5900, null, [], day);
  const view = await render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <LegendsScreen
            data={data}
            error="Legend League data is temporarily unavailable."
            loading={false}
            refreshing={false}
            selectedDay={day}
            onBack={jest.fn()}
            onRefresh={jest.fn(async () => undefined)}
            onSelectDay={jest.fn()}
            onExport={jest.fn()}
          />
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );

  expect(StyleSheet.flatten(view.getByTestId('legends-hero').props.style)).toMatchObject({
    minHeight: 285,
  });
  expect(StyleSheet.flatten(view.getByTestId('legends-hero-actions').props.style)).toMatchObject({
    top: 51,
    left: 16,
    right: 16,
  });
  expect(
    view.getByText('The server is temporarily unavailable. Please try again shortly.'),
  ).toBeTruthy();
  expect(view.queryByText('Not in Legend League')).toBeNull();
  expect(view.queryByText('History')).toBeNull();
});

test('renders stored player Legends immediately and retains them while another day loads', async () => {
  const today = new Date(Date.now() - 5 * 60 * 60 * 1000).toISOString().slice(0, 10);
  const storedDay = {
    trophiesGainedTotal: 80,
    trophiesLostTotal: -20,
    trophiesTotal: 60,
    attacks: [40, 40],
    defenses: [-20],
  };
  const player = Player.fromJson({
    tag: '#P1',
    name: 'Stored Player',
    townHallLevel: 18,
    trophies: 5600,
    bestTrophies: 5900,
  });
  player.legendsBySeason = {
    getSpecificSeason: () => ({ days: { [today]: storedDay } }),
  } as never;
  const initial = legendLeagueDataFromPlayer(player, today);
  expect(initial.currentDay).toMatchObject({ day: today, trophyChange: 60 });
  expect(initial.currentDay?.startsAt.toISOString()).toBe(`${today}T05:10:00.000Z`);
  expect(initial.currentDay?.endsAt.getTime()).toBe(
    initial.currentDay!.startsAt.getTime() + 86_400_000,
  );

  const pending = new Promise<PlayerLegendLeagueData>(() => undefined);
  const loadLegendLeagueData = jest.fn(
    async (_tag: string, _force: boolean, day: string, baseline: PlayerLegendLeagueData) =>
      day === today ? baseline : pending,
  );
  mockUseAppRuntime.mockReturnValue({ players: { loadLegendLeagueData } } as never);
  const view = await render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <LegendsRoot player={player} onBack={jest.fn()} />
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );

  expect(view.getByText('Stored Player')).toBeTruthy();
  await waitFor(() => expect(loadLegendLeagueData).toHaveBeenCalled());
  await fireEvent.press(view.getByLabelText('Previous page'));
  expect(view.getByText('Stored Player')).toBeTruthy();
});
