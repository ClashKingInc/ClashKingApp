import 'dart:convert';

import 'package:clashkingapp/classes/data/gears_data_manager.dart';
import 'package:clashkingapp/classes/profile/legend/legend_hero_gear.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class Attack {
  final int change;
  final int time;
  final int trophies;
  final List<HeroGear> heroGear;

  Attack({
    required this.change,
    required this.time,
    required this.trophies,
    required this.heroGear,
  });

  factory Attack.fromJson(dynamic json) {
    try {
      if (json is String) {
        json = jsonDecode(json) as Map<String, dynamic>;
      }

      var heroGearJson = json['hero_gear'] as List<dynamic>? ?? [];

      // Gérer les deux types d'éléments dans la liste `hero_gear`
      List<HeroGear> heroGearList = heroGearJson.map((i) {
        if (i is String) {
          // Si l'élément est une chaîne de caractères, créer un HeroGear avec juste le nom
          return HeroGear(
            name: i,
            level: 1,
            hero: GearDataManager().getGearInfo(i)['hero'] ?? 'unknown',
            url: GearDataManager().getGearInfo(i)['url'] ??
                'https://assets.clashk.ing/clashkinglogo.png',
            rarity: GearDataManager().getGearInfo(i)['rarity'] ?? '1',
          );
        } else if (i is Map<String, dynamic>) {
          // Si l'élément est un objet JSON, traiter normalement
          return HeroGear.fromJson(i);
        } else {
          // Cas où le type est inconnu, renvoyer une valeur par défaut
          return HeroGear(
            name: "Unknown",
            level: 1,
            hero: 'unknown',
            url: 'https://assets.clashk.ing/clashkinglogo.png',
            rarity: '1',
          );
        }
      }).toList();

      return Attack(
        change: json['change'] ?? 0,
        time: json['time'] ?? 0,
        trophies: json['trophies'] ?? 0,
        heroGear: heroGearList,
      );
    } catch (exception, stackTrace) {
      Sentry.captureException(exception, stackTrace: stackTrace);
      Sentry.captureMessage('Failed to parse Legend Attack, json: $json');
      return Attack(change: 0, time: 0, trophies: 0, heroGear: []);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'change': change,
      'time': time,
      'trophies': trophies,
      'hero_gear': heroGear.map((v) => v.toJson()).toList(),
    };
  }
}
