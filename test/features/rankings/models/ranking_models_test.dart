import 'package:clashkingapp/core/config/api_config.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
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
    test('uses the Builder Base trophy for Builder Base boards', () {
      expect(RankingBoard.playerBuilder.iconUrl, ImageAssets.builderBaseTrophy);
      expect(RankingBoard.clanBuilder.iconUrl, ImageAssets.builderBaseTrophy);
    });

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
      expect(entry.subtitle, 'Clan One');
      expect(entry.clanBadgeUrl, '${ApiConfig.apiUrlV2}/clan/%23CLAN/badge');
      expect(entry.score, 6012);
      expect(entry.movement, '+6');
      expect(entry.imageUrl, 'https://example.com/league.png');
    });

    test('maps the Builder Base league name to its badge beside names', () {
      final entry = RankingEntry.fromJson({
        'tag': '#PLAYER',
        'name': 'Builder Player',
        'rank': 1,
        'builderBaseTrophies': 5000,
        'builderBaseLeague': {'id': 44000005, 'name': 'Copper League III'},
      }, RankingBoard.playerBuilder);

      expect(
        entry.imageUrl,
        'https://assets.clashk.ing/leagues/builder-base/copper_league_3.png',
      );
      expect(entry.metricImageUrl, ImageAssets.builderBaseTrophy);
      expect(entry.subtitle, isEmpty);
    });

    test('prefers every official leagueTier size over legacy league icons', () {
      final entry = RankingEntry.fromJson({
        'tag': '#PLAYER',
        'name': 'Player One',
        'rank': 1,
        'trophies': 5492,
        'league': {
          'name': 'Legend League',
          'iconUrls': {'medium': 'https://example.com/legacy-purple.png'},
        },
        'leagueTier': {
          'name': 'Legend I',
          'iconUrls': {'small': 'https://example.com/legend-one.png'},
        },
      }, RankingBoard.playerHome);

      expect(entry.imageUrl, 'https://example.com/legend-one.png');
      expect(entry.metricImageUrl, 'https://example.com/legend-one.png');
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

    test('uses townhall as the primary image on ranked rows', () {
      final entry = RankingEntry.fromJson(
        {
          'tag': '#PLAYER',
          'name': 'Ranked Player',
          'placement': 1,
          'townhall_level': 18,
          'league_trophies': 724,
        },
        RankingBoard.playerRanked,
        rankedLeagueIconUrl: 'https://example.com/pekka-23.png',
      );

      expect(entry.imageUrl, ImageAssets.townHall(18));
      expect(entry.metricImageUrl, 'https://example.com/pekka-23.png');
    });

    test('uses the cached league badge for townhall ranking metrics', () {
      final entry = RankingEntry.fromJson({
        'tag': '#PLAYER',
        'name': 'Townhall Player',
        'rank': 1,
        'townhall_level': 18,
        'trophies': 5513,
        'league': {
          'id': 105000036,
          'name': 'Legend I',
          'badge': 'https://example.com/legend-one.png',
        },
      }, RankingBoard.playerTownHall);

      expect(entry.imageUrl, ImageAssets.townHall(18));
      expect(entry.metricImageUrl, 'https://example.com/legend-one.png');
    });

    test(
      'uses included clan badge and never shows player tag on CK boards',
      () {
        final entry = RankingEntry.fromJson({
          'tag': '#PLAYER',
          'name': 'Townhall Player',
          'rank': 1,
          'townhall_level': 18,
          'trophies': 5513,
          'clan': {
            'tag': '#CLAN',
            'name': 'Clan One',
            'badge': 'https://example.com/clan.png',
          },
        }, RankingBoard.playerTownHall);

        expect(entry.subtitle, 'Clan One');
        expect(entry.subtitle, isNot(contains('#CLAN')));
        expect(entry.subtitle, isNot(contains('#PLAYER')));
        expect(entry.clanBadgeUrl, 'https://example.com/clan.png');
      },
    );

    test('leaves subtitle empty for clanless player rankings', () {
      final entry = RankingEntry.fromJson({
        'tag': '#PLAYER',
        'name': 'Clanless Player',
        'rank': 1,
        'trophies': 5000,
      }, RankingBoard.playerHome);

      expect(entry.subtitle, isEmpty);
      expect(entry.clanBadgeUrl, isEmpty);
    });

    test('never falls back to a player tag as the visible name', () {
      final entry = RankingEntry.fromJson({
        'tag': '#PLAYER',
        'rank': 1,
        'trophies': 5000,
      }, RankingBoard.playerHome);

      expect(entry.name, isEmpty);
      expect(entry.subtitle, isEmpty);
    });
  });
}
