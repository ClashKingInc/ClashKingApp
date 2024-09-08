import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:clashkingapp/classes/profile/description/achievement.dart';
import 'package:clashkingapp/classes/profile/description/equipment.dart';
import 'package:clashkingapp/classes/profile/description/hero.dart';
import 'package:clashkingapp/classes/profile/description/spell.dart';
import 'package:clashkingapp/classes/profile/description/troop.dart';
import 'package:clashkingapp/classes/clan/clan_info.dart';
import 'package:clashkingapp/classes/functions.dart';
import 'package:clashkingapp/classes/data/player_league_data_manager.dart';
import 'package:clashkingapp/classes/profile/legend/legend_data.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:retry/retry.dart';
import 'dart:io';
import 'package:clashkingapp/classes/profile/legend/legend_service.dart';
import 'package:clashkingapp/classes/profile/todo/to_do.dart';
import 'package:clashkingapp/classes/profile/todo/to_do_service.dart';
import 'package:clashkingapp/classes/profile/stats/player_stats_service.dart';
import 'package:clashkingapp/classes/profile/stats/player_war_stats.dart';

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
  String role;
  String warPreference;
  int donations;
  int donationsReceived;
  int clanCapitalContributions;
  Clan? clan;
  List<Achievement> achievements;
  List<Hero> heroes;
  List<Troop> troops;
  List<Spell> spells;
  List<Equipment> equipments;
  String league = '';
  String townHallPic = '';
  String builderHallPic = '';
  String leagueUrl = '';
  PlayerLegendData? playerLegendData;
  bool initialized = false;
  bool legendsInitialized = false;
  ToDo? toDo;
  late WarStats? warStats;
  bool warStatsInitialized = false;

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

  List<Troop> getActiveTroops() {
    return troops.where((troop) => troop.superTroopIsActive).toList();
  }

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

  void updateFrom(ProfileInfo profileInfo) {
    name = profileInfo.name;
    tag = profileInfo.tag;
    townHallLevel = profileInfo.townHallLevel;
    townHallWeaponLevel = profileInfo.townHallWeaponLevel;
    expLevel = profileInfo.expLevel;
    trophies = profileInfo.trophies;
    bestTrophies = profileInfo.bestTrophies;
    warStars = profileInfo.warStars;
    attackWins = profileInfo.attackWins;
    defenseWins = profileInfo.defenseWins;
    builderHallLevel = profileInfo.builderHallLevel;
    builderBaseTrophies = profileInfo.builderBaseTrophies;
    bestBuilderBaseTrophies = profileInfo.bestBuilderBaseTrophies;
    role = profileInfo.role;
    warPreference = profileInfo.warPreference;
    donations = profileInfo.donations;
    donationsReceived = profileInfo.donationsReceived;
    clanCapitalContributions = profileInfo.clanCapitalContributions;
    clan = profileInfo.clan;
    achievements = profileInfo.achievements;
    heroes = profileInfo.heroes;
    troops = profileInfo.troops;
    spells = profileInfo.spells;
    equipments = profileInfo.equipments;
    league = profileInfo.league;
    townHallPic = profileInfo.townHallPic;
    builderHallPic = profileInfo.builderHallPic;
    leagueUrl = profileInfo.leagueUrl;
    playerLegendData = profileInfo.playerLegendData;
    initialized = true;
    legendsInitialized = true;
  }
}

// Service
class ProfileInfoService {
  Future<ProfileInfo?> fetchProfileInfo(String tag) async {
    final transaction = Sentry.startTransaction(
      'fetchProfileInfo',
      'task',
      bindToScope: true,
    );

    try {
      tag = tag.replaceAll('#', '!');

      // Define the retry logic with exponential backoff
      final response = await retry(
        () async {
          final responseSpan = transaction.startChild('http.get');
          final response = await http
              .get(
                Uri.parse('https://api.clashking.xyz/v1/players/$tag'),
              )
              .timeout(Duration(seconds: 10));
          responseSpan.finish(
            status: response.statusCode == 200
                ? SpanStatus.ok()
                : SpanStatus.internalError(),
          );

          if (response.statusCode == 200) {
            return response;
          } else {
            Sentry.captureMessage('Player not found, tag: $tag');
            return null;
          }
        },
        retryIf: (e) => e is http.ClientException || e is SocketException,
      );

      if (response != null) {
        String responseBody = utf8.decode(response.bodyBytes);
        ProfileInfo profileInfo =
            ProfileInfo.fromJson(jsonDecode(responseBody));

        // Start fetching additional data in the background
        _fetchAdditionalProfileData(profileInfo, transaction);
        _fetchPlayerLegendData(profileInfo, transaction);
        _fetchPlayerWarStats(profileInfo, transaction);

        transaction.finish(status: SpanStatus.ok());
        return profileInfo;
      } else {
        return null;
      }
    } catch (exception, stackTrace) {
      transaction.finish(status: SpanStatus.internalError());
      Sentry.captureException(exception, stackTrace: stackTrace);
      Sentry.captureMessage('Failed to load player stats, tag: $tag');
      throw Exception('Failed to load player stats: $exception');
    }
  }

