import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameDataService.mergeFallbackSectionData', () {
    test('adds missing image URLs without dropping bundle metadata', () {
      final storage = <String, dynamic>{
        'heroes': {
          'Barbarian King': {
            'info': 'bundle-info',
            'url': '',
          },
          'Archer Queen': {
            'info': 'existing-info',
          },
        },
      };

      GameDataService.mergeFallbackSectionData(
        storage: storage,
        sectionKey: 'heroes',
        fallbackResponse: {
          'heroes': {
            'Barbarian King': {
              'url':
                  'https://assets.clashk.ing/home-base/hero-pics/Icon_HV_Hero_Barbarian_King.png',
              'type': 'hero',
            },
            'Archer Queen': {
              'url':
                  'https://assets.clashk.ing/home-base/hero-pics/Icon_HV_Hero_Archer_Queen.png',
              'type': 'hero',
            },
          },
        },
      );

      final heroes = storage['heroes'] as Map<String, dynamic>;
      expect(heroes['Barbarian King']['info'], 'bundle-info');
      expect(
        heroes['Barbarian King']['url'],
        'https://assets.clashk.ing/home-base/hero-pics/Icon_HV_Hero_Barbarian_King.png',
      );
      expect(heroes['Barbarian King']['type'], 'hero');
      expect(heroes['Archer Queen']['info'], 'existing-info');
      expect(
        heroes['Archer Queen']['url'],
        'https://assets.clashk.ing/home-base/hero-pics/Icon_HV_Hero_Archer_Queen.png',
      );
    });

    test('creates the section when the bundle did not load it', () {
      final storage = <String, dynamic>{};

      GameDataService.mergeFallbackSectionData(
        storage: storage,
        sectionKey: 'pets',
        fallbackResponse: {
          'pets': {
            'L.A.S.S.I': {
              'url':
                  'https://assets.clashk.ing/home-base/pet-pics/Icon_HV_Hero_Pets_L.A.S.S.I.png',
              'type': 'pet',
            },
          },
        },
      );

      expect(
        storage['pets']['L.A.S.S.I']['url'],
        'https://assets.clashk.ing/home-base/pet-pics/Icon_HV_Hero_Pets_L.A.S.S.I.png',
      );
      expect(storage['pets']['L.A.S.S.I']['type'], 'pet');
    });
  });
}
