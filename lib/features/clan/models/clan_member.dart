import 'package:clashkingapp/features/clan/models/clan_league.dart';

class ClanMember {
  final String tag;
  final String name;
  final String role;
  final int townHallLevel;
  final int expLevel;
  final int trophies;
  final int donations;
  final int donationsReceived;
  final int builderBaseTrophies;
  final ClanLeague league;
  final ClanLeague? builderBaseLeague;

  ClanMember({
    required this.tag,
    required this.name,
    required this.role,
    required this.townHallLevel,
    required this.expLevel,
    required this.trophies,
    required this.donations,
    required this.donationsReceived,
    required this.builderBaseTrophies,
    required this.league,
    this.builderBaseLeague,
  });

  factory ClanMember.fromJson(Map<String, dynamic> json) {
    final rawLeague = json["leagueTier"] ?? json["league"];
    final rawBuilderBaseLeague = json["builderBaseLeague"];
    return ClanMember(
      tag: json["tag"]?.toString() ?? "",
      name: json["name"]?.toString() ?? "",
      role: json["role"]?.toString() ?? "",
      townHallLevel: (json["townHallLevel"] as num?)?.toInt() ?? 0,
      expLevel: (json["expLevel"] as num?)?.toInt() ?? 0,
      trophies: (json["trophies"] as num?)?.toInt() ?? 0,
      donations: (json["donations"] as num?)?.toInt() ?? 0,
      donationsReceived: (json["donationsReceived"] as num?)?.toInt() ?? 0,
      builderBaseTrophies: (json["builderBaseTrophies"] as num?)?.toInt() ?? 0,
      league: rawLeague is Map
          ? ClanLeague.fromJson(Map<String, dynamic>.from(rawLeague))
          : ClanLeague.unranked(),
      builderBaseLeague: rawBuilderBaseLeague is Map
          ? ClanLeague.fromJson(Map<String, dynamic>.from(rawBuilderBaseLeague))
          : null,
    );
  }

  factory ClanMember.empty() {
    return ClanMember(
      tag: "",
      name: "",
      role: "",
      townHallLevel: 0,
      expLevel: 0,
      trophies: 0,
      donations: 0,
      donationsReceived: 0,
      builderBaseTrophies: 0,
      league: ClanLeague.unranked(),
      builderBaseLeague: null,
    );
  }
}
