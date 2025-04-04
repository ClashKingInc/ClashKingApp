class WarAttack {
  final String attackerTag;
  final String defenderTag;
  final int stars;
  final int destructionPercentage;
  final int order;

  WarAttack({
    required this.attackerTag,
    required this.defenderTag,
    required this.stars,
    required this.destructionPercentage,
    required this.order,
  });

  factory WarAttack.fromJson(Map<String, dynamic> json) {
    return WarAttack(
      attackerTag: json['attackerTag'],
      defenderTag: json['defenderTag'],
      stars: json['stars'],
      destructionPercentage: json['destructionPercentage'],
      order: json['order'],
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
