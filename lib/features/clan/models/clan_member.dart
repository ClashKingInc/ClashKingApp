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
  });

  factory ClanMember.fromJson(Map<String, dynamic> json) {
    return ClanMember(
        tag: json["tag"],
        name: json["name"],
        role: json["role"],
        townHallLevel: json["townHallLevel"],
        expLevel: json["expLevel"],
        trophies: json["trophies"],
        donations: json["donations"],
        donationsReceived: json["donationsReceived"],
        builderBaseTrophies: json["builderBaseTrophies"],
        league: json["league"] != null
            ? ClanLeague.fromJson(json["league"] as Map<String, dynamic>)
            : ClanLeague.unranked());
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
        league: ClanLeague.unranked());
  }
}
