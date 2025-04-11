class WarAttack {
  final String attackerTag;
  final String defenderTag;
  final int stars;
  final int destructionPercentage;
  final int order;
  final MiniMember? defender;
  final MiniMember? attacker;

  WarAttack({
    required this.attackerTag,
    required this.defenderTag,
    required this.stars,
    required this.destructionPercentage,
    required this.order,
    this.defender,
    this.attacker,
  });

  factory WarAttack.fromJson(Map<String, dynamic> json) {
    return WarAttack(
      attackerTag: json['attackerTag'],
      defenderTag: json['defenderTag'],
      stars: json['stars'],
      destructionPercentage: json['destructionPercentage'],
      order: json['order'],
      defender: json['defender'] != null
          ? MiniMember.fromJson(json['defender'])
          : null,
      attacker: json['attacker'] != null
          ? MiniMember.fromJson(json['attacker'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attackerTag': attackerTag,
      'defenderTag': defenderTag,
      'stars': stars,
      'destructionPercentage': destructionPercentage,
      'order': order,
    };
  }
}


class MiniMember {
  final String tag;
  final String name;
  final int townhallLevel;
  final int mapPosition;
  final int? opponentAttacks;

  MiniMember({
    required this.tag,
    required this.name,
    required this.townhallLevel,
    required this.mapPosition,
    this.opponentAttacks,
  });

  factory MiniMember.fromJson(Map<String, dynamic> json) {
    return MiniMember(
      tag: json['tag'],
      name: json['name'],
      townhallLevel: json['townhallLevel'],
      mapPosition: json['mapPosition'],
      opponentAttacks: json['opponentAttacks']
    );
  }
}