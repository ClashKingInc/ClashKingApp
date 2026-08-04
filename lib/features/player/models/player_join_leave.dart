import 'package:clashkingapp/features/clan/models/clan_join_leave.dart';

class PlayerJoinLeavePage {
  final int available;
  final List<JoinLeaveEvent> items;

  const PlayerJoinLeavePage({required this.available, required this.items});

  factory PlayerJoinLeavePage.fromJson(Map<String, dynamic> json) =>
      PlayerJoinLeavePage(
        available: (json['available'] as num?)?.toInt() ?? 0,
        items: (json['items'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(JoinLeaveEvent.fromJson)
            .toList(growable: false),
      );
}

class PlayerJoinLeaveTotal {
  final JoinLeaveClan clan;
  final int visits;
  final int minutes;

  const PlayerJoinLeaveTotal({
    required this.clan,
    required this.visits,
    required this.minutes,
  });

  factory PlayerJoinLeaveTotal.fromJson(Map<String, dynamic> json) =>
      PlayerJoinLeaveTotal(
        clan: JoinLeaveClan.fromJson(
          json['clan'] as Map<String, dynamic>? ?? const {},
        ),
        visits: (json['visits'] as num?)?.toInt() ?? 0,
        minutes: (json['minutes'] as num?)?.toInt() ?? 0,
      );
}
