import 'package:clashkingapp/features/war_cwl/models/war_attack.dart';

class WarMember {
  final String tag;
  final String name;
  final int townhallLevel;
  final int mapPosition;
  final List<WarAttack>? attacks;
  final WarAttack? bestOpponentAttack;

  WarMember({
    required this.tag,
    required this.name,
    required this.townhallLevel,
    required this.mapPosition,
    this.attacks,
    this.bestOpponentAttack,
  });

  factory WarMember.fromJson(Map<String, dynamic> json) {
    return WarMember(
      tag: json['tag'],
      name: json['name'],
      townhallLevel: json['townhallLevel'],
      mapPosition: json['mapPosition'],
      attacks: (json['attacks'] as List<dynamic>?)
          ?.map((e) => WarAttack.fromJson(e))
          .toList(),
      bestOpponentAttack: json['bestOpponentAttack'] != null
          ? WarAttack.fromJson(json['bestOpponentAttack'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tag': tag,
      'name': name,
      'townhallLevel': townhallLevel,
      'mapPosition': mapPosition,
      'attacks': attacks?.map((e) => e.toJson()).toList(),
      'bestOpponentAttack': bestOpponentAttack?.toJson(),
    };
  }
}
