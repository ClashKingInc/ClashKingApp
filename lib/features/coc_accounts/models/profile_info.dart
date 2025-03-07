import 'package:clashkingapp/services/api_service.dart';

class ProfileInfo {
  String name;
  String tag;
  int townHallLevel;
  int townHallWeaponLevel;
  int expLevel;
  int trophies;
  int bestTrophies;
  int warStars;
  int attackWins;
  int defenseWins;
  int builderHallLevel;
  int builderBaseTrophies;
  int bestBuilderBaseTrophies;
  String clanTag;
  String role;
  String warPreference;
  int donations;
  int donationsReceived;
  int clanCapitalContributions;
  String league;
  String townHallPic;
  String builderHallPic;
  String leagueUrl;

  ProfileInfo({
    required this.name,
    required this.tag,
    required this.townHallLevel,
    required this.townHallWeaponLevel,
    required this.expLevel,
    required this.trophies,
    required this.bestTrophies,
    required this.warStars,
    required this.attackWins,
    required this.defenseWins,
    required this.builderHallLevel,
    required this.builderBaseTrophies,
    required this.bestBuilderBaseTrophies,
    required this.clanTag,
    required this.role,
    required this.warPreference,
    required this.donations,
    required this.donationsReceived,
    required this.clanCapitalContributions,
    required this.league,
    required this.townHallPic,
    required this.builderHallPic,
    required this.leagueUrl,
  });

  factory ProfileInfo.fromJson(Map<String, dynamic> json) {
    try {
      ProfileInfo profile = ProfileInfo(
        name: json["name"] ?? "Unknown",
        tag: json["tag"] ?? "Unknown",
        townHallLevel: json["townHallLevel"] ?? 0,
        townHallWeaponLevel: json["townHallWeaponLevel"] ?? 0,
        expLevel: json["expLevel"] ?? 0,
        trophies: json["season_trophies"] ?? 0,
        bestTrophies: json["bestTrophies"] ?? 0,
        warStars: json["warStars"] ?? 0,
        attackWins: json["attackWins"] ?? 0,
        defenseWins: json["defenseWins"] ?? 0,
        builderHallLevel: json["builderHallLevel"] ?? 0,
        builderBaseTrophies: json["builderBaseTrophies"] ?? 0,
        bestBuilderBaseTrophies: json["bestBuilderBaseTrophies"] ?? 0,
        clanTag: json["clan"]?["tag"] ?? "",
        role: json["role"] ?? "",
        warPreference: json["warPreference"] ?? "",
        donations: json["donations"] ?? 0,
        donationsReceived: json["donationsReceived"] ?? 0,
        clanCapitalContributions: json["clanCapitalContributions"] ?? 0,
        league: json["league"]?["name"] ?? "",
        townHallPic:
            "${ApiService.assetUrl}/home-base/town-hall-pics/town-hall-${json["townHallLevel"] ?? 0}.png",
        builderHallPic:
            "${ApiService.assetUrl}/home-base/builder-hall-pics/builder-hall-${json["builderHallLevel"] ?? 0}.png",
        leagueUrl: json["league"]?["iconUrls"]?["medium"] ?? "",
      );

      return profile;
    } catch (e, stacktrace) {
      print("❌ Exception in ProfileInfo.fromJson: $e");
      print(stacktrace);
      return ProfileInfo(
        name: "Unknown",
        tag: "Unknown",
        townHallLevel: 0,
        townHallWeaponLevel: 0,
        expLevel: 0,
        trophies: 0,
        bestTrophies: 0,
        warStars: 0,
        attackWins: 0,
        defenseWins: 0,
        builderHallLevel: 0,
        builderBaseTrophies: 0,
        bestBuilderBaseTrophies: 0,
        clanTag: "",
        role: "",
        warPreference: "",
        donations: 0,
        donationsReceived: 0,
        clanCapitalContributions: 0,
        league: "",
        townHallPic: "",
        builderHallPic: "",
        leagueUrl: "",
      );
    }
  }
}
