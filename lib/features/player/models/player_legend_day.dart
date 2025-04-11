import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/features/player/models/player_equipment.dart';
import 'package:clashkingapp/features/player/models/player_legend_attack.dart';

class PlayerLegendDay {
  final List<int> attacks;
  final List<int> defenses;
  final int trophiesGainedTotal;
  final int trophiesLostTotal;
  final int trophiesTotal;
  final int totalAttacks;
  final int totalDefenses;
  final int? startTrophies;
  final int? endTrophies;
  final List<PlayerLegendAttack> newAttacks;
  final List<PlayerLegendAttack> newDefenses;

  PlayerLegendDay({
    required this.attacks,
    required this.defenses,
    required this.trophiesGainedTotal,
    required this.trophiesLostTotal,
    required this.trophiesTotal,
    required this.totalAttacks,
    required this.totalDefenses,
    required this.newAttacks,
    required this.newDefenses,
    this.startTrophies,
    this.endTrophies,
  });

  int get remainingAttacks {
    return 8 - totalAttacks;
  }

  factory PlayerLegendDay.fromJson(Map<String, dynamic> json) {
    return PlayerLegendDay(
      attacks: List<int>.from(json['attacks'] ?? []),
      defenses: List<int>.from(json['defenses'] ?? []),
      trophiesGainedTotal: json['trophies_gained_total'] ?? 0,
      trophiesLostTotal: json['trophies_lost_total'] ?? 0,
      trophiesTotal: json['trophies_total'] ?? 0,
      totalAttacks: json['num_attacks'] ?? 0,
      totalDefenses: json['num_defenses'] ?? 0,
      startTrophies: json['start_trophies'],
      endTrophies: json['end_trophies'],
      newAttacks: (json['new_attacks'] as List?)
              ?.map((x) => PlayerLegendAttack.fromJson(x))
              .toList() ??
          [],
      newDefenses: (json['new_defenses'] as List?)
              ?.map((x) => PlayerLegendAttack.fromJson(x))
              .toList() ??
          [],
    );
  }

  Map<String, PlayerEquipment> gearCountsFlatFromProfile(
      List<PlayerEquipment> playerEquipments) {
    final Map<String, PlayerEquipment> result = {};
    final Set<String> processed = {};

    for (final attack in newAttacks) {
      for (final gear in attack.heroGear) {
        final gearName = gear.name;

        if (processed.contains(gearName)) continue;

        // Cherche dans le profil du joueur
        final fromProfile = playerEquipments.firstWhere(
          (e) => e.name == gearName,
          orElse: () => PlayerEquipment(
            name: gearName,
            level: gear.level,
            maxLevel: GameDataService.gearsData["gears"]?[gearName]
                    ?["maxLevel"] ??
                gear.level,
            rarity:
                GameDataService.gearsData["gears"]?[gearName]?["rarity"] ?? "1",
            village: "home",
          ),
        );

        result[gearName] = fromProfile;
        processed.add(gearName);
      }
    }

    return result;
  }

  Map<String, int> get usageCount {
    final Map<String, int> count = {};

    for (final attack in newAttacks) {
      for (final gear in attack.heroGear) {
        count[gear.name] = (count[gear.name] ?? 0) + 1;
      }
    }

    return count;
  }
}
