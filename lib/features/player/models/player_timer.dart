enum PlayerTimerType { war, cwl, capital }

class PlayerTimer {
  const PlayerTimer({
    required this.type,
    required this.expiresAt,
    required this.clans,
    this.warTag,
  });

  final PlayerTimerType type;
  final DateTime expiresAt;
  final List<String> clans;
  final String? warTag;

  factory PlayerTimer.fromJson(Map<String, dynamic> json) {
    return PlayerTimer(
      type: switch (json['type']) {
        'cwl' => PlayerTimerType.cwl,
        'capital' => PlayerTimerType.capital,
        _ => PlayerTimerType.war,
      },
      expiresAt:
          DateTime.tryParse(json['expiresAt']?.toString() ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      clans: (json['clans'] as List? ?? const [])
          .map((clan) => clan.toString())
          .toList(growable: false),
      warTag: json['warTag']?.toString(),
    );
  }
}

class PlayerTimers {
  const PlayerTimers({required this.items});

  final List<PlayerTimer> items;

  factory PlayerTimers.fromJson(Map<String, dynamic> json) {
    return PlayerTimers(
      items: (json['items'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => PlayerTimer.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
    );
  }
}
