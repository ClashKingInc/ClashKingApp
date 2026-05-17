import 'package:clashkingapp/features/clan/models/clan_capital_history.dart';
import 'package:clashkingapp/features/clan/models/clan_join_leave.dart';
import 'package:clashkingapp/features/clan/models/clan_war_stats.dart';
import 'package:clashkingapp/features/war_cwl/models/war_cwl.dart';
import 'package:clashkingapp/features/clan/models/clan_war_log.dart';

import 'clan_location.dart';
import 'clan_badge.dart';
import 'clan_league.dart';
import 'clan_member.dart';
import 'clan_capital.dart';
import 'clan_chat_language.dart';

class Clan {
  final String tag;
  final String name;
  final String type;
  final String description;
  final ClanLocation? location;
  final bool isFamilyFriendly;
  final ClanBadgeUrls badgeUrls;
  final int clanLevel;
  final int clanPoints;
  final int clanBuilderBasePoints;
  final int clanCapitalPoints;
  final ClanLeague? capitalLeague;
  final int requiredTrophies;
  final String warFrequency;
  final int warWinStreak;
  final int warWins;
  final int warTies;
  final int warLosses;
  final bool isWarLogPublic;
  final ClanLeague? warLeague;
  final int members;
  final List<ClanMember> memberList;
  final List<ClanLeague> labels;
  final int requiredBuilderBaseTrophies;
  final int requiredTownhallLevel;
  final ClanCapital? clanCapital;
  final ClanChatLanguage? chatLanguage;
  WarCwl? warCwl;
  ClanJoinLeave? joinLeave;
  CapitalHistoryItems? clanCapitalRaid;
  ClanWarLog? clanWarLog;
  ClanWarStats? clanWarStats;

  Clan({
    required this.tag,
    required this.name,
    required this.type,
    required this.description,
    this.location,
    required this.isFamilyFriendly,
    required this.badgeUrls,
    required this.clanLevel,
    required this.clanPoints,
    required this.clanBuilderBasePoints,
    required this.clanCapitalPoints,
    this.capitalLeague,
    required this.requiredTrophies,
    required this.warFrequency,
    required this.warWinStreak,
    required this.warWins,
    required this.warTies,
    required this.warLosses,
    required this.isWarLogPublic,
    this.warLeague,
    required this.members,
    required this.memberList,
    required this.labels,
    required this.requiredBuilderBaseTrophies,
    required this.requiredTownhallLevel,
    this.clanCapital,
    this.chatLanguage
  });

  factory Clan.fromJson(Map<String, dynamic> json) {
    final memberList = (json["memberList"] as List<dynamic>? ?? const []);
    final labels = (json["labels"] as List<dynamic>? ?? const []);

    return Clan(
      tag: json["tag"]?.toString() ?? "",
      name: json["name"]?.toString() ?? "",
      type: json["type"]?.toString() ?? "",
      description: json["description"] ?? "",
      location: json["location"] != null
          ? ClanLocation.fromJson(json["location"])
          : null,
      isFamilyFriendly: json["isFamilyFriendly"] ?? false,
      badgeUrls: ClanBadgeUrls.fromJson(
        (json["badgeUrls"] as Map<String, dynamic>?) ?? const {},
      ),
      clanLevel: (json["clanLevel"] as num?)?.toInt() ?? 0,
      clanPoints: (json["clanPoints"] as num?)?.toInt() ?? 0,
      clanBuilderBasePoints:
          (json["clanBuilderBasePoints"] as num?)?.toInt() ?? 0,
      clanCapitalPoints: (json["clanCapitalPoints"] as num?)?.toInt() ?? 0,
      capitalLeague: json["capitalLeague"] != null
          ? ClanLeague.fromJson(json["capitalLeague"])
          : null,
      requiredTrophies: (json["requiredTrophies"] as num?)?.toInt() ?? 0,
      warFrequency: json["warFrequency"] ?? "unknown",
      warWinStreak: (json["warWinStreak"] as num?)?.toInt() ?? 0,
      warWins: (json["warWins"] as num?)?.toInt() ?? 0,
      warTies: (json["warTies"] as num?)?.toInt() ?? 0,
      warLosses: (json["warLosses"] as num?)?.toInt() ?? 0,
      isWarLogPublic: json["isWarLogPublic"] ?? true,
      warLeague: json["warLeague"] != null
          ? ClanLeague.fromJson(json["warLeague"])
          : null,
      members: (json["members"] as num?)?.toInt() ?? 0,
      memberList: memberList
          .map((m) => ClanMember.fromJson(m))
          .toList(),
      labels: labels.map((l) => ClanLeague.fromJson(l)).toList(),
      requiredBuilderBaseTrophies:
          (json["requiredBuilderBaseTrophies"] as num?)?.toInt() ?? 0,
      requiredTownhallLevel:
          (json["requiredTownhallLevel"] as num?)?.toInt() ?? 0,
      clanCapital: json["clanCapital"] != null
          ? ClanCapital.fromJson(json["clanCapital"])
          : null,
      chatLanguage: json["chatLanguage"] != null
          ? ClanChatLanguage.fromJson(json["chatLanguage"])
          : null,
    );
  }

  void linkWar(WarCwl s) {
    warCwl = s;
  }

  void linkJoinLeave(ClanJoinLeave s) {
    joinLeave = s;
  }
}
