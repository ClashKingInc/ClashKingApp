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

  factory WarMember.fromJson(Map<String, dynamic>? json) {
    final data = json ?? const <String, dynamic>{};

    return WarMember(
      tag: data['tag']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      townhallLevel: (data['townhallLevel'] as num?)?.toInt() ?? 0,
      mapPosition: (data['mapPosition'] as num?)?.toInt() ?? 0,
      opponentAttacks: (data['opponentAttacks'] as num?)?.toInt() ?? 0,
      attacks: (data['attacks'] as List<dynamic>?)
          ?.whereType<Map>()
          .map((e) => WarAttack.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      bestOpponentAttack: _asMap(data['bestOpponentAttack']) != null
          ? WarAttack.fromJson(_asMap(data['bestOpponentAttack'])!)
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

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}
