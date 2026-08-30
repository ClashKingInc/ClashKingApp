import { fireEvent, render } from '@testing-library/react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { ClanBadgeUrls, type Clan } from '../../clan/models';
import type { Player } from '../../player/models/player';
import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import {
  CwlClan,
  CwlLeague,
  CwlLeagueRound,
  WarAttack,
  WarClan,
  WarCwl,
  WarInfo,
  WarMember,
} from '../models';
import type { WarPresentationActions, WarPresentationModel } from './contracts';
import { CwlScreen } from './cwl-screen';
import { WarCwlPresentationRoot } from './war-cwl-screen';

const badge = new ClanBadgeUrls('', '', 'badge.png');
const attack = new WarAttack('#P1', '#E1', 3, 100, 1, 135);
const playerMember = new WarMember('#P1', 'Main', 17, 1, 0, [attack], null);
const enemyMember = new WarMember('#E1', 'Enemy One', 17, 1, 1, [], attack);
const war = new WarInfo(
  'inWar',
  '#WAR',
  1,
  2,
  new WarClan('#CLAN', 'Linked Clan', badge, 20, 1, 3, 100, [playerMember]),
  new WarClan('#ENEMY', 'Enemy Clan', badge, 20, 0, 0, 0, [enemyMember]),
  new Date(),
  new Date(),
  new Date(),
  'random',
);
const clan = {
  tag: '#CLAN',
  name: 'Linked Clan',
  badgeUrls: badge,
  warLeague: { name: 'Champion League I' },
} as Clan;
const model: WarPresentationModel = {
  profiles: [{ tag: '#P1', name: 'Main', clanTag: '#CLAN', clan } as Player],
  ownedPlayerTags: ['#P1'],
  bookmarkedPlayers: [],
  bookmarkedClans: [],
  hydratedBookmarkedClans: [],
  summaries: new Map([['#CLAN', new WarCwl('#CLAN', true, false, war, null, [])]]),
};
const actions: WarPresentationActions = {
  refresh: jest.fn(async () => undefined),
  hydrateBookmarkedPlayers: jest.fn(async () => undefined),
  loadWarSummaries: jest.fn(async () => undefined),
  isNetworkError: jest.fn(() => false),
  openNetworkError: jest.fn(),
  showMessage: jest.fn(),
  openClan: jest.fn(),
  openPlayer: jest.fn(),
  copyText: jest.fn(async () => undefined),
};

function renderRoot() {
  return render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <WarCwlPresentationRoot model={model} actions={actions} />
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );
}

