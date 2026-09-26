import { fireEvent, render } from '@testing-library/react-native';
import { StyleSheet } from 'react-native';

import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import {
  PlayerLegendBattle,
  PlayerLegendBattlelog,
  PlayerLegendOpponentInsight,
} from '../../player/models';
import { LegendBattlePanel, sortedLegendBattles } from './legend-battle-panel';

async function renderPanel(
  data: PlayerLegendBattlelog,
  options: {
    readonly onOpenOpponent?: (tag: string) => void;
    readonly onOpenArmy?: (shareCode: string) => void;
  } = {},
) {
  return render(
    <I18nProvider locale="en">
      <CKThemeProvider preference="light">
        <LegendBattlePanel
          data={data}
          now={new Date('2026-09-21T06:30:00.000Z')}
          onOpenArmy={options.onOpenArmy}
          onOpenOpponent={options.onOpenOpponent}
        />
      </CKThemeProvider>
    </I18nProvider>,
  );
}

test('keeps armies collapsed until the card body is pressed and preserves the opponent link', async () => {
  const onOpenOpponent = jest.fn();
  const onOpenArmy = jest.fn();
  const attack = new PlayerLegendBattle(
    40,
    false,
    new Date('2026-09-21T06:00:00.000Z'),
    135,
    18,
    '#OPP',
    'Opponent',
    18,
    3,
    100,
    'u1x8',
    new PlayerLegendOpponentInsight(5700, 24, 40),
  );
  const unknown = new PlayerLegendBattle(20, false, null, 0, 18, '', '', 18, 2, 84, 'u2x8');
  const data = new PlayerLegendBattlelog(
    '#P1',
    '2026-09-21',
    new Date('2026-09-21T05:10:00.000Z'),
    new Date('2026-09-22T05:10:00.000Z'),
    false,
    60,
    -40,
    20,
    [attack, unknown],
    [],
  );
  const view = await renderPanel(data, { onOpenArmy, onOpenOpponent });

  expect(view.getByRole('tab', { name: 'Attacks, 2 / 8' })).toBeTruthy();
  expect(view.getByText('Attacks')).toBeTruthy();
  expect(view.getByText('Defenses')).toBeTruthy();
  expect(view.getByText(/\/ 8 \(\+60\)/)).toBeTruthy();
  expect(view.getByText(/\/ 8 \(-40\)/)).toBeTruthy();
  expect(StyleSheet.flatten(view.getByRole('tab', { name: 'Attacks, 2 / 8' }).props.style))
    .toMatchObject({ alignItems: 'center', justifyContent: 'center' });
  expect(view.getByText('5,700 (#24)')).toBeTruthy();
  expect(StyleSheet.flatten(view.getByText('Opponent').props.style)).toMatchObject({ fontSize: 16 });
  expect(view.getByText('30 minutes ago')).toBeTruthy();
  expect(view.queryByText('2m 15s')).toBeNull();
  expect(view.getByText('(+40)')).toBeTruthy();
  expect(view.getByText('100%')).toBeTruthy();
  expect(view.getByLabelText('Stars: 3 / 3')).toBeTruthy();
  expect(view.getAllByTestId(/legend-battle-0-star-/)).toHaveLength(3);
  expect(
    StyleSheet.flatten(view.getByTestId('legend-battle-1-star-2').props.style),
  ).toMatchObject({ opacity: 0.24 });
  expect(view.queryByTestId('legend-battle-army-0')).toBeNull();

  await fireEvent.press(view.getByRole('link', { name: 'Opponent' }));
  expect(onOpenOpponent).toHaveBeenCalledWith('#OPP');
  expect(view.queryByTestId('legend-battle-army-0')).toBeNull();

  await fireEvent.press(view.getByTestId('legend-battle-0'));
  expect(view.getByTestId('legend-battle-army-0')).toBeTruthy();
  await fireEvent.press(view.getByRole('button', { name: 'Details' }));
  expect(onOpenArmy).toHaveBeenCalledWith('u1x8');

  await fireEvent.press(view.getByTestId('legend-battle-1'));
  expect(view.getByText('Unknown')).toBeTruthy();
  expect(view.getByTestId('legend-battle-army-1')).toBeTruthy();
});

test('sorts newest battles first without mutating the source and keeps missing times stable last', () => {
  const oldest = new PlayerLegendBattle(10, false, new Date('2026-09-21T05:30:00.000Z'));
  const missingFirst = new PlayerLegendBattle(20, false, null);
  const newest = new PlayerLegendBattle(30, false, new Date('2026-09-21T06:15:00.000Z'));
  const missingSecond = new PlayerLegendBattle(40, false, null);
  const source = [oldest, missingFirst, newest, missingSecond] as const;

  expect(sortedLegendBattles(source)).toEqual([newest, oldest, missingFirst, missingSecond]);
  expect(source).toEqual([oldest, missingFirst, newest, missingSecond]);
});

test('never expands an automatic defense even when a share code is present', async () => {
  const automatic = new PlayerLegendBattle(
    -40,
    true,
    new Date('2026-09-21T06:00:00.000Z'),
    30,
    18,
    '',
    '',
    18,
    null,
    null,
    'u1x8',
  );
  const data = new PlayerLegendBattlelog(
    '#P1',
    '2026-09-21',
    new Date('2026-09-21T05:10:00.000Z'),
    new Date('2026-09-22T05:10:00.000Z'),
    false,
    0,
    -40,
    -40,
    [],
    [automatic],
  );
  const view = await renderPanel(data);

  await fireEvent.press(view.getByRole('tab', { name: 'Defenses, 1 / 8' }));
  expect(view.getByText('Automatic defense')).toBeTruthy();
  await fireEvent.press(view.getByTestId('legend-battle-0'));
  expect(view.queryByTestId('legend-battle-army-0')).toBeNull();
});
