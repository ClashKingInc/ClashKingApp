import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameDataService static data normalization', () {
    test('prefers non-seasonal duplicate troop for the base item key', () {
      GameDataService.loadFromBundleForTesting({
        'troops': [
          {
            'name': 'Meteor Golem',
            'village': 'home',
            'is_seasonal': true,
            'levels': [
              {'level': 1},
            ],
          },
          {
            'name': 'Meteor Golem',
            'village': 'home',
            'levels': [
              {'level': 1},
            ],
          },
        ],
      });

      final troops = GameDataService.troopsData['troops'];
      expect(troops['Meteor Golem']['is_seasonal'], isNot(true));
      expect(
        troops['Meteor Golem']['url'],
        'https://assets.clashk.ing/troops/meteor_golem/icon.webp',
      );
      expect(troops['Meteor Golem 2']['is_seasonal'], isTrue);
    });

    test('uses official game translations for supported UI locales', () {
      GameDataService.loadFromBundleForTesting({
        'war_leagues': [
          {
            '_id': 48000007,
            'name': 'Gold League III',
            'TID': {'name': 'TID_LEAGUE_GOLD3'},
          },
        ],
      });
      GameDataService.loadTranslationsForTesting({
        'TID_LEAGUE_GOLD3': {'DE': 'Gold-Liga III'},
        'TID_GOLD': {'DE': 'Gold'},
      }, locale: const Locale('de'));

      final item = Map<String, dynamic>.from(
        GameDataService.warLeagueData['leagues']['Gold League III'] as Map,
      );
      expect(
        GameDataService.localizedNameForItemOrFallback(
          item,
          locale: const Locale('de'),
          fallback: 'Gold III',
        ),
        'Gold-Liga III',
      );
      expect(
        GameDataService.localizedNameForTidOrFallback(
          'TID_GOLD',
          locale: const Locale('de'),
          fallback: 'Goldvorrat',
        ),
        'Gold',
      );
    });

    test('indexes war leagues by their public API IDs', () {
      GameDataService.loadFromBundleForTesting({
        'war_leagues': [
          {
            '_id': 48000007,
            'name': 'Gold League III',
            'TID': {'name': 'TID_LEAGUE_GOLD3'},
          },
          {
            '_id': 48000019,
            'name': 'Titan League III',
            'TID': {'name': 'TID_LEAGUE_HERO3'},
          },
        ],
      });

      expect(
        GameDataService.warLeaguesByApiId[48000006]?['name'],
        'Gold League III',
      );
      expect(
        GameDataService.warLeaguesByApiId[48000018]?['name'],
        'Titan League III',
      );
    });

    test('keeps the ARB fallback when Clash lacks the app locale', () {
      GameDataService.loadTranslationsForTesting({
        'TID_LEAGUE_GOLD3': {'EN': 'Gold League III'},
      }, locale: const Locale('cs'));

      expect(
        GameDataService.hasTranslationsForLocale(const Locale('cs')),
        isFalse,
      );
      expect(
        GameDataService.localizedNameForItemOrFallback(
          {
            'name': 'Gold League III',
            'TID': {'name': 'TID_LEAGUE_GOLD3'},
          },
          locale: const Locale('cs'),
          fallback: 'Zlato III',
        ),
        'Zlato III',
      );
    });
  });
}
