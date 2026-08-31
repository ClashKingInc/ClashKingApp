import { fireEvent, render } from '@testing-library/react-native';

import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import type { CocAccountLink } from '../../auth/models';
import { Player } from '../models/player';
import { PlayerCardOptions, PlayerClanOverview } from '../models/player-support';
import type { PlayersPresentationActions } from './contracts';
import { PlayerDataCard } from './player-card';

const player = {
  name: 'Alpha',
  tag: '#ALPHA',
  townHallLevel: 17,
  townHallPic: 'town-hall.png',
  trophies: 5600,
  league: 'Legend League',
  leagueUrl: 'league.png',
  lastOnline: new Date(0),
  clan: null,
  clanOverview: new PlayerClanOverview('#CLAN', 'Clan', 20, {
    small: 'badge.png',
    medium: '',
    large: '',
  }),
} as Player;

const link: CocAccountLink = {
  playerTag: player.tag,
  isVerified: false,
  hidden: false,
  raw: {},
};

const makeActions = (): PlayersPresentationActions => ({
  refresh: jest.fn(async () => undefined),
  showMessage: jest.fn(),
  openManageAccounts: jest.fn(),
  openPlayer: jest.fn(),
  hydrateBookmarkedPlayers: jest.fn(async () => undefined),
  loadBookmarkedPlayer: jest.fn(async () => player),
  verifyAccount: jest.fn(async () => ({ success: true, message: null })),
  refreshAccounts: jest.fn(async () => undefined),
  openGameSettings: jest.fn(),
  setAccountNotifications: jest.fn(async () => undefined),
  setAccountHidden: jest.fn(async () => undefined),
  setCardOption: jest.fn(async () => undefined),
});

describe('PlayerDataCard options', () => {
  it('keeps Flutter option order, verification rules, and feature gates', async () => {
    const actions = makeActions();
    const onVerify = jest.fn();
    const screen = await render(
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <PlayerDataCard
            player={player}
            link={link}
            options={new PlayerCardOptions()}
            featureFlags={{ upgradeTracker: false, rankedLeague: false }}
            notificationsEnabled
            notificationActive={false}
            notificationUpdating={false}
            actions={actions}
            onVerify={onVerify}
          />
        </CKThemeProvider>
      </I18nProvider>,
    );

    expect(screen.getByText('Clan')).toBeTruthy();

    await fireEvent.press(screen.getByRole('button', { name: 'Options' }));

    expect(
      screen.getAllByRole('switch').map((control) => control.props.accessibilityLabel),
    ).toEqual([
      'Notifications',
      'Show on to-do page',
      'Show Upgrade Tracker on Home',
      'Show Ranked on Home',
      'Show in War tab',
      'Hide account',
    ]);
    expect(screen.getByRole('switch', { name: 'Notifications' }).props.accessibilityState).toEqual({
      checked: false,
      disabled: true,
    });

    await fireEvent.press(screen.getByRole('switch', { name: 'Show in War tab' }));
    expect(actions.setCardOption).toHaveBeenCalledWith('#ALPHA', 'war', false);
    await fireEvent.press(
      screen.getAllByRole('button', { name: 'Link or verify account' }).at(-1)!,
    );
    expect(onVerify).toHaveBeenCalledTimes(1);
  });

  it('keeps the parsed API clan name visible before a full clan object is linked', async () => {
    const parsed = Player.fromJson({
      name: 'Parsed Player',
      tag: '#PARSED',
      townHallLevel: 17,
      trophies: 5000,
      clan: {
        tag: '#PARSEDCLAN',
        name: 'Parsed Clan',
        badgeUrls: { small: 'parsed-badge.png' },
      },
    });
    const screen = await render(
      <I18nProvider locale="en">
        <CKThemeProvider preference="dark">
          <PlayerDataCard
            player={parsed}
            bookmarked
            options={new PlayerCardOptions()}
            featureFlags={{ upgradeTracker: false, rankedLeague: false }}
            notificationsEnabled={false}
            notificationActive={false}
            notificationUpdating={false}
            actions={makeActions()}
            onVerify={jest.fn()}
          />
        </CKThemeProvider>
      </I18nProvider>,
    );

    expect(screen.getByText('Parsed Clan')).toBeTruthy();
  });
});