describe('WarCwlPresentationRoot', () => {
  it('shows one clean Flutter message for a clan that is not in war', async () => {
    const inactiveModel: WarPresentationModel = {
      ...model,
      summaries: new Map([
        ['#CLAN', new WarCwl('#CLAN', true, false, new WarInfo('notInWar'), null, [])],
      ]),
    };
    const screen = await render(
      <SafeAreaProvider
        initialMetrics={{
          frame: { x: 0, y: 0, width: 390, height: 844 },
          insets: { top: 47, right: 0, bottom: 34, left: 0 },
        }}
      >
        <I18nProvider locale="en">
          <CKThemeProvider preference="light">
            <WarCwlPresentationRoot model={inactiveModel} actions={actions} />
          </CKThemeProvider>
        </I18nProvider>
      </SafeAreaProvider>,
    );

    expect(screen.getByText('Linked Clan is not in war.')).toBeTruthy();
    expect(screen.queryByText('Linked Clan')).toBeNull();
    expect(screen.queryByText('Contact the leader or a co-leader to start a war.')).toBeNull();
  });

  it('opens the full war detail, switches tabs, and opens an attack sheet', async () => {
    const screen = await renderRoot();
    await fireEvent.press(screen.getByRole('button', { name: 'Linked Clan versus Enemy Clan' }));
    expect(screen.getAllByText('Statistics')).toHaveLength(2);
    await fireEvent.press(screen.getByRole('tab', { name: 'Events' }));
    await fireEvent.press(screen.getByRole('button', { name: 'Main 3 stars' }));
    expect(screen.getByText('Attack Details')).toBeTruthy();
    expect(screen.getByText('random')).toBeTruthy();
    expect(screen.getByText('Destruction')).toBeTruthy();
    expect(screen.getByText('2m 15s')).toBeTruthy();
  });

  it('allows the preparation countdown to wrap without truncating it', async () => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2026-08-30T15:00:00.000Z'));
    const preparation = new WarInfo(
      'preparation',
      '#PREP',
      15,
      2,
      new WarClan('#CLAN', 'Linked Clan', badge, 20, 0, 0, 0, [playerMember]),
      new WarClan('#ENEMY', 'Enemy Clan', badge, 20, 0, 0, 0, [enemyMember]),
      new Date('2026-08-30T18:05:00.000Z'),
      new Date('2026-08-31T18:05:00.000Z'),
      new Date('2026-08-29T15:00:00.000Z'),
      'random',
    );
    const preparationModel: WarPresentationModel = {
      ...model,
      summaries: new Map([['#CLAN', new WarCwl('#CLAN', true, false, preparation, null, [])]]),
    };
    const screen = await render(
      <SafeAreaProvider
        initialMetrics={{
          frame: { x: 0, y: 0, width: 390, height: 844 },
          insets: { top: 47, right: 0, bottom: 34, left: 0 },
        }}
      >
        <I18nProvider locale="en">
          <CKThemeProvider preference="light">
            <WarCwlPresentationRoot model={preparationModel} actions={actions} />
          </CKThemeProvider>
        </I18nProvider>
      </SafeAreaProvider>,
    );

    const label = screen.getByTestId('war-summary-state-label');
    expect(label.props.numberOfLines).toBe(2);
    expect(screen.getByText('Preparation\nStarts in 3h 5m')).toBeTruthy();
    jest.useRealTimers();
  });

  it('shows only the remaining time for an ongoing war', async () => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2026-08-30T15:00:00.000Z'));
    const ongoing = new WarInfo(
      'inWar',
      '#ONGOING',
      15,
      2,
      new WarClan('#CLAN', 'Linked Clan', badge, 20, 0, 39, 28.89, [playerMember]),
      new WarClan('#ENEMY', 'Enemy Clan', badge, 20, 0, 39, 28.89, [enemyMember]),
      new Date('2026-08-29T14:45:00.000Z'),
      new Date('2026-08-31T14:15:00.000Z'),
      new Date('2026-08-28T14:45:00.000Z'),
      'random',
    );
    const ongoingModel: WarPresentationModel = {
      ...model,
      summaries: new Map([['#CLAN', new WarCwl('#CLAN', true, false, ongoing, null, [])]]),
    };
    const screen = await render(
      <SafeAreaProvider
        initialMetrics={{
          frame: { x: 0, y: 0, width: 390, height: 844 },
          insets: { top: 47, right: 0, bottom: 34, left: 0 },
        }}
      >
        <I18nProvider locale="en">
          <CKThemeProvider preference="light">
            <WarCwlPresentationRoot model={ongoingModel} actions={actions} />
          </CKThemeProvider>
        </I18nProvider>
      </SafeAreaProvider>,
    );

    expect(screen.getByText('Ends in 23h 15m')).toBeTruthy();
    expect(screen.queryByText(/Ongoing war/)).toBeNull();
    jest.useRealTimers();
  });

  it('shows Flutter-equivalent CWL round timing, attack counts, and perfect-war state', async () => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2026-08-30T15:00:00.000Z'));
    const cwlClan = new CwlClan('#CLAN', 'Linked Clan', badge, 20, 1, 3, 100, 100, [], 1, 1, {});
    const enemyClan = new CwlClan('#ENEMY', 'Enemy Clan', badge, 20, 0, 3, 100, 100, [], 2, 1, {});
    const ended = new WarInfo(
      'warEnded',
      '#CWLWAR',
      1,
      1,
      new WarClan('#CLAN', 'Linked Clan', badge, 20, 1, 3, 100, [playerMember]),
      new WarClan('#ENEMY', 'Enemy Clan', badge, 20, 0, 3, 100, [enemyMember]),
      null,
      new Date('2026-08-30T13:30:00.000Z'),
      null,
      'cwl',
    );
    const summary = new WarCwl(
      '#CLAN',
      false,
      true,
      new WarInfo('notInWar'),
      new CwlLeague('ended', '2026-08', [cwlClan, enemyClan], [new CwlLeagueRound(1, ['#CWLWAR'])]),
      [ended],
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
            <CwlScreen
              clanTag="#CLAN"
              summary={summary}
              actions={actions}
              onBack={jest.fn()}
              onOpenWar={jest.fn()}
            />
          </CKThemeProvider>
        </I18nProvider>
      </SafeAreaProvider>,
    );

    expect(screen.getByText('Ended 1 hours ago')).toBeTruthy();
    expect(screen.getAllByText('1/1').length).toBeGreaterThanOrEqual(1);
    expect(screen.getByText('0/1')).toBeTruthy();
    expect(screen.getAllByText('Perfect war')).toHaveLength(2);
    jest.useRealTimers();
  });
});
