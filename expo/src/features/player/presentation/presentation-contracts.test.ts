import { createTranslator } from '../../../i18n';
import type { CocAccountLink } from '../../auth/models';
import type { Player } from '../models/player';
import { PlayerCardOptions } from '../models/player-support';
import {
  buildPlayerRosters,
  normalizeRosterTag,
  playerGridColumns,
  resolveRosterSwipeTarget,
  type PlayersPresentationModel,
} from './contracts';
import { formatLastRefresh, formatPlayerActivity, wrapActivityCaption } from './presentation-utils';

const player = (tag: string, name: string) => ({ tag, name }) as Player;
const link = (playerTag: string): CocAccountLink => ({
  playerTag,
  isVerified: true,
  hidden: false,
  raw: {},
});

describe('players presentation contracts', () => {
  it('preserves linked-account order and excludes linked bookmark duplicates', () => {
    const model: PlayersPresentationModel = {
      profiles: [player('#TWO', 'Two'), player('#ONE', 'One')],
      accountLinks: [link('#ONE'), link('#TWO')],
      bookmarks: [
        {
          tag: '#TWO',
          name: 'Duplicate',
          townHallLevel: 17,
          townHallPic: '',
          clanName: '',
          trophies: 0,
          league: '',
          leagueUrl: '',
        },
        {
          tag: '#THREE',
          name: 'Three',
          townHallLevel: 16,
          townHallPic: '',
          clanName: '',
          trophies: 0,
          league: '',
          leagueUrl: '',
        },
      ],
      optionsByTag: { '#ONE': new PlayerCardOptions() },
      notificationsEnabled: true,
      notificationAccountTags: new Set(),
      updatingNotificationTags: new Set(),
      featureFlags: { upgradeTracker: true, rankedLeague: true },
    };
    const rosters = buildPlayerRosters(model);
    expect(rosters.linked.map((entry) => entry.kind === 'linked' && entry.player.tag)).toEqual([
      '#ONE',
      '#TWO',
    ]);
    expect(rosters.bookmarked).toHaveLength(1);
    expect(rosters.missingBookmarkTags).toEqual(['#THREE']);
  });

  it('matches Flutter linked-tag set semantics for duplicates and empty tags', () => {
    const model: PlayersPresentationModel = {
      profiles: [player('#ONE', 'One'), player('', 'Invalid')],
      accountLinks: [link('#ONE'), link(' #one '), link('')],
      bookmarks: [],
      optionsByTag: {},
      notificationsEnabled: false,
      notificationAccountTags: new Set(),
      updatingNotificationTags: new Set(),
      featureFlags: { upgradeTracker: true, rankedLeague: true },
    };

    expect(buildPlayerRosters(model).linked).toHaveLength(1);
  });

  it('keeps grid, normalization, and activity-caption boundaries', () => {
    expect(normalizeRosterTag(' #abc ')).toBe('#ABC');
    expect(playerGridColumns(419)).toBe(1);
    expect(playerGridColumns(852)).toBe(2);
    expect(playerGridColumns(1320)).toBe(3);
    expect(formatPlayerActivity(new Date(0), createTranslator('en'))).toBe(
      'Last active unavailable',
    );
    expect(wrapActivityCaption('18 minutes ago')).toBe('18 minutes\nago');
    expect(
      formatLastRefresh(
        new Date(2026, 7, 27, 14, 5),
        createTranslator('en'),
        'en',
        new Date(2026, 7, 29, 14, 5),
      ),
    ).toBe('Aug 27, 14:05');
  });

  it('projects roster swipes in both text directions', () => {
    expect(
      resolveRosterSwipeTarget({
        startIndex: 0,
        deltaX: 60,
        velocityX: 0,
        segmentWidth: 100,
        isRtl: false,
      }),
    ).toBe(1);
    expect(
      resolveRosterSwipeTarget({
        startIndex: 0,
        deltaX: -60,
        velocityX: 0,
        segmentWidth: 100,
        isRtl: true,
      }),
    ).toBe(1);
  });
});