  Future<void> _fetchAdditionalProfileData(
      ProfileInfo profileInfo, ISentrySpan transaction) async {
    final townHallPicSpan =
        transaction.startChild('fetchPlayerTownHallByTownHallLevel');
    final builderHallPicSpan =
        transaction.startChild('fetchPlayerBuilderHallByTownHallLevel');
    final troopsSpan = transaction.startChild('fetchImagesAndTypes_troops');
    final heroesSpan = transaction.startChild('fetchImagesAndTypes_heroes');
    final spellsSpan = transaction.startChild('fetchImagesAndTypes_spells');
    final equipmentsSpan =
        transaction.startChild('fetchImagesAndTypes_equipments');
    final leagueNameSpan = transaction.startChild('fetchLeagueName');

    final results = await Future.wait([
      fetchWithSpan(townHallPicSpan,
          () => fetchPlayerTownHallByTownHallLevel(profileInfo.townHallLevel)),
      fetchWithSpan(
          builderHallPicSpan,
          () => fetchPlayerBuilderHallByTownHallLevel(
              profileInfo.builderHallLevel)),
      fetchWithSpan(
          troopsSpan, () => fetchImagesAndTypes(profileInfo.troops, "troops")),
      fetchWithSpan(
          heroesSpan, () => fetchImagesAndTypes(profileInfo.heroes, "heroes")),
      fetchWithSpan(
          spellsSpan, () => fetchImagesAndTypes(profileInfo.spells, "spells")),
      fetchWithSpan(equipmentsSpan,
          () => fetchImagesAndTypes(profileInfo.equipments, "gears")),
      fetchWithSpan(leagueNameSpan, () => fetchLeagueName(profileInfo.tag)),
    ]);

    // Assign results to profileInfo
    profileInfo.townHallPic = results[0] as String;
    profileInfo.builderHallPic = results[1] as String;
    profileInfo.league = results[6] as String;
    profileInfo.leagueUrl =
        PlayerLeagueDataManager().getLeagueUrl(profileInfo.league);
    profileInfo.initialized = true; // Set initialized to true
  }

  Future<void> _fetchPlayerLegendData(
      ProfileInfo profileInfo, ISentrySpan transaction) async {
    final playerLegendDataSpan = transaction.startChild('fetchLegendData');
    try {
      final playerLegendData =
          await PlayerLegendService().fetchLegendData(profileInfo.tag);
      profileInfo.playerLegendData = playerLegendData;
      profileInfo.legendsInitialized = true;

      playerLegendDataSpan.finish(status: SpanStatus.ok());
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
      Sentry.captureMessage('Failed to load player legend data, tag: ${profileInfo.tag}');
      playerLegendDataSpan.finish(status: SpanStatus.internalError());
      rethrow;
    }
  }

  Future<void> _fetchPlayerWarStats(
      ProfileInfo profileInfo, ISentrySpan transaction) async {
    int timestampStart =
        DateTime.now().subtract(Duration(days: 90)).millisecondsSinceEpoch ~/
            1000;
    int timestampEnd = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final playerStatsService = PlayerStatsService(
        playerTag: profileInfo.tag.replaceFirst("#", '%23'),
        timestampStart: timestampStart,
        timestampEnd: timestampEnd);

    try {
      // Récupérer les données des War Hits
      WarStats? warStats = await playerStatsService.fetchPlayerWarHits();
      profileInfo.warStats = warStats;
      profileInfo.warStatsInitialized = true;
    } catch (exception, stackTrace) {
      Sentry.captureException(exception, stackTrace: stackTrace);
      Sentry.captureMessage('Failed to load player war stats, tag: ${profileInfo.tag}');
    }
  }

  Future<T> fetchWithSpan<T>(
      ISentrySpan span, Future<T> Function() future) async {
    try {
      final result = await future();
      span.finish(status: SpanStatus.ok());
      return result;
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
      span.finish(status: SpanStatus.internalError());
      rethrow;
    }
  }

  Future<ProfileInfo?> fetchCompleteProfileInfo(String tag) async {
    ProfileInfo? profileInfo = await ProfileInfoService().fetchProfileInfo(tag);
    while (profileInfo!.initialized != true) {
      await Future.delayed(Duration(milliseconds: 100));
    }
    await ToDoService.fetchPlayerToDoData(profileInfo);

    return profileInfo;
  }
}
