import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:clashkingapp/classes/profile/achievement.dart';
import 'package:clashkingapp/classes/profile/equipment.dart';
import 'package:clashkingapp/classes/profile/hero.dart';
import 'package:clashkingapp/classes/profile/spell.dart';
import 'package:clashkingapp/classes/profile/troop.dart';
import 'package:clashkingapp/classes/clan/clan_info.dart';
import 'package:clashkingapp/classes/functions.dart';
import 'package:clashkingapp/classes/data/league_data_manager.dart';
import 'package:clashkingapp/classes/profile/legend_league.dart';

class ProfileInfo {
  final String name;
  final String tag;
  final int townHallLevel;
  final int townHallWeaponLevel;
  final int expLevel;
  final int trophies;
  final int bestTrophies;
  final int warStars;
  final int attackWins;
  final int defenseWins;
  final int builderHallLevel;
  final int builderBaseTrophies;
  final int bestBuilderBaseTrophies;
  final String role;
  final String warPreference;
  final int donations;
  final int donationsReceived;
  final int clanCapitalContributions;
  final Clan? clan;
  final List<Achievement> achievements;
  final List<Hero> heroes;
  final List<Troop> troops;
  final List<Spell> spells;
  final List<Equipment> equipments;
  String league = '';
  String townHallPic = '';
  String builderHallPic = '';
  String leagueUrl = '';
  late PlayerLegendData? playerLegendData;

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
    required this.role,
    required this.warPreference,
    required this.donations,
    required this.donationsReceived,
    required this.clanCapitalContributions,
    required this.clan,
    required this.achievements,
    required this.heroes,
    required this.troops,
    required this.spells,
    required this.equipments,
  });

  factory ProfileInfo.fromJson(Map<String, dynamic> json) {
    return ProfileInfo(
      name: json['name'] ?? 'No name',
      tag: json['tag'] ?? 'No tag',
      townHallLevel: json['townHallLevel'] ?? 0,
      townHallWeaponLevel: json['townHallWeaponLevel'] ?? 0,
      expLevel: json['expLevel'] ?? 0,
      trophies: json['trophies'] ?? 0,
      bestTrophies: json['bestTrophies'] ?? 0,
      warStars: json['warStars'] ?? 0,
      attackWins: json['attackWins'] ?? 0,
      defenseWins: json['defenseWins'] ?? 0,
      builderHallLevel: json['builderHallLevel'] ?? 0,
      builderBaseTrophies: json['builderBaseTrophies'] ?? 0,
      bestBuilderBaseTrophies: json['bestBuilderBaseTrophies'] ?? 0,
      role: json['role'] ?? 'No role',
      warPreference: json['warPreference'] ?? 'No preference',
      donations: json['donations'] ?? 0,
      donationsReceived: json['donationsReceived'] ?? 0,
      clanCapitalContributions: json['clanCapitalContributions'] ?? 0,
      clan: json['clan'] != null ? Clan.fromJson(json['clan']) : null,
      achievements: List<Achievement>.from(
          json['achievements'].map((x) => Achievement.fromJson(x ?? {}))),
      heroes:
          List<Hero>.from(json['heroes'].map((x) => Hero.fromJson(x)) ?? []),
      troops:
          List<Troop>.from(json['troops'].map((x) => Troop.fromJson(x)) ?? []),
      spells:
          List<Spell>.from(json['spells'].map((x) => Spell.fromJson(x)) ?? []),
      equipments: List<Equipment>.from(
          json['heroEquipment'].map((x) => Equipment.fromJson(x)) ?? []),
    );
  }
}

// Service

class ProfileInfoService {
// Placeholder methods for fetching data
  Future<ProfileInfo> fetchProfileInfo(String tag) async {
    // Fetch profile info based on tag
    tag = tag.replaceAll('#', '!');

    final response = await http.get(
      Uri.parse('https://api.clashking.xyz/v1/players/$tag'),
    );

    if (response.statusCode == 200) {
      String responseBody = utf8.decode(response.bodyBytes);
      ProfileInfo profileInfo = ProfileInfo.fromJson(jsonDecode(responseBody));
      profileInfo.townHallPic =
          await fetchPlayerTownHallByTownHallLevel(profileInfo.townHallLevel);

      profileInfo.leagueUrl =
          LeagueDataManager().getLeagueUrl(profileInfo.league);

      profileInfo.builderHallPic = await fetchPlayerBuilderHallByTownHallLevel(
          profileInfo.builderHallLevel);
      await fetchImagesAndTypes(profileInfo.troops);
      await fetchImagesAndTypes(profileInfo.heroes);
      await fetchImagesAndTypes(profileInfo.spells);
      await fetchImagesAndTypes(profileInfo.equipments);
      profileInfo.league = await fetchLeagueName(profileInfo.tag);
      profileInfo.leagueUrl =
          LeagueDataManager().getLeagueUrl(profileInfo.league);
      
      print(profileInfo.leagueUrl);

      profileInfo.playerLegendData =
          await PlayerLegendService().fetchLegendData(profileInfo.tag);

      return profileInfo;
    } else {
      throw Exception('Failed to load player stats');
    }
  }
}
