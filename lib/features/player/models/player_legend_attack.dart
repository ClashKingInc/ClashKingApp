import 'package:clashkingapp/features/player/models/player_legend_hero_gear.dart';

class PlayerLegendAttack {
  final int change;
  final int trophies;
  final int time;
  final List<LegendHeroGear> heroGear;

  PlayerLegendAttack({
    required this.change,
    required this.trophies,
    required this.time,
    required this.heroGear,
  });

  factory PlayerLegendAttack.fromJson(Map<String, dynamic> json) {
    return PlayerLegendAttack(
      change: json['change'] ?? 0,
      trophies: json['trophies'] ?? 0,
      time: json['time'] ?? 0,
      heroGear: (json['hero_gear'] as List?)?.map((x) => LegendHeroGear.fromJson(x)).toList() ?? [],
    );
  }
}
