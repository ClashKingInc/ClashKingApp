import { act, render, waitFor } from '@testing-library/react-native';

import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import { PlayerClanOverview, RankedLeagueData, type Player } from '../../player/models';
import type { RankedScreenProps } from './ranked-screen';
import { RankedRoot } from './ranked-root';

let mockRuntime: ReturnType<typeof runtimeFixture>;
let mockScreenProps: RankedScreenProps;

jest.mock('../../../core/app/runtime-context', () => ({
  useAppRuntime: () => mockRuntime,
}));

jest.mock('./ranked-screen', () => ({
  RankedScreen: (props: RankedScreenProps) => {
    mockScreenProps = props;
    return null;
  },
}));

function deferred<T>() {
  let resolve!: (value: T) => void;
  const promise = new Promise<T>((next) => {
    resolve = next;
  });
  return { promise, resolve };
}

const player = {
  name: 'Alpha',
  tag: '#ALPHA',
  townHallLevel: 18,
  townHallPic: 'town-hall.png',
  clanOverview: PlayerClanOverview.empty(),
} as Player;

function rankedData(trophies: number) {
  return new RankedLeagueData('#ALPHA', 'Alpha', 18, trophies, trophies, null, new Map(), []);
}

function runtimeFixture() {
  return {
    accounts: {
      subscribe: jest.fn(() => jest.fn()),
      verifiedAccounts: [] as { playerTag: string }[],
      accounts: [],
    },
    players: {
      subscribe: jest.fn(() => jest.fn()),
      profiles: [] as Player[],
      loadRankedLeagueData: jest.fn(),
      getPlayerAndClanData: jest.fn(),
    },
    bookmarks: {
      subscribe: jest.fn(() => jest.fn()),
      isPlayerBookmarked: jest.fn(() => false),
      togglePlayer: jest.fn(),
    },
    playerCardPreferences: {
      subscribe: jest.fn(() => jest.fn()),
      isRankedShownOnHome: jest.fn((_tag: string) => true),
    },
  };
}

describe('RankedRoot refresh presentation', () => {
  it('revalidates warmed data without showing pull-to-refresh state', async () => {
    const cached = deferred<RankedLeagueData>();
    const fresh = deferred<RankedLeagueData>();
    mockRuntime = runtimeFixture();
    mockRuntime.players.loadRankedLeagueData.mockImplementation(
      (_tag: string, forceRefresh: boolean) => (forceRefresh ? fresh.promise : cached.promise),
    );

    await render(
      <I18nProvider locale="en">
        <CKThemeProvider preference="dark">
          <RankedRoot
            player={player}
            onBack={jest.fn()}
            openPlayer={jest.fn()}
            openInGame={jest.fn()}
          />
        </CKThemeProvider>
      </I18nProvider>,
    );

    await act(async () => {
      cached.resolve(rankedData(1200));
      await cached.promise;
    });
    await waitFor(() =>
      expect(mockRuntime.players.loadRankedLeagueData).toHaveBeenCalledWith('#ALPHA', true, true),
    );
    expect(mockScreenProps.data?.trophies).toBe(1200);
    expect(mockScreenProps.loading).toBe(false);
    expect(mockScreenProps.refreshing).toBe(false);

    await act(async () => {
      fresh.resolve(rankedData(1225));
      await fresh.promise;
    });
    await waitFor(() => expect(mockScreenProps.data?.trophies).toBe(1225));
    expect(mockScreenProps.refreshing).toBe(false);
  });

  it('offers only verified accounts enabled for Ranked on Home', async () => {
    const hidden = { ...player, name: 'Hidden', tag: '#HIDDEN' } as Player;
    mockRuntime = runtimeFixture();
    mockRuntime.accounts.verifiedAccounts = [{ playerTag: '#ALPHA' }, { playerTag: '#HIDDEN' }];
    mockRuntime.players.profiles = [player, hidden];
    mockRuntime.playerCardPreferences.isRankedShownOnHome.mockImplementation(
      (tag: string) => tag !== '#HIDDEN',
    );
    mockRuntime.players.loadRankedLeagueData.mockResolvedValue(rankedData(1200));

    await render(
      <I18nProvider locale="en">
        <CKThemeProvider preference="dark">
          <RankedRoot
            player={player}
            allowAccountSwitch
            onBack={jest.fn()}
            openPlayer={jest.fn()}
            openInGame={jest.fn()}
          />
        </CKThemeProvider>
      </I18nProvider>,
    );

    await waitFor(() => expect(mockScreenProps.accounts).toEqual([player]));
  });
});
