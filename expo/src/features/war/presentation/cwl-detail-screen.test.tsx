import { fireEvent, render, within } from '@testing-library/react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import { CwlLeague, WarCwl, WarInfo } from '../models';
import { CwlScreen } from './cwl-screen';
import type { WarPresentationActions } from './contracts';

jest.mock('../../../core/assets/local-asset-cache', () => ({
  localImageCache: {
    subscribe: () => () => {},
    peek: () => undefined,
    resolve: jest.fn(),
    getRevision: () => 0,
  },
}));
const actions = { openClan: jest.fn(), openPlayer: jest.fn() } as unknown as WarPresentationActions;
const clans = [
  {
    tag: '#A',
    name: 'Alpha',
    members: [
      { tag: '#P', name: 'Main', townHallLevel: 18 },
      { tag: '#R', name: 'Reserve', townHallLevel: 16 },
    ],
  },
  { tag: '#B', name: 'Beta', members: [{ tag: '#E', name: 'Enemy', townHallLevel: 17 }] },
];
const wars = ['inWar', 'preparation'].map((state, index) =>
  WarInfo.fromJson({
    state,
    war_tag: `#W${index}`,
    warType: 'cwl',
    teamSize: 1,
    clan: { ...clans[0], members: [{ tag: '#P', name: 'Main', townhallLevel: index ? 17 : 18 }] },
    opponent: { ...clans[1], members: [{ tag: '#E', name: 'Enemy', townhallLevel: 17 }] },
  }),
);
const group = CwlLeague.fromJson({
  state: 'inWar',
  season: '2026-09',
  clans,
  rounds: [{ warTags: ['#W0'] }, { warTags: ['#W1'] }],
});
const summary = new WarCwl('#A', false, true, new WarInfo('notInWar'), group, wars);
async function setup(props: Partial<React.ComponentProps<typeof CwlScreen>> = {}) {
  return render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="en_GB">
        <CKThemeProvider preference="dark">
          <CwlScreen
            summary={summary}
            clanTag="#A"
            actions={actions}
            onBack={jest.fn()}
            onOpenWar={jest.fn()}
            {...props}
          />
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );
}
it('does not fabricate preparation for missing rounds', async () => {
  const missing = new WarCwl('#A', false, true, new WarInfo('notInWar'), group, []);
  const screen = await setup({ summary: missing });
  expect(screen.queryByText('Preparation')).toBeNull();
  expect(screen.getAllByText('No data available.').length).toBeGreaterThan(0);
});
it('hides incomplete tables until detail loading finishes', async () => {
  const screen = await setup({ loading: true });
  expect(screen.getByText('Analyzing war stats...')).toBeTruthy();
  expect(screen.queryByRole('button', { name: 'Alpha · Beta' })).toBeNull();
});
it('retains member searches when moving between tabs', async () => {
  const screen = await setup();
  expect(screen.getByText('September 2026')).toBeTruthy();
  expect(screen.queryByText('September 2026 season')).toBeNull();
  await fireEvent.press(screen.getByRole('tab', { name: 'Players' }));
  const search = screen.getByPlaceholderText('Search players');
  await fireEvent.changeText(search, 'Reserve');
  await fireEvent.press(screen.getByRole('tab', { name: 'Matchups' }));
  await fireEvent.press(screen.getByRole('tab', { name: 'Players' }));
  expect(screen.getByPlaceholderText('Search players').props.value).toBe('Reserve');
  expect(screen.getByText('Reserve')).toBeTruthy();
  expect(screen.queryByText('Main')).toBeNull();
});
it('always shows registered rosters and keeps war lineups with each matchup', async () => {
  const screen = await setup();
  await fireEvent.press(screen.getByRole('tab', { name: 'Clans' }));
  expect(screen.getByLabelText('Town Hall 16: 1')).toBeTruthy();
  expect(screen.getByLabelText('Town Hall 18: 1')).toBeTruthy();
  expect(screen.queryByRole('button', { name: 'Registered roster' })).toBeNull();
  await fireEvent.press(screen.getByRole('tab', { name: 'Matchups' }));
  await fireEvent.press(screen.getByRole('button', { name: 'Town Hall distribution' }));
  expect(screen.getByLabelText('Town Hall 18: Alpha 1, Beta 0')).toBeTruthy();
  expect(screen.queryByLabelText('Town Hall 16: Alpha 1, Beta 0')).toBeNull();
});
it('switches one selected round with arrows and opens the selected matchup', async () => {
  const onOpenWar = jest.fn();
  const screen = await setup({ onOpenWar });
  expect(screen.getByText('Next matchup')).toBeTruthy();
  await fireEvent.press(screen.getByRole('button', { name: 'Next period' }));
  expect(screen.queryByText('Next matchup')).toBeNull();
  await fireEvent.press(screen.getByRole('button', { name: 'Alpha · Beta' }));
  expect(onOpenWar).toHaveBeenCalledWith(expect.objectContaining({ tag: '#W1' }), 2);
  await fireEvent.press(screen.getByRole('button', { name: 'Previous period' }));
  expect(screen.getByText('Next matchup')).toBeTruthy();
});
it('exposes expanded state and an explicit collapse action without a wall of stat tiles', async () => {
  const screen = await setup();
  await fireEvent.press(screen.getByRole('tab', { name: 'Players' }));
  const player = screen.getByRole('button', { name: 'Main' });
  expect(player.props.accessibilityState.expanded).toBe(false);
  await fireEvent.press(player);
  expect(screen.getByRole('button', { name: 'Main' }).props.accessibilityState.expanded).toBe(true);
  expect(screen.getByText('Average stars')).toBeTruthy();
  expect(screen.queryByText('Full Stats')).toBeNull();
  await fireEvent.press(screen.getByRole('button', { name: 'Collapse' }));
  expect(screen.queryByText('Average stars')).toBeNull();
  expect(screen.getByRole('button', { name: 'Main' }).props.accessibilityState.expanded).toBe(
    false,
  );
});

it('shows an ended result for a matchup between two other clans', async () => {
  const other = WarInfo.fromJson({
    state: 'warEnded',
    war_tag: '#OTHER',
    warType: 'cwl',
    teamSize: 1,
    clan: { tag: '#C', name: 'Charlie', stars: 3, destructionPercentage: 100 },
    opponent: { tag: '#D', name: 'Delta', stars: 1, destructionPercentage: 50 },
  });
  const league = CwlLeague.fromJson({
    state: 'inWar',
    season: '2026-09',
    clans,
    rounds: [{ warTags: ['#W0', '#OTHER'] }],
  });
  const complete = new WarCwl('#A', false, true, new WarInfo('notInWar'), league, [
    wars[0]!,
    other,
  ]);
  const screen = await setup({ summary: complete });
  const row = within(screen.getByRole('button', { name: 'Charlie · Delta' }));
  expect(row.getByText('Victory')).toBeTruthy();
  expect(row.queryByText('Ongoing war')).toBeNull();
});
