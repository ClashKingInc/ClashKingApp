import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:clashkingapp/classes/functions.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class EventHistoryItem {
  final String tag;
  final String type;
  final dynamic pvalue;
  final dynamic value;
  final DateTime time;
  final String clan;
  final int th;
  late String townHallPic;

  EventHistoryItem({
    required this.tag,
    required this.type,
    this.pvalue,
    required this.value,
    required this.time,
    required this.clan,
    required this.th,
  });

  factory EventHistoryItem.fromJson(Map<String, dynamic> json) {
    return EventHistoryItem(
      tag: json['tag'],
      type: json['type'],
      pvalue: json['p_value'],
      value: json['value'],
      time: DateTime.parse(json['time']),
      clan: json['clan'],
      th: json['th'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tag': tag,
      'type': type,
      'p_value': pvalue,
      'value': value,
      'time': time,
      'clan': clan,
      'th': th,
    };
  }
}

class EventHistoryClan {
  final List<EventHistoryItem> items;
  late int leagueNumber = 0;
  late int capitalContributionsNumber = 0;
  late int clanNumber = 0;
  late int warStarsNumber = 0;
  late int bestBuilderBaseTrophiesNumber = 0;
  late int builderBaseLeagueNumber = 0;
  late int gamesChampionNumber = 0;
  late int superTroopNumber = 0;
  late int defenseWinsNumber = 0;
  late int heroUpgradeNumber = 0;
  late int petUpgradeNumber = 0;
  late int spellUpgradeNumber = 0;
  late int gearUpgradeNumber = 0;
  late int bestTrophiesNumber = 0;
  late int roleChangeNumber = 0;
  late int donationNumber = 0;
  late int expLevelNumber = 0;
  late int warPreferenceNumber = 0;
  late int townHallWeaponLevelNumber = 0;
  late int townHallLevelNumber = 0;
  late int otherNumber = 0;

  EventHistoryClan({required this.items});

  factory EventHistoryClan.fromJson(Map<String, dynamic> json) {
    var list = json['items'] as List;
    List<EventHistoryItem> itemsList = list.map((i) => EventHistoryItem.fromJson(i)).toList();
    return EventHistoryClan(items: itemsList);
  }
}

class EventHistoryClanService {
  static Future<EventHistoryClan> fetcheventHistoryData(String clanTag) async {
    try{
    clanTag = clanTag.replaceAll('#', '!');
    final response = await http.get(Uri.parse('https://api.clashking.xyz/clan/$clanTag/historical'));
    
    if (response.statusCode == 200) {
      EventHistoryClan eventHistoryClan = EventHistoryClan.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      for (var item in eventHistoryClan.items) {
        item.townHallPic = await fetchPlayerTownHallByTownHallLevel(item.th);
        switch (item.type) {
          case 'league':
            eventHistoryClan.leagueNumber += 1;
            break;
          case 'clanCapitalContributions':
            eventHistoryClan.capitalContributionsNumber += 1;
            break;
          case 'clan':
            eventHistoryClan.clanNumber += 1;
            break;
          case 'warStars':
            eventHistoryClan.warStarsNumber += 1;
            break;
          case 'bestBuilderBaseTrophies':
            eventHistoryClan.bestBuilderBaseTrophiesNumber += 1;
            break;
          case 'builderBaseLeague':
            eventHistoryClan.builderBaseLeagueNumber += 1;
            break;
          case 'gamesChampion':
            eventHistoryClan.gamesChampionNumber += 1;
            break;
          case 'superTroop':
            eventHistoryClan.superTroopNumber += 1;
            break;
          case 'defenseWins':
            eventHistoryClan.defenseWinsNumber += 1;
            break;
          case 'heroUpgrade':
            eventHistoryClan.heroUpgradeNumber += 1;
            break;
          case 'petUpgrade':
            eventHistoryClan.petUpgradeNumber += 1;
            break;
          case 'spellUpgrade':
            eventHistoryClan.spellUpgradeNumber += 1;
            break;
          case 'gearUpgrade':
            eventHistoryClan.gearUpgradeNumber += 1;
            break;
          case 'bestTrophies':
            eventHistoryClan.bestTrophiesNumber += 1;
            break;
          case 'roleChange':
            eventHistoryClan.roleChangeNumber += 1;
            break;
          case 'donation':
            eventHistoryClan.donationNumber += 1;
            break;
          case 'expLevel':
            eventHistoryClan.expLevelNumber += 1;
            break;
          case 'warPreference':
            eventHistoryClan.warPreferenceNumber += 1;
            break;
          case 'townHallWeaponLevel':
            eventHistoryClan.townHallWeaponLevelNumber += 1;
            break;
          case 'townHallLevel':
            eventHistoryClan.townHallLevelNumber += 1;
            break;
          default:
            eventHistoryClan.otherNumber += 1;
            break;
        }
      }
      return eventHistoryClan;
    } else {
      return EventHistoryClan(items: []);
    }
    } catch (exception, stackTrace) {
      final hint = Hint.withMap({
        'clan_tag': clanTag,
      });
      Sentry.captureException(exception, stackTrace: stackTrace);
      Sentry.captureMessage('Failed to load join leave data, hint: ${hint.toString()}');
      return EventHistoryClan(items: []);
    }
  }
}
