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
        'https://assets.clashk.ing/home-base/league-tier-icons/Dragon_League_29.png',
      );
    });

    test('uses available Legend tier league assets', () {
      GameDataService.playerLeagueData.clear();

      expect(
        ImageAssets.getLeagueImage('Legend League'),
        'https://assets.clashk.ing/home-base/league-tier-icons/Legend_League.png',
      );
      expect(
        ImageAssets.getLeagueImage('Legend League I'),
        'https://assets.clashk.ing/home-base/league-tier-icons/Legend_League_1.webp',
      );
      expect(
        ImageAssets.getLeagueImage('Legend League 2'),
        'https://assets.clashk.ing/home-base/league-tier-icons/Legend_League_2.webp',
      );
      expect(
        ImageAssets.getLeagueImage('Legend League III'),
        'https://assets.clashk.ing/home-base/league-tier-icons/Legend_League_3.webp',
      );
      expect(
        ImageAssets.getLeagueImage('Legend III'),
        'https://assets.clashk.ing/home-base/league-tier-icons/Legend_League_3.webp',
      );
      expect(
        ImageAssets.getLeagueImage('Legend 3'),
        'https://assets.clashk.ing/home-base/league-tier-icons/Legend_League_3.webp',
      );
    });

    test('uses CWL league icons for war league metadata', () {
      GameDataService.playerLeagueData.clear();
      GameDataService.playerLeagueData['leagues'] = {
        'Crystal League I': {
          'url':
              'https://assets.clashk.ing/home-base/league-icons/Icon_HV_League_Crystal_2.png',
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
        'https://assets.clashk.ing/home-base/league-icons/Icon_HV_CWL_Crystal_1.png',
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
        'https://assets.clashk.ing/home-base/league-icons/Icon_HV_CWL_Titan_2.png',
      );
      expect(
        ImageAssets.getWarLeagueImage('Legend League'),
        'https://assets.clashk.ing/home-base/league-icons/Icon_HV_CWL_Legend.png',
      );
    });

    test('uses direct Titan CWL icon from display name without static data', () {
      GameDataService.playerLeagueData.clear();
      GameDataService.leagueData.clear();
      GameDataService.warLeagueData.clear();

      expect(
        ImageAssets.getWarLeagueImage('Titan League II'),
        'https://assets.clashk.ing/home-base/league-icons/Icon_HV_CWL_Titan_2.png',
      );
    });

    test('does not fall back to player league icons for unknown war leagues', () {
      GameDataService.warLeagueData.clear();
      GameDataService.leagueData.clear();
      GameDataService.playerLeagueData.clear();
      GameDataService.playerLeagueData['leagues'] = {
        'Goblin League I': {
          'url':
              'https://assets.clashk.ing/home-base/league-icons/Icon_HV_League_Goblin_1.png',
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
  });
}
