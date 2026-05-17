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
        'https://assets.clashk.ing/troops/baby_dragon/icon.webp',
      );
    });

    test('builds direct hero icon URLs from API names', () {
      expect(
        ImageAssets.getHeroImage('Barbarian King'),
        'https://assets.clashk.ing/home-base/hero-pics/Icon_HV_Hero_Barbarian_King.png',
      );
      expect(
        ImageAssets.getBuilderBaseHeroImage('Battle Machine'),
        'https://assets.clashk.ing/builder-base/hero-pics/Icon_BB_Hero_Battle_Machine.png',
      );
    });
  });
}
