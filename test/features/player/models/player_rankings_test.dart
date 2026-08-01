import 'package:clashkingapp/features/player/models/player_rankings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses both camelCase ranking categories', () {
    final rankings = PlayerRankings.fromJson({
      'tag': '#PLAYER',
      'homeVillage': {
        'points': 5600,
        'globalRank': 42,
        'locationId': '32000087',
        'locationName': 'United States',
        'countryCode': 'US',
        'localRank': 7,
      },
      'builderBase': {
        'points': 5100,
        'globalRank': 84,
        'locationId': '32000006',
        'locationName': 'Brazil',
        'countryCode': 'BR',
        'localRank': 12,
      },
    });

    expect(rankings.tag, '#PLAYER');
    expect(rankings.homeVillage.points, 5600);
    expect(rankings.homeVillage.globalRank, 42);
    expect(rankings.homeVillage.locationId, '32000087');
    expect(rankings.homeVillage.locationName, 'United States');
    expect(rankings.homeVillage.countryCode, 'US');
    expect(rankings.homeVillage.localRank, 7);
    expect(rankings.builderBase.points, 5100);
    expect(rankings.builderBase.globalRank, 84);
    expect(rankings.builderBase.locationId, '32000006');
    expect(rankings.builderBase.locationName, 'Brazil');
    expect(rankings.builderBase.countryCode, 'BR');
    expect(rankings.builderBase.localRank, 12);
  });

  test('preserves nullable placement for a retained location', () {
    final rankings = PlayerRankings.fromJson({
      'tag': '#PLAYER',
      'homeVillage': {
        'points': null,
        'globalRank': null,
        'locationId': '32000087',
        'locationName': 'United States',
        'countryCode': 'US',
        'localRank': null,
      },
      'builderBase': {
        'points': null,
        'globalRank': null,
        'locationId': null,
        'locationName': null,
        'countryCode': null,
        'localRank': null,
      },
    });

    expect(rankings.homeVillage.locationId, '32000087');
    expect(rankings.homeVillage.points, isNull);
    expect(rankings.homeVillage.localRank, isNull);
    expect(rankings.homeVillage.globalRank, isNull);
    expect(rankings.builderBase.globalRank, isNull);
  });
}
