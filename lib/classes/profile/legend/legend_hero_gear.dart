import 'package:clashkingapp/classes/data/gears_data_manager.dart';


class HeroGear {
  final String name;
  final int level;
  String hero;
  String url;
  String rarity;

  HeroGear(
      {required this.name,
      required this.level,
      required this.hero,
      required this.url,
      required this.rarity
      });

  factory HeroGear.fromJson(Map<String, dynamic> json) {
    Map<String, String> gears = GearDataManager().getGearInfo(json['name']);
    String hero = gears['hero'] ?? 'unknown';
    String url =
        gears['url'] ?? 'https://assets.clashk.ing/clashkinglogo.png';
    String rarity = gears['rarity'] ?? '1';
    return HeroGear(
      name: json['name'],
      level: json['level'],
      hero: hero,
      url: url,
      rarity: rarity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'level': level,
      'hero': hero,
      'url': url,
      'rarity': rarity,
    };
  }
}

class GearDetails {
  int count;
  String url;
  String hero;
  String name;

  GearDetails(this.count, this.url, this.hero, this.name);
}
