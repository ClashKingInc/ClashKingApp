import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImageAssets direct player item URLs', () {
    test('builds direct player league asset URLs', () {
      GameDataService.playerLeagueData.clear();
      GameDataService.playerLeagueData['leagues'] = {
        'Dragon League 29': {'name': 'Dragon League 29'},
      };

      expect(
        ImageAssets.getLeagueImage('Dragon League 29'),
        'https://assets.clashk.ing/leagues/league-tier/dragon_league_29.png',
      );
    });

    test('uses available Legend tier league assets', () {
      GameDataService.playerLeagueData.clear();

      expect(
        ImageAssets.getLeagueImage('Unranked'),
        'https://assets.clashk.ing/leagues/league-tier/unranked.png',
      );
      expect(
        ImageAssets.getLeagueImage('Legend League'),
        'https://assets.clashk.ing/leagues/league-tier/legend_league.png',
      );
      expect(
        ImageAssets.getLeagueImage('Legend League I'),
        'https://assets.clashk.ing/leagues/league-tier/legend_league_1.webp',
      );
      expect(
        ImageAssets.getLeagueImage('Legend League 2'),
        'https://assets.clashk.ing/leagues/league-tier/legend_league_2.webp',
      );
      expect(
        ImageAssets.getLeagueImage('Legend League III'),
        'https://assets.clashk.ing/leagues/league-tier/legend_league_3.webp',
      );
      expect(
        ImageAssets.getLeagueImage('Legend III'),
        'https://assets.clashk.ing/leagues/league-tier/legend_league_3.webp',
      );
      expect(
        ImageAssets.getLeagueImage('Legend 3'),
        'https://assets.clashk.ing/leagues/league-tier/legend_league_3.webp',
      );
    });

    test('uses CWL league icons for war league metadata', () {
      GameDataService.playerLeagueData.clear();
      GameDataService.playerLeagueData['leagues'] = {
        'Crystal League I': {
          'url':
              'https://assets.clashk.ing/leagues/league-tier/crystal_league_1.png',
        },
      };
      GameDataService.leagueData.clear();
      GameDataService.warLeagueData.clear();
      GameDataService.warLeagueData['leagues'] = {
        'Crystal League I': {
          'name': 'Crystal League I',
          'TID': {'name': 'TID_LEAGUE_CRYSTAL1'},
        },
      };

      expect(
        ImageAssets.getWarLeagueImage('Crystal League I'),
        'https://assets.clashk.ing/leagues/cwl/crystal_league_1.png',
      );
    });

    test('uses Titan and Legend CWL league icons', () {
      GameDataService.playerLeagueData.clear();
      GameDataService.leagueData.clear();
      GameDataService.warLeagueData.clear();
      GameDataService.warLeagueData['leagues'] = {
        'Titan League II': {
          'name': 'Titan League II',
          'TID': {'name': 'TID_LEAGUE_HERO2'},
        },
        'Legend League': {
          'name': 'Legend League',
          'TID': {'name': 'TID_LEAGUE_LEGENDARY'},
        },
      };

      expect(
        ImageAssets.getWarLeagueImage('Titan League II'),
        'https://assets.clashk.ing/leagues/cwl/titan_league_2.png',
      );
      expect(
        ImageAssets.getWarLeagueImage('Legend League'),
        'https://assets.clashk.ing/leagues/cwl/legend_league.png',
      );
    });

    test(
      'uses direct Titan CWL icon from display name without static data',
      () {
        GameDataService.playerLeagueData.clear();
        GameDataService.leagueData.clear();
        GameDataService.warLeagueData.clear();

        expect(
          ImageAssets.getWarLeagueImage('Titan League II'),
          'https://assets.clashk.ing/leagues/cwl/titan_league_2.png',
        );
      },
    );

    test('does not fall back to player league icons for unknown war leagues', () {
      GameDataService.warLeagueData.clear();
      GameDataService.leagueData.clear();
      GameDataService.playerLeagueData.clear();
      GameDataService.playerLeagueData['leagues'] = {
        'Goblin League I': {
          'url':
              'https://assets.clashk.ing/leagues/league-tier/goblin_league_1.png',
        },
      };

      expect(
        ImageAssets.getWarLeagueImage('Goblin League I'),
        ImageAssets.defaultImage,
      );
    });

    test('builds direct spell and equipment asset URLs', () {
      expect(
        ImageAssets.getSpellImage('Lightning Spell'),
        'https://assets.clashk.ing/spells/lightning_spell.webp',
      );
      expect(
        ImageAssets.getGearImage('Barbarian Puppet'),
        'https://assets.clashk.ing/equipment/barbarian_puppet.webp',
      );
    });

    test('normalizes punctuation-heavy troop and pet names', () {
      expect(
        ImageAssets.getTroopImage('P.E.K.K.A'),
        'https://assets.clashk.ing/troops/pekka/icon.webp',
      );
      expect(
        ImageAssets.getPetImage('L.A.S.S.I'),
        'https://assets.clashk.ing/pets/lassi/icon.webp',
      );
      expect(
        ImageAssets.getBuilderBaseTroopImage('Baby Dragon 2'),
        'https://assets.clashk.ing/troops/baby_dragon_2/icon.webp',
      );
      expect(
        ImageAssets.getTroopImage('Meteor Golem'),
        'https://assets.clashk.ing/troops/meteor_golem/icon.webp',
      );
      expect(
        ImageAssets.getTroopImage('M.E.T.E.O.R Golem'),
        'https://assets.clashk.ing/troops/meteor_golem/icon.webp',
      );
    });

    test('builds direct hero icon URLs from API names', () {
      expect(
        ImageAssets.getHeroImage('Barbarian King'),
        'https://assets.clashk.ing/heroes/barbarian_king/icon.webp',
      );
      expect(
        ImageAssets.getBuilderBaseHeroImage('Battle Machine'),
        'https://assets.clashk.ing/heroes/battle_machine/icon.webp',
      );
    });

    test('builds v2.1.0 building and trap still-frame URLs', () {
      expect(
        ImageAssets.getHomeVillageBuildingImage('Wall', 9),
        'https://assets.clashk.ing/buildings/home-village/wall/level_9.webp',
      );
      expect(
        ImageAssets.getBuilderBaseBuildingImage('Double Cannon', 10),
        'https://assets.clashk.ing/buildings/builder-base/double_cannon/level_10.webp',
      );
      expect(
        ImageAssets.getSeasonalDefenseImage('Roaster', 10),
        'https://assets.clashk.ing/buildings/seasonal-defense/roaster/level_10.webp',
      );
      expect(
        ImageAssets.getBuilderBaseTrapImage('Push Trap', 10),
        'https://assets.clashk.ing/traps/builder-base/push_trap/level_10.webp',
      );
    });

    test('builds v2.1.0 decoration, league, and sticker URLs', () {
      expect(
        ImageAssets.getHomeVillageDecorationImage('Card Collector'),
        'https://assets.clashk.ing/decorations/home-village/card_collector.webp',
      );
      expect(
        ImageAssets.getBuilderBaseDecorationImage('Ancient Barbarian Statue'),
        'https://assets.clashk.ing/decorations/builder-base/ancient_barbarian_statue.webp',
      );
      expect(
        ImageAssets.getWarLeagueImage('Bronze League III'),
        'https://assets.clashk.ing/leagues/cwl/bronze_league_3.png',
      );
      expect(
        ImageAssets.getCapitalLeagueImage('Bronze League III'),
        'https://assets.clashk.ing/leagues/capital-leagues/bronze_league_3.png',
      );
      expect(
        ImageAssets.getBuilderBaseLeagueImage('Copper League III'),
        'https://assets.clashk.ing/leagues/builder-base/copper_league_3.png',
      );
      expect(
        ImageAssets.builderWave,
        'https://assets.clashk.ing/stickers/builder_wave.webp',
      );
    });
  });
}
