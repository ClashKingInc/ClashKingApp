import 'package:clashkingapp/classes/clan/description/builder_base_league.dart';
import 'package:clashkingapp/classes/clan/description/league.dart';

class Member {
  final String tag;
  final String name;
  final String role;
  final int townHallLevel;
  final int expLevel;
  final League league;
  final int trophies;
  final int builderBaseTrophies;
  final int clanRank;
  final int previousClanRank;
  final int donations;
  final int donationsReceived;
  final BuilderBaseLeague builderBaseLeague;

  Member({
    required this.tag,
    required this.name,
    required this.role,
    required this.townHallLevel,
    required this.expLevel,
    required this.league,
    required this.trophies,
    required this.builderBaseTrophies,
    required this.clanRank,
    required this.previousClanRank,
    required this.donations,
    required this.donationsReceived,
    required this.builderBaseLeague,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      tag: json['tag'] ?? 'No tag',
      name: json['name'] ?? 'No name',
      role: json['role'] ?? 'No role',
      townHallLevel: json['townHallLevel'] ?? 0,
      expLevel: json['expLevel'] ?? 0,
      league: League.fromJson(json['league']),
      trophies: json['trophies'] ?? 0,
      builderBaseTrophies: json['builderBaseTrophies'] ?? 0,
      clanRank: json['clanRank'] ?? 0,
      previousClanRank: json['previousClanRank'] ?? 0,
      donations: json['donations'] ?? 0,
      donationsReceived: json['donationsReceived'] ?? 0,
      builderBaseLeague: BuilderBaseLeague.fromJson(json['builderBaseLeague']),
    );
  }

  Member createMemberFromJson(Map<String, dynamic> json) {
    Member member = Member.fromJson(json);
    return member;
  }
}