import 'package:clashkingapp/features/war_cwl/models/war_cwl.dart';

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
    this.chatLanguage,
  });

  factory Clan.fromJson(Map<String, dynamic> json) {
    return Clan(
      tag: json["tag"],
      name: json["name"],
      type: json["type"],
      description: json["description"] ?? "",
      location: json["location"] != null
          ? ClanLocation.fromJson(json["location"])
          : null,
      isFamilyFriendly: json["isFamilyFriendly"] ?? false,
      badgeUrls: ClanBadgeUrls.fromJson(json["badgeUrls"]),
      clanLevel: json["clanLevel"],
      clanPoints: json["clanPoints"],
      clanBuilderBasePoints: json["clanBuilderBasePoints"],
      clanCapitalPoints: json["clanCapitalPoints"],
      capitalLeague: json["capitalLeague"] != null
          ? ClanLeague.fromJson(json["capitalLeague"])
          : null,
      requiredTrophies: json["requiredTrophies"],
      warFrequency: json["warFrequency"],
      warWinStreak: json["warWinStreak"],
      warWins: json["warWins"],
      warTies: json["warTies"],
      warLosses: json["warLosses"],
      isWarLogPublic: json["isWarLogPublic"] ?? true,
      warLeague: json["warLeague"] != null
          ? ClanLeague.fromJson(json["warLeague"])
          : null,
      members: json["members"],
      memberList: (json["memberList"] as List)
          .map((m) => ClanMember.fromJson(m))
          .toList(),
      labels:
          (json["labels"] as List).map((l) => ClanLeague.fromJson(l)).toList(),
      requiredBuilderBaseTrophies: json["requiredBuilderBaseTrophies"],
      requiredTownhallLevel: json["requiredTownhallLevel"],
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
}
