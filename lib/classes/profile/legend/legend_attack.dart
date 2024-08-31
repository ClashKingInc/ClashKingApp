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

  factory Attack.fromJson(Map<String, dynamic> json) {
    try{
    var heroGearJson = json['hero_gear'] as List<dynamic>? ?? [];
    List<HeroGear> heroGearList =
        heroGearJson.map((i) => HeroGear.fromJson(i)).toList();

    return Attack(
      change: json['change'],
      time: json['time'],
      trophies: json['trophies'],
      heroGear: heroGearList,
    );
    } catch (exception, stackTrace) {
      var hint = Hint.withMap({
        'json': json,
      });
      Sentry.captureException(exception, stackTrace: stackTrace);
      Sentry.captureMessage('Failed to parse Legend Attack, hint: ${hint.toString()}');
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