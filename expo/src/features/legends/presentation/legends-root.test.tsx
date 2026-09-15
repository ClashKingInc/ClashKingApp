import { fireEvent, render, waitFor } from '@testing-library/react-native';
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
} from '../../player/models';
import { useAppRuntime } from '../../../core/app/runtime-context';
import { LegendsRoot, LegendsScreen, legendLeagueDataFromPlayer } from './legends-root';

jest.mock('../../../core/app/runtime-context', () => ({ useAppRuntime: jest.fn() }));
const mockUseAppRuntime = jest.mocked(useAppRuntime);

test('labels and renders each non-automatic Legend battle army with batched opponent insights', async () => {
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
    null,
    null,
    [new PlayerLegendDaySummary(day, 320, -80, 240)],
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

  expect(view.getByText('Your army')).toBeTruthy();
  expect(view.getByText('Army used against you')).toBeTruthy();
  expect(view.getAllByText('Trophies · 5,700')).toHaveLength(2);
  expect(view.getAllByText('Global rank · #24')).toHaveLength(2);
  expect(view.getAllByText(`${day} · +40`)).toHaveLength(2);
  expect(view.getByTestId('legend-recent-summary')).toBeTruthy();
  expect(view.getByTestId(`legend-perfect-day-${day}`)).toBeTruthy();
  expect(view.getByText('Most-used troops · ×1')).toBeTruthy();
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
  fireEvent.press(view.getAllByLabelText('Back')[1]!);
  expect(view.getByText('Stored Player')).toBeTruthy();
  expect(view.getByText('Daily trend')).toBeTruthy();
});
