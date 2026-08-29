import 'package:clashkingapp/core/constants/image_assets.dart';

class ClanJoinLeave {
  final String clanTag;
  final int available;
  final int uniquePlayers;
  final List<JoinLeaveEvent> joinLeaveList;

  ClanJoinLeave({
    required this.clanTag,
    required this.available,
    required this.uniquePlayers,
    required this.joinLeaveList,
  });

  factory ClanJoinLeave.fromJson(Map<String, dynamic> json) {
    return ClanJoinLeave(
      clanTag: json['clan_tag'] ?? "",
      available: (json['available'] as num?)?.toInt() ?? 0,
      uniquePlayers: (json['uniquePlayers'] as num?)?.toInt() ?? 0,
      joinLeaveList:
          (json['items'] as List<dynamic>? ??
                  json['join_leave_list'] as List<dynamic>? ??
                  const [])
              .map((e) => JoinLeaveEvent.fromJson(e))
              .toList(),
    );
  }

  factory ClanJoinLeave.empty() {
    return ClanJoinLeave(
      clanTag: "",
      available: 0,
      uniquePlayers: 0,
      joinLeaveList: [],
    );
  }

  ClanJoinLeave appendPage(ClanJoinLeave page) {
    final seen = <String>{};
    final combined = <JoinLeaveEvent>[];
    for (final event in [...joinLeaveList, ...page.joinLeaveList]) {
      final key =
          '${event.time.toUtc().toIso8601String()}|${event.type}|${event.tag}';
      if (seen.add(key)) combined.add(event);
    }
    return ClanJoinLeave(
      clanTag: clanTag.isEmpty ? page.clanTag : clanTag,
      available: page.available,
      uniquePlayers: page.uniquePlayers,
      joinLeaveList: combined,
    );
  }
}

class JoinLeaveEvent {
  final String type;
  final JoinLeaveClan? clan;
  final DateTime time;
  final String tag;
  final String name;
  final int th;

  JoinLeaveEvent({
    required this.type,
    required this.clan,
    required this.time,
    required this.tag,
    required this.name,
    required this.th,
  });

  factory JoinLeaveEvent.fromJson(Map<String, dynamic> json) {
    return JoinLeaveEvent(
      type: json['type'] ?? "",
      clan: json['clan'] is Map<String, dynamic>
          ? JoinLeaveClan.fromJson(json['clan'] as Map<String, dynamic>)
          : null,
      time: DateTime.tryParse(json['time'] ?? '') ?? DateTime(1970),
      tag: json['tag'] ?? "",
      name: json['name'] ?? "",
      th:
          (json['townHallLevel'] as num?)?.toInt() ??
          (json['th'] as num?)?.toInt() ??
          0,
    );
  }
}

class JoinLeaveClan {
  final String name;
  final String tag;
  final String badge;

  const JoinLeaveClan({
    required this.name,
    required this.tag,
    required this.badge,
  });

  factory JoinLeaveClan.fromJson(Map<String, dynamic> json) {
    final tag = json['tag'] as String? ?? '';
    return JoinLeaveClan(
      name: json['name'] as String? ?? '',
      tag: tag,
      badge: ImageAssets.clanBadgeForTag(tag),
    );
  }
}
