import { ImageAssets } from '../../../core/assets/image-assets';
import { RankingBoard, RankingEntry, RankingLocation } from './ranking-models';

describe('ranking models', () => {
  test('keeps regions distinct from synthetic Worldwide and validates country codes', () => {
    const europe = RankingLocation.fromJson({ id: 32000000, name: 'Europe', isCountry: false });
    const unitedStates = RankingLocation.fromJson({
      id: 32000006,
      name: 'United States',
      isCountry: true,
      countryCode: 'us',
    });

    expect(europe.apiPath).toBe('32000000');
    expect(europe.isWorldwide).toBe(false);
    expect(europe.hasValidCountryCode).toBe(false);
    expect(RankingLocation.worldwide().apiPath).toBe('global');
    expect(unitedStates.countryCode).toBe('US');
    expect(unitedStates.hasValidCountryCode).toBe(true);
  });

  test('decodes official Home Village fields and replaces the supplied clan badge', () => {
    const entry = RankingEntry.fromJson(
      {
        tag: '#PLAYER',
        name: 'Player One',
        rank: 2,
        previousRank: 8,
        trophies: 6012,
        clan: {
          tag: '#CLAN',
          name: 'Clan One',
          badgeUrls: { small: 'small-badge.png', medium: 'medium-badge.png' },
        },
        leagueTier: { iconUrls: { medium: 'https://example.com/league.png' } },
      },
      RankingBoard.playerHome,
    );

    expect(entry.subtitle).toBe('Clan One');
    expect(entry.clanBadgeUrl).toBe('https://badges.clashk.ing/CLAN');
    expect(entry.score).toBe(6012);
    expect(entry.movement).toBe('+6');
    expect(entry.imageUrl).toBe('https://example.com/league.png');
  });

  test('uses builder league art, the builder trophy metric, and the canonical clan badge', () => {
    const entry = RankingEntry.fromJson(
      {
        tag: '#PLAYER',
        name: 'Builder Player',
        builderBaseTrophies: 5000,
        builderBaseLeague: { id: 44000005, name: 'Copper League III' },
        clan: {
          tag: ' #bUiLdEr ',
          name: 'Builder Clan',
          badgeUrls: { small: 'broken-api-badge.png' },
        },
      },
      RankingBoard.playerBuilder,
    );

    expect(entry.imageUrl).toBe(
      'https://assets.clashk.ing/leagues/builder-base/copper_league_3.png',
    );
    expect(entry.metricImageUrl).toBe(ImageAssets.builderBaseTrophy);
    expect(entry.clanBadgeUrl).toBe('https://badges.clashk.ing/BUILDER');
  });

  test.each([
    ['Home Village', RankingBoard.playerHome],
    ['Builder Base', RankingBoard.playerBuilder],
  ] as const)('leaves the clan badge empty for clanless %s rankings', (_label, board) => {
    const entry = RankingEntry.fromJson(
      { tag: '#PLAYER', name: 'Clanless Player', trophies: 5000 },
      board,
    );

    expect(entry.subtitle).toBe('');
    expect(entry.clanBadgeUrl).toBe('');
  });

  test('keeps the supplied clan badge for ClashKing player boards', () => {
    const entry = RankingEntry.fromJson(
      {
        tag: '#PLAYER',
        clan: {
          tag: '#CLAN',
          name: 'Clan One',
          badge: 'https://example.com/clan.png',
        },
      },
      RankingBoard.playerTownHall,
    );

    expect(entry.clanBadgeUrl).toBe('https://example.com/clan.png');
  });

  test('uses selected ranked-tier art unless a town hall is present', () => {
    const withoutTownHall = RankingEntry.fromJson(
      { tag: '#P1', name: 'One', placement: 5, league_trophies: 854 },
      RankingBoard.playerRanked,
      'selected-tier.png',
    );
    const withTownHall = RankingEntry.fromJson(
      { tag: '#P2', name: 'Two', placement: 1, townhall_level: 18, league_trophies: 900 },
      RankingBoard.playerRanked,
      'selected-tier.png',
    );

    expect(withoutTownHall.imageUrl).toBe('selected-tier.png');
    expect(withTownHall.imageUrl).toBe(ImageAssets.townHall(18));
    expect(withTownHall.metricImageUrl).toBe('selected-tier.png');
  });

  test('decodes the live clan Builder Base history score field', () => {
    const entry = RankingEntry.fromJson(
      {
        tag: '#CLAN',
        name: 'Builder Clan',
        rank: 4,
        previousRank: 7,
        builderBasePoints: 4_321,
        badgeUrls: { medium: 'https://example.com/badge.png' },
      },
      RankingBoard.clanBuilder,
    );

    expect(entry.score).toBe(4_321);
    expect(entry.imageUrl).toBe('https://example.com/badge.png');
    expect(entry.movement).toBe('+3');
  });

  test('does not partially parse malformed integer strings', () => {
    const entry = RankingEntry.fromJson(
      { tag: '#PLAYER', name: 'One', rank: '12oops', trophies: '6000oops' },
      RankingBoard.playerHome,
    );
    expect(entry.rank).toBe(0);
    expect(entry.score).toBe(0);
  });
});
