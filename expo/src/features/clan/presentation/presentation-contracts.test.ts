import { BookmarkedClan } from '../../../core/bookmarks/bookmark-service';
import type { Player } from '../../player/models/player';
import type { Clan } from '../models';
import { buildClanRoster, clanMemberCapacityLabel, type ClansPresentationModel } from './contracts';

const clan = (tag: string, name: string): Clan =>
  ({
    tag,
    name,
    badgeUrls: { small: '', medium: '', large: `${tag}.png` },
    members: 42,
    warLeague: { name: 'Champion League I' },
    clanPoints: 50_000,
    location: { countryCode: 'US', name: 'United States' },
    type: 'inviteOnly',
  }) as Clan;

const player = (tag: string, clanTag: string, linkedClan: Clan): Player =>
  ({ tag, clanTag, clan: linkedClan }) as Player;

describe('clan roster contracts', () => {
  it('preserves first linked-tag position, latest clan value, and bookmark order', () => {
    const first = clan('#ONE', 'Old One');
    const second = clan('#TWO', 'Two');
    const latest = clan('#ONE', 'Latest One');
    const hydrated = clan('#BOOK', 'Hydrated Bookmark');
    const model: ClansPresentationModel = {
      profiles: [
        player('#P1', '#ONE', first),
        player('#P2', '#TWO', second),
        player('#P3', '#ONE', latest),
      ],
      bookmarks: [
        new BookmarkedClan('#ONE', 'Duplicate', '', 0, 0),
        new BookmarkedClan('#BOOK', 'Stored', 'stored.png', 10, 25),
        new BookmarkedClan('#MISSING', 'Missing', 'missing.png', 8, 15),
      ],
      hydratedClans: [hydrated],
    };

    const roster = buildClanRoster(model);
    expect(roster.items.map((item) => item.tag)).toEqual(['#ONE', '#TWO', '#BOOK', '#MISSING']);
    expect(roster.items[0]).toMatchObject({ name: 'Latest One', accountCount: 2 });
    expect(roster.items[2]).toMatchObject({ name: 'Hydrated Bookmark', bookmarked: true });
    expect(roster.missingBookmarkTags).toEqual(['#MISSING']);
  });

  it('matches the fixed Clash clan capacity label', () => {
    expect(clanMemberCapacityLabel(47)).toBe('47/50');
  });
});
