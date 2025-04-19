class ClanJoinLeave {
  final String clanTag;
  final int timeStampStart;
  final int timeStampEnd;
  final JoinLeaveStats stats;
  final List<JoinLeaveEvent> joinLeaveList;

  ClanJoinLeave({
    required this.clanTag,
    required this.timeStampStart,
    required this.timeStampEnd,
    required this.stats,
    required this.joinLeaveList,
  });

  factory ClanJoinLeave.fromJson(Map<String, dynamic> json) {
    return ClanJoinLeave(
      clanTag: json['clan_tag'] ?? "",
      timeStampStart: json['timestamp_start'] ?? 0,
      timeStampEnd: json['timestamp_end'] ?? 0,
      stats: JoinLeaveStats.fromJson(json['stats']),
      joinLeaveList: (json['join_leave_list'] as List<dynamic>)
          .map((e) => JoinLeaveEvent.fromJson(e))
          .toList(),
    );
  }

  factory ClanJoinLeave.empty() {
    return ClanJoinLeave(
      clanTag: "",
      timeStampStart: 0,
      timeStampEnd: 0,
      stats: JoinLeaveStats(
        totalEvents: 0,
        totalJoins: 0,
        totalLeaves: 0,
        uniquePlayers: 0,
        movingPlayers: 0,
        playerStillInClan: 0,
        playerLeftClan: 0,
        rejoinedPlayers: 0,
        mostMovingPlayers: [],
      ),
      joinLeaveList: [],
    );
  }
}

class JoinLeaveStats {
  final int totalEvents;
  final int totalJoins;
  final int totalLeaves;
  final int uniquePlayers;
  final int movingPlayers;
  final int playerStillInClan;
  final int playerLeftClan;
  final int rejoinedPlayers;
  final String? firstEvent;
  final String? lastEvent;
  final int? mostMovingHour;
  final double? avgTimeBetweenJoinLeave;
  final List<MostActivePlayer> mostMovingPlayers;

  JoinLeaveStats({
    required this.totalEvents,
    required this.totalJoins,
    required this.totalLeaves,
    required this.uniquePlayers,
    required this.movingPlayers,
    required this.playerStillInClan,
    required this.playerLeftClan,
    required this.rejoinedPlayers,
    this.firstEvent,
    this.lastEvent,
    this.mostMovingHour,
    this.avgTimeBetweenJoinLeave,
    required this.mostMovingPlayers,
  });

  factory JoinLeaveStats.fromJson(Map<String, dynamic> json) {
    return JoinLeaveStats(
      totalEvents: json['total_events'] ?? 0,
      totalJoins: json['total_joins'] ?? 0,
      totalLeaves: json['total_leaves'] ?? 0,
      uniquePlayers: json['unique_players'] ?? 0,
      movingPlayers: json['moving_players'] ?? 0,
      playerStillInClan: json['players_still_in_clan'] ?? 0,
      playerLeftClan: json['players_left_forever'] ?? 0,
      rejoinedPlayers: json['rejoined_players'] ?? 0,
      firstEvent: json['first_event'] ?? "",
      lastEvent: json['last_event'] ?? "",
      mostMovingHour: json['most_moving_hour'] ?? 0,
      avgTimeBetweenJoinLeave: (json['avg_time_between_join_leave'] as num?)?.toDouble(),
      mostMovingPlayers: (json['most_moving_players'] as List<dynamic>)
          .map((e) => MostActivePlayer.fromJson(e))
          .toList(),
    );
  }
}

class MostActivePlayer {
  final String tag;
  final String name;
  final int count;

  MostActivePlayer({
    required this.tag,
    required this.name,
    required this.count,
  });

  factory MostActivePlayer.fromJson(Map<String, dynamic> json) {
    return MostActivePlayer(
      tag: json['tag'] ?? "",
      name: json['name'] ?? "",
      count: json['count'] ?? 0,
    );
  }
}

class JoinLeaveEvent {
  final String type;
  final String clan;
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
      clan: json['clan'] ?? "",
      time: DateTime.parse(json['time']),
      tag: json['tag'] ?? "",
      name: json['name'] ?? "",
      th: json['th'] ?? 0,
    );
  }
}
