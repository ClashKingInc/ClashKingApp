import 'package:clashkingapp/features/war_cwl/models/war_attack.dart';

class WarMember {
  final String tag;
  final String name;
  final int townhallLevel;
  final int mapPosition;
  final int opponentAttacks;
  final List<WarAttack>? attacks;
  final WarAttack? bestOpponentAttack;

  WarMember({
    required this.tag,
    required this.name,
    required this.townhallLevel,
    required this.mapPosition,
    required this.opponentAttacks,
    this.attacks,
    this.bestOpponentAttack,
  });

  factory WarMember.fromJson(Map<String, dynamic> json) {
    return WarMember(
      tag: json['tag'],
      name: json['name'],
      townhallLevel: json['townhallLevel'],
      mapPosition: json['mapPosition'],
      opponentAttacks: json['opponentAttacks'] ?? 0,
      attacks: (json['attacks'] as List<dynamic>?)
          ?.map((e) => WarAttack.fromJson(e))
          .toList(),
      bestOpponentAttack: json['bestOpponentAttack'] != null
          ? WarAttack.fromJson(json['bestOpponentAttack'])
          : null,
    );
  }

  factory WarMember.empty() {
    return WarMember(
      tag: "",
      name: "",
      townhallLevel: 0,
      mapPosition: 0,
      opponentAttacks: 0,
      attacks: [],
      bestOpponentAttack: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tag': tag,
      'name': name,
      'townhallLevel': townhallLevel,
      'mapPosition': mapPosition,
      'opponentAttacks': opponentAttacks,
      'attacks': attacks?.map((e) => e.toJson()).toList(),
      'bestOpponentAttack': bestOpponentAttack?.toJson(),
    };
  }
}
