import {
  ClanLeaderboardHistoryEntry,
  ClanLeaderboardSeasonSummary,
  ClanLeaderboardType,
  ClanProfileChange,
} from '../models';
import {
  capitalBucketLabel,
  descriptionTextDiff,
  leaderboardEntryKey,
  profileChangeKey,
} from './clan-history-tabs';

describe('clan history parity helpers', () => {
  it('keeps duplicate-date leaderboard rows and duplicate profile changes keyed independently', () => {
    const entry = new ClanLeaderboardHistoryEntry(
      new Date('2026-08-01T00:00:00.000Z'),
      12,
      50_000,
      48,
      null,
    );
    expect(leaderboardEntryKey(entry, 0, ClanLeaderboardType.homeVillage)).not.toBe(
      leaderboardEntryKey(entry, 1, ClanLeaderboardType.homeVillage),
    );

    const change = new ClanProfileChange(
      new Date('2026-08-01T00:00:00.000Z'),
      'description',
      'Old',
      'New',
    );
    expect(profileChangeKey(change, 0)).not.toBe(profileChangeKey(change, 1));
  });

  it('labels six-season capital buckets as the full localized date range', () => {
    const seasons = Array.from({ length: 6 }, (_, index) => {
      const month = index + 1;
      return new ClanLeaderboardSeasonSummary(
        `2026-${String(month).padStart(2, '0')}`,
        new Date(2026, index, 1),
        new Date(2026, index + 1, 0),
        1,
        1,
        1,
      );
    });

    expect(capitalBucketLabel(seasons, 0, 'en_GB')).toBe('1 Jan 2026 – 30 Jun 2026');
  });

  it('matches Flutter shared-prefix/shared-suffix description diffing', () => {
    expect(
      descriptionTextDiff('First line\nOld rule\nKeep this', 'First line\nNew rule\nKeep this'),
    ).toEqual({
      prefix: 'First line\n',
      removed: 'Old',
      added: 'New',
      suffix: ' rule\nKeep this',
    });
  });

  it('keeps insertion and deletion bodies between the shared edges', () => {
    expect(
      descriptionTextDiff('Alpha\nRemove me\nOmega', 'Alpha\nAdd one\nAdd two\nOmega'),
    ).toEqual({
      prefix: 'Alpha\n',
      removed: 'Remove me',
      added: 'Add one\nAdd two',
      suffix: '\nOmega',
    });
  });
});
