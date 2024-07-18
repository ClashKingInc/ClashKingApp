import 'package:clashkingapp/classes/profile/legend/legend_hero_gear.dart';

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

  factory Attack.fromJson(Map<String, dynamic> json) {
    var heroGearJson = json['hero_gear'] as List<dynamic>? ?? [];
    List<HeroGear> heroGearList =
        heroGearJson.map((i) => HeroGear.fromJson(i)).toList();

    return Attack(
      change: json['change'],
      time: json['time'],
      trophies: json['trophies'],
      heroGear: heroGearList,
    );
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