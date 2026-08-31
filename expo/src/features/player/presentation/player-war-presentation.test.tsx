import { fireEvent, render, waitFor } from '@testing-library/react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { Linking } from 'react-native';

import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import { Player } from '../models';
import {
  EnemyTownhallStats,
  MiniWarMember,
  PlayerWarStats,
  PlayerWarStatsData,
  PlayerWarTypeStats,
  WarAttackSnapshot,
  WarMemberData,
} from '../models/player-war';
import { WarInfo } from '../../war/models/war';
import { PlayerWarTab, warAttackSwipeAction } from './player-detail-components';

const typeStats = new PlayerWarTypeStats(
  1,
  1,
  1,
  1,
  0,
  { '0': 0, '1': 0, '2': 0, '3': 1 },
  { '0': 0, '1': 0, '2': 1, '3': 0 },
  { '17vs16': new EnemyTownhallStats(3, 100, 1, { '3': 1 }) },
  { '16vs17': new EnemyTownhallStats(2, 85, 1, { '2': 1 }) },
);
const target = new MiniWarMember('#TARGET', 'Defender', 16, 4, null);
const attacker = new MiniWarMember('#ATTACKER', 'Attacker', 16, 5, null);
const war = new PlayerWarStatsData(
  WarInfo.fromJson({
    state: 'warEnded',
    war_tag: '#WAR',
    warType: 'random',
    teamSize: 15,
    attacksPerMember: 2,
    startTime: '20260801T120000.000Z',
    endTime: '20260802T120000.000Z',
    clan: {
      tag: '#A',
      name: 'Alpha',
      clanLevel: 20,
      attacks: 28,
      stars: 40,
      destructionPercentage: 96.4,
    },
    opponent: {
      tag: '#B',
      name: 'Bravo',
      clanLevel: 19,
      attacks: 27,
      stars: 38,
      destructionPercentage: 91.2,
    },
  }),
  new WarMemberData(
    '#PLAYER',
    'Player',
    17,
    1,
    1,
    [new WarAttackSnapshot('#PLAYER', '#TARGET', 3, 100, 1, 120, target, null)],
    [new WarAttackSnapshot('#ATTACKER', '#PLAYER', 2, 85, 2, 130, null, attacker)],
  ),
);
const friendlyTarget = new MiniWarMember('#FRIENDLY', 'Friendly Defender', 15, 7, null);
const friendlyWar = new PlayerWarStatsData(
  WarInfo.fromJson({
    state: 'warEnded',
    war_tag: '#FRIENDLY-WAR',
    warType: 'friendly',
    startTime: '20260803T120000.000Z',
  }),
  new WarMemberData(
    '#PLAYER',
    'Player',
    17,
    1,
    0,
    [new WarAttackSnapshot('#PLAYER', '#FRIENDLY', 2, 88, 1, 120, friendlyTarget, null)],
    [],
  ),
);
const stats = new PlayerWarStats(
  'Player',
  '#PLAYER',
  17,
  { start: 0, end: 0 },
  { random: typeStats, cwl: typeStats, friendly: typeStats, all: typeStats },
  [war],
);
const player = Player.fromJson({ tag: '#PLAYER', name: 'Player', townHallLevel: 17 });
const statsWithFriendlyWar = new PlayerWarStats(
  'Player',
  '#PLAYER',
  17,
  { start: 0, end: 0 },
  { random: typeStats, cwl: typeStats, friendly: typeStats, all: typeStats },
  [war, friendlyWar],
);

const wrap = (child: React.ReactElement) =>
  render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 0, right: 0, bottom: 0, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">{child}</CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );

