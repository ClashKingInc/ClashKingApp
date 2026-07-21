import 'package:clashkingapp/features/rankings/models/ranking_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RankingLocation', () {
    test('keeps region 32000000 distinct from synthetic Worldwide', () {
      final europe = RankingLocation.fromJson({
        'id': 32000000,
        'name': 'Europe',
        'isCountry': false,
      });

      expect(europe.isWorldwide, isFalse);
      expect(europe.apiPath, '32000000');
      expect(const RankingLocation.worldwide().apiPath, 'global');
    });

    test('only accepts two-letter country codes for flag rendering', () {
      final valid = RankingLocation.fromJson({
        'id': 32000006,
        'name': 'United States',
        'isCountry': true,
        'countryCode': 'us',
      });
      final region = RankingLocation.fromJson({
        'id': 32000000,
        'name': 'Europe',
        'isCountry': false,
        'countryCode': 'EU',
      });

      expect(valid.countryCode, 'US');
      expect(valid.hasValidCountryCode, isTrue);
      expect(region.hasValidCountryCode, isFalse);
    });
  });

  group('RankingEntry', () {
    test('decodes official player ranking fields', () {
      final entry = RankingEntry.fromJson({
        'tag': '#PLAYER',
        'name': 'Player One',
        'rank': 2,
        'previousRank': 8,
        'trophies': 6012,
        'clan': {'tag': '#CLAN', 'name': 'Clan One'},
        'leagueTier': {
          'iconUrls': {'medium': 'https://example.com/league.png'},
        },
      }, RankingBoard.playerHome);

      expect(entry.audience, RankingAudience.players);
      expect(entry.subtitle, 'Clan One · #CLAN');
      expect(entry.score, 6012);
      expect(entry.movement, '+6');
      expect(entry.imageUrl, 'https://example.com/league.png');
    });

    test('decodes ClashKing snake-case clan fields', () {
      final entry = RankingEntry.fromJson({
        'tag': '#CLAN',
        'name': 'Clan One',
        'rank': 4,
        'war_win_streak': 19,
        'badge_url': 'https://example.com/badge.png',
      }, RankingBoard.clanWinStreak);

      expect(entry.audience, RankingAudience.clans);
      expect(entry.score, 19);
      expect(entry.imageUrl, 'https://example.com/badge.png');
    });

    test('uses the selected ranked-tier badge for every ranked row', () {
      final entry = RankingEntry.fromJson(
        {
          'tag': '#PLAYER',
          'name': 'Ranked Player',
          'placement': 5,
          'league_trophies': 854,
          'league': {
            'iconUrls': {'medium': 'https://example.com/legacy-purple.png'},
          },
        },
        RankingBoard.playerRanked,
        rankedLeagueIconUrl: 'https://example.com/legend-one.png',
      );

      expect(entry.imageUrl, 'https://example.com/legend-one.png');
      expect(entry.metricImageUrl, 'https://example.com/legend-one.png');
    });
  });
}
