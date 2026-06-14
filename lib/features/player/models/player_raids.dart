class PlayerRaids {
  final int attackLimit;
  final int attackDone;

  PlayerRaids({
    required this.attackLimit,
    required this.attackDone,
  });

  factory PlayerRaids.fromJson(Map<String, dynamic> json) {
    return PlayerRaids(
      attackLimit: (json['attack_limit'] as num?)?.toInt() ?? 5,
      attackDone:  (json['attacks_done'] as num?)?.toInt() ?? 0,
    );
  }

  factory PlayerRaids.empty() {
    return PlayerRaids(
      attackLimit: 5,
      attackDone: 0,
    );
  }
}