describe('player war presentation parity', () => {
  it('renders the expanded all-TH section and collapsed defender-TH sections', async () => {
    const screen = await wrap(<PlayerWarTab data={stats} player={player} actions={{} as never} />);
    expect(screen.getByTestId('war-stats-all').props.accessibilityState.expanded).toBe(true);
    expect(screen.getByTestId('war-stats-th-16').props.accessibilityState.expanded).toBe(false);
    await fireEvent.press(screen.getByTestId('war-stats-th-16'));
    await waitFor(() => expect(screen.getAllByText(/3\.00/).length).toBeGreaterThan(0));
    expect(screen.getByText('Town Hall 16')).toBeTruthy();
    await fireEvent.press(screen.getByRole('radio', { name: 'Charts' }));
    await waitFor(() => expect(screen.getByTestId('war-chart-guide')).toBeTruthy());
    expect(screen.getByTestId('war-chart-scale')).toBeTruthy();
    expect(screen.getAllByText(/Poor/)).toHaveLength(2);
    expect(screen.getByTestId('war-heatmap-attack-17vs16')).toBeTruthy();
    expect(screen.getByTestId('war-heatmap-defense-16vs17')).toBeTruthy();
  });

  it('renders the performance row and complete Flutter-equivalent detail sections', async () => {
    const openPlayer = jest.fn();
    const screen = await wrap(
      <PlayerWarTab data={stats} player={player} actions={{ openPlayer } as never} />,
    );
    await fireEvent.press(screen.getByRole('radio', { name: 'Attacks' }));
    await waitFor(() => expect(screen.getByTestId('war-attack-summary')).toBeTruthy());
    expect(screen.getByText('4. Defender')).toBeTruthy();
    await fireEvent.press(screen.getByRole('button', { name: /4\. Defender/ }));
    expect(openPlayer).toHaveBeenCalledWith('#TARGET');
    await fireEvent.press(screen.getByRole('button', { name: 'Attack Details' }));
    await waitFor(() => expect(screen.getByText('War ended')).toBeTruthy());
    expect(screen.getByText('Team size')).toBeTruthy();
    expect(screen.getByText('15')).toBeTruthy();
    expect(screen.getByText('Attacks Per Member')).toBeTruthy();
    expect(screen.getByText('Alpha')).toBeTruthy();
    expect(screen.getByText('Bravo')).toBeTruthy();
    expect(screen.getByText('Players')).toBeTruthy();
    expect(screen.getByText('Attacker')).toBeTruthy();
    expect(screen.getAllByText('Defender', { exact: true }).length).toBeGreaterThan(0);
  });

  it('shows localized feedback when player navigation fails', async () => {
    const showMessage = jest.fn();
    const screen = await wrap(
      <PlayerWarTab
        data={stats}
        player={player}
        actions={
          {
            openPlayer: jest.fn(async () => {
              throw new Error('network');
            }),
            showMessage,
          } as never
        }
      />,
    );
    await fireEvent.press(screen.getByRole('radio', { name: 'Attacks' }));
    await fireEvent.press(screen.getByRole('button', { name: /4\. Defender/ }));
    await waitFor(() => expect(showMessage).toHaveBeenCalledWith('Failed to load player data'));
  });

  it('applies quick war-type choices to attack history rows', async () => {
    const screen = await wrap(
      <PlayerWarTab
        data={statsWithFriendlyWar}
        player={player}
        actions={{ openPlayer: jest.fn() } as never}
      />,
    );
    await fireEvent.press(screen.getByRole('radio', { name: 'Attacks' }));
    expect(screen.getByText('7. Friendly Defender')).toBeTruthy();
    await fireEvent.press(screen.getByRole('button', { name: 'Quick Filters' }));
    await fireEvent.press(screen.getByRole('checkbox', { name: 'Friendly' }));
    await waitFor(() => expect(screen.queryByText('7. Friendly Defender')).toBeNull());
    expect(screen.getByText('4. Defender')).toBeTruthy();
  });

  it('maps right swipes to player navigation and left swipes to details', () => {
    expect(warAttackSwipeAction(80)).toBe('player');
    expect(warAttackSwipeAction(-80)).toBe('details');
    expect(warAttackSwipeAction(40)).toBeNull();
  });

  it('retains rendered stats while an advanced filter is loading', async () => {
    const screen = await wrap(
      <PlayerWarTab data={stats} player={player} loading actions={{} as never} />,
    );
    expect(screen.getByTestId('war-filter-loading')).toBeTruthy();
    expect(screen.getByTestId('war-stats-all')).toBeTruthy();
  });

  it('keeps export confirmation open with the generated path and Open action', async () => {
    const exportWarStats = jest.fn(async () => '/documents/player.xlsx');
    const open = jest.spyOn(Linking, 'openURL').mockResolvedValueOnce(undefined);
    const screen = await wrap(
      <PlayerWarTab
        data={stats}
        player={player}
        actions={{ exportWarStats, showMessage: jest.fn() } as never}
      />,
    );
    await fireEvent.press(screen.getByRole('button', { name: 'Export' }));
    await fireEvent.press(screen.getAllByRole('button', { name: 'Export' }).at(-1)!);
    await waitFor(() => expect(screen.getByText('/documents/player.xlsx')).toBeTruthy());
    await fireEvent.press(screen.getByRole('button', { name: 'Open' }));
    expect(open).toHaveBeenCalledWith('file:///documents/player.xlsx');
    open.mockRestore();
  });
});
