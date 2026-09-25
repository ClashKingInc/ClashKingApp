import { BookmarkedClan, BookmarkedPlayer } from '../../../core/bookmarks/bookmark-service';
import { ClanBadgeUrls, type Clan } from '../../clan/models';
import type { Player } from '../../player/models/player';
import { WarClan, WarCwl, WarInfo, WarMember } from '../models';
import { buildWarRoster, type WarPresentationModel } from './contracts';

const badge = new ClanBadgeUrls('small', 'medium', 'large');
const member = new WarMember('#P1', 'Main', 17, 1, 0, [], null);
const clanSide = new WarClan('#CLAN', 'Linked Clan', badge, 20, 0, 0, 0, [member]);
const enemySide = new WarClan('#ENEMY', 'Enemy', badge, 20, 0, 0, 0, []);
const activeWar = new WarInfo(
  'inWar',
  '#WAR',
  15,
  2,
  clanSide,
  enemySide,
  new Date(),
  new Date(),
  new Date(),
  'random',
);

const linkedClan = {
  tag: '#CLAN',
  name: 'Linked Clan',
  badgeUrls: badge,
  warLeague: { name: 'Champion League I' },
} as Clan;

describe('war presentation roster', () => {
  it('uses linked account and direct clan bookmark order across the two tabs', () => {
    const first = { tag: '#P1', name: 'First', clanTag: '#CLAN', clan: linkedClan } as Player;
    const secondClan = { ...linkedClan, tag: '#SECOND', name: 'Second Clan' } as Clan;
    const second = { tag: '#P2', name: 'Second', clanTag: '#SECOND', clan: secondClan } as Player;
    const roster = buildWarRoster({
      profiles: [first, second],
      ownedPlayerTags: ['#P2', '#P1'],
      bookmarkedPlayers: [],
      bookmarkedClans: [
        new BookmarkedClan('#BOOK2', 'Second bookmark', '', 1, 1),
        new BookmarkedClan('#BOOK1', 'First bookmark', '', 1, 1),
      ],
      hydratedBookmarkedClans: [],
      summaries: new Map(),
    });
    expect(roster.items.map((item) => item.tag)).toEqual(['#SECOND', '#CLAN', '#BOOK2', '#BOOK1']);
  });
  it('keeps hydrated bookmarked profiles out of linked clans and preserves Flutter sort priority', () => {
    const linked = { tag: '#P1', name: 'Main', clanTag: '#CLAN', clan: linkedClan } as Player;
    const hydratedBookmark = {
      tag: '#PB',
      name: 'Scout',
      clanTag: '#BOOK',
      clan: { ...linkedClan, tag: '#BOOK', name: 'Book Clan' },
    } as Player;
    const model: WarPresentationModel = {
      profiles: [linked, hydratedBookmark],
      ownedPlayerTags: ['#P1'],
      bookmarkedPlayers: [
        new BookmarkedPlayer('#PB', 'Scout', 16, '', '#BOOK', 'Book Clan', 0, '', ''),
      ],
      bookmarkedClans: [new BookmarkedClan('#EMPTY', 'Empty Bookmark', '', 1, 1)],
      hydratedBookmarkedClans: [],
      summaries: new Map([['#CLAN', new WarCwl('#CLAN', true, false, activeWar, null, [])]]),
    };

    const roster = buildWarRoster(model);
    expect(roster.items.map((item) => item.tag)).toEqual(['#CLAN', '#EMPTY']);
    expect(roster.items[0]).toMatchObject({
      sortWeight: 0,
      bookmarked: false,
      badgeUrl: 'https://badges.clashk.ing/CLAN.avif',
      accounts: [{ tag: '#P1', name: 'Main', bookmarked: false }],
    });
    expect(roster.items[1]).toMatchObject({ bookmarked: true, name: 'Empty Bookmark', accounts: [] });
    expect(roster.missingWarClanTags).toEqual(['#EMPTY']);
    expect(roster.missingBookmarkedPlayerTags).toEqual([]);
  });

  it('honors the per-player War-tab visibility contract', () => {
    const model: WarPresentationModel = {
      profiles: [{ tag: '#P1', name: 'Main', clanTag: '#CLAN', clan: linkedClan } as Player],
      ownedPlayerTags: ['#P1'],
      bookmarkedPlayers: [],
      bookmarkedClans: [],
      hydratedBookmarkedClans: [],
      summaries: new Map(),
      hiddenPlayerTags: new Set(['P1']),
    };
    expect(buildWarRoster(model).items).toEqual([]);
  });
});
