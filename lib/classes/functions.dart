import 'dart:convert';
import 'package:clashkingapp/classes/clan/clan_info.dart';
import 'package:clashkingapp/classes/clan/war_league/current_war_info.dart';
import 'package:http/http.dart' as http;
import 'package:clashkingapp/classes/data/league_data_manager.dart';
import 'package:clashkingapp/classes/data/troops_data_manager.dart';
import 'package:clashkingapp/classes/data/pets_data_manager.dart';
import 'package:clashkingapp/classes/data/heroes_data_manager.dart';
import 'package:clashkingapp/classes/data/spells_data_manager.dart';
import 'package:clashkingapp/classes/data/gears_data_manager.dart';

Future<String> fetchPlayerTownHallByTownHallLevel(int townHallLevel) async {
  String townHallPic;
  if (townHallLevel >= 1 && townHallLevel <= 16) {
    townHallPic =
        'https://clashkingfiles.b-cdn.net/home-base/town-hall-pics/town-hall-$townHallLevel.png';
  } else {
    townHallPic =
        'https://clashkingfiles.b-cdn.net/home-base/town-hall-pics/town-hall-16.png';
  }
  return townHallPic;
}

Future<String> fetchPlayerBuilderHallByTownHallLevel(
    int builderHallLevel) async {
  String builderHallPic;
  if (builderHallLevel >= 1 && builderHallLevel <= 10) {
    builderHallPic =
        'https://clashkingfiles.b-cdn.net/builder-base/builder-hall-pics/Building_BB_Builder_Hall_level_$builderHallLevel.png';
  } else {
    builderHallPic =
        'https://clashkingfiles.b-cdn.net/builder-base/builder-hall-pics/Building_BB_Builder_Hall_level_8.png';
  }

  return builderHallPic;
}

Future<Clan> fetchClanInfo(String tag) async {
  tag = tag.replaceAll('#', '!');

  final response = await http.get(
    Uri.parse('https://api.clashking.xyz/v1/clans/$tag'),
  );

  if (response.statusCode == 200) {
    String responseBody = utf8.decode(response.bodyBytes);
    Clan clanInfo = Clan.fromJson(jsonDecode(responseBody));
    clanInfo.warLeague!.imageUrl =
        LeagueDataManager().getLeagueUrl(clanInfo.warLeague!.name);

    return clanInfo;
  } else {
    throw Exception(
        'Failed to load clan stats with status code: ${response.statusCode}');
  }
}

Future<String> fetchLeagueName(String tag) async {
  tag = tag.replaceAll('#', '!');

  final response = await http.get(
    Uri.parse('https://api.clashking.xyz/player/$tag/stats'),
  );

  if (response.statusCode == 200) {
    String responseBody = utf8.decode(response.bodyBytes);
    return jsonDecode(responseBody)['league'] ?? "Unranked";
  } else {
    return "Unranked";
  }
}

Future<CurrentWarInfo> fetchCurrentWarInfo(String clanTag) async {
  clanTag = clanTag.replaceAll('#', '!');
  final response = await http.get(
    Uri.parse('https://api.clashking.xyz/v1/clans/$clanTag/currentwar'),
  );

  if (response.statusCode == 200) {
    String responseBody = utf8.decode(response.bodyBytes);
    CurrentWarInfo warInfo =
        CurrentWarInfo.fromJson(jsonDecode(responseBody), "war", clanTag);
    return warInfo;
  } else {
    throw Exception(
        'Failed to load current war info with status code: ${response.statusCode}');
  }
}

Future<void> fetchImagesAndTypes(List<dynamic> items, String type) async {
  for (var item in items) {
    Map<String, String> urlAndType;
    switch (type) {
      case "gears":
        urlAndType = GearDataManager().getGearInfo(item.name);
        item.rarity = urlAndType['rarity'] ?? '1';
        break;
      case "pets":
        urlAndType = PetsDataManager().getPetInfo(item.name);
        break;
      case "heroes":
        urlAndType = HeroesDataManager().getHeroInfo(item.name);
        break;
      case "spells":
        urlAndType = SpellsDataManager().getSpellInfo(item.name);
        break;
      default:
        urlAndType = TroopDataManager().getTroopInfo(item.name);
    }
    item.imageUrl = urlAndType['url'] ??
        'https://clashkingfiles.b-cdn.net/clashkinglogo.png';
    item.type = urlAndType['type'] ?? 'unknown';
  }
}

DateTime findLastMondayOfMonth(int year, int month) {
  DateTime firstDayOfNextMonth = DateTime(year, month + 1, 1);

  DateTime lastDayOfMonth = firstDayOfNextMonth.subtract(Duration(days: 1));

  int weekdayOfLastDay = lastDayOfMonth.weekday;

  int daysToLastMonday = (weekdayOfLastDay - DateTime.monday) % 7;

  DateTime lastMondayOfMonth =
      lastDayOfMonth.subtract(Duration(days: daysToLastMonday));

  return lastMondayOfMonth;
}
