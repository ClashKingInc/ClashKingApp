import { BookmarkedClan, BookmarkedPlayer } from '../../core/bookmarks';
import { AccountBootstrapService } from './account-bootstrap-service';

function harness(options: { noAccounts?: boolean; bookmarkError?: unknown } = {}) {
  const calls: string[] = [];
  const linkedAccounts = options.noAccounts ? [] : [{ playerTag: '#P', isVerified: true, raw: {} }];
  const accounts = {
    accounts: linkedAccounts,
    selectedTag: '#P',
    setCurrentUserId: (id: string | null) => calls.push(`account-user:${id}`),
    loadSelectedTag: async () => calls.push('selected-load'),
    fetchAccounts: async () => {
      calls.push('accounts-fetch');
      return linkedAccounts;
    },
    initializeSelectedTag: async () => calls.push('selected-init'),
    updateRefreshTime: () => calls.push('refresh-time'),
  };
  const bookmarks = {
    loaded: false,
    players: [new BookmarkedPlayer('#BP', '#BP', 0, '', '', '', 0, '', '')],
    clans: [new BookmarkedClan('#BC', '#BC', '', 0, 0)],
    setCurrentUserId: (id: string | null) => calls.push(`bookmark-user:${id}`),
    load: async () => {
      calls.push('bookmarks-load');
      if (options.bookmarkError) throw options.bookmarkError;
    },
  };
  const clansByTag = new Map<string, { tag: string }>();
  const players = {
    profiles: [{ tag: '#P', clanTag: '#DISCOVERED' }],
    hydrateBookmarkedPlayers: async (tags: readonly string[]) =>
      calls.push(`bookmarked-players:${tags.join(',')}`),
    prefetchRankedLeagueData: async (_tags: readonly string[], force = false) =>
      calls.push(`ranked:${force}`),
    loadOfficialPlayerData: async () => {
      calls.push('players');
      return { '#P': '#DISCOVERED' };
    },
    linkClansToPlayer: () => calls.push('link-players'),
    notifyDataChanged: () => calls.push('notify-players'),
    clearRankedLeagueCache: () => calls.push('ranked-clear'),
  };
  let playerCardPreferencesLoaded = false;
  const playerCardPreferences = {
    get loaded() {
      return playerCardPreferencesLoaded;
    },
    load: async () => {
      calls.push('card-preferences-load');
      playerCardPreferencesLoaded = true;
    },
    clear: () => calls.push('card-preferences-clear'),
  };
  const upgrades = {
    configureRemote: () => calls.push('upgrades-configure'),
    clearCache: () => calls.push('upgrades-clear'),
    load: async (_tag: string, force = false) => {
      calls.push(`upgrade:${force}`);
      return null;
    },
  };
  const upgradeWidgets = {
    clear: async () => calls.push('upgrade-widgets-clear'),
    sync: async () => calls.push('upgrade-widgets-sync'),
  };
  const clans = {
    clans: clansByTag,
    loadAllClanData: async (tags: readonly string[]) => {
      calls.push(`clans:${tags.join(',')}`);
      for (const tag of tags) clansByTag.set(tag, { tag });
    },
    linkWarsToClans: () => calls.push('link-wars'),
    notifyDataChanged: () => calls.push('notify-clans'),
  };
  const wars = {
    summaries: new Map<string, { tag: string }>(),
    loadAllWarData: async (tags: readonly string[]) => {
      calls.push(`wars:${tags.join(',')}`);
    },
    notifyDataChanged: () => calls.push('notify-wars'),
  };
  const storage = {
    getString: async () => '#CACHED',
    setString: async () => undefined,
    remove: async () => undefined,
  };
  const warWidgets = {
    seedClanOptionsFromProfiles: async () => calls.push('widgets'),
  };
  const service = new AccountBootstrapService({
    accounts: accounts as never,
    bookmarks: bookmarks as never,
    players: players as never,
    playerCardPreferences: playerCardPreferences as never,
    upgrades: upgrades as never,
    upgradeWidgets: upgradeWidgets as never,
    clans: clans as never,
    wars: wars as never,
    storage,
    warWidgets: warWidgets as never,
  });
  return { service, calls };
}

describe('AccountBootstrapService', () => {
  test('hydrates bookmarks, accounts, cached and discovered clans, wars, links, and selection', async () => {
    const { service, calls } = harness();
    await service.initialize('user');
    await Promise.resolve();

    expect(calls.slice(0, 5)).toEqual([
      'account-user:user',
      'bookmark-user:user',
      'selected-load',
      'bookmarks-load',
      'card-preferences-load',
    ]);
    expect(calls).toEqual(
      expect.arrayContaining([
        'accounts-fetch',
        'bookmarked-players:#BP',
        'clans:#CACHED,#BC',
        'wars:#CACHED,#BC',
        'players',
        'clans:#DISCOVERED',
        'wars:#DISCOVERED',
        'link-players',
        'link-wars',
        'notify-players',
        'notify-clans',
        'notify-wars',
        'refresh-time',
        'selected-init',
        'widgets',
      ]),
    );
  });

  test('preserves Flutter early return when the user has no account links', async () => {
    const { service, calls } = harness({ noAccounts: true });
    await service.initialize('user');
    await Promise.resolve();
    expect(calls).toContain('accounts-fetch');
    expect(calls).toContain('bookmarked-players:#BP');
    expect(calls).not.toContain('selected-init');
    expect(calls).not.toContain('players');
    expect(calls).toContain('widgets');
  });

  test('bookmark loading remains startup-critical and blocks linked hydration on failure', async () => {
    const failure = new Error('bookmark network');
    const { service, calls } = harness({ bookmarkError: failure });
    await expect(service.initialize('user')).rejects.toBe(failure);
    expect(calls).not.toContain('accounts-fetch');
  });

  test('loads player card preferences once across repeated authenticated bootstrap', async () => {
    const { service, calls } = harness({ noAccounts: true });
    await service.initialize('user');
    await service.initialize('user');
    expect(calls.filter((call) => call === 'card-preferences-load')).toHaveLength(1);
  });

  test('anonymous bootstrap clears card, ranked, upgrade, and widget session state', async () => {
    const { service, calls } = harness({ noAccounts: true });
    await service.initialize(null);
    expect(calls).toEqual(
      expect.arrayContaining([
        'card-preferences-clear',
        'ranked-clear',
        'upgrades-clear',
        'upgrade-widgets-clear',
      ]),
    );
    expect(calls).not.toContain('card-preferences-load');
  });

  test('manual refresh keeps links stable and awaits forced ranked and upgrade data', async () => {
    const { service, calls } = harness();
    await service.refresh();

    expect(calls).not.toContain('accounts-fetch');
    expect(calls).toEqual(
      expect.arrayContaining([
        'ranked:true',
        'upgrade:true',
        'upgrade-widgets-sync',
        'refresh-time',
      ]),
    );
    expect(calls.indexOf('refresh-time')).toBeGreaterThan(calls.indexOf('upgrade-widgets-sync'));
  });
});
