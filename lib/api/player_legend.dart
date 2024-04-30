import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PlayerLegendSeasonsService {
  static Future<List<dynamic>> fetchSeasonsData(String tag) async {
    final response = await http.get(Uri.parse(
        'https://api.clashking.xyz/player/${tag.substring(1)}/legend_rankings'));
    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);
      return json.decode(body);
    } else {
      throw Exception('Failed to load seasons data');
    }
  }
}

class PlayerLegendData {
  final Map<String, dynamic> legendData;
  final Map<String, dynamic> legendRanking;
  final String name;
  final String tag;
  final int townHallLevel;
  final Map<String, dynamic> rankings;
  final int streak;
  List<dynamic> seasonsData = [];
  String firstTrophies = '0';
  String currentTrophies = "0";
  int diffTrophies = 0;
  List<dynamic> attacksList = [];
  List<dynamic> defensesList = [];

  PlayerLegendData(
      {required this.legendData,
      required this.legendRanking,
      required this.name,
      required this.tag,
      required this.townHallLevel,
      required this.rankings,
      required this.streak});

  factory PlayerLegendData.fromJson(Map<String, dynamic> json) {
    return PlayerLegendData(
        legendData: json['legends'] ?? {},
        legendRanking: json['rankings'] ?? {},
        name: json['name'] ?? '',
        tag: json['tag'] ?? '',
        townHallLevel: json['townhall'] ?? 0,
        rankings: json['rankings'] ?? {},
        streak: json['streak'] ?? 0);
  }
}

class PlayerLegendService {
  Future<PlayerLegendData> fetchLegendData(String tag) async {
    final response = await http.get(Uri.parse(
        'https://api.clashking.xyz/player/${tag.substring(1)}/legends'));
    if (response.statusCode == 200) {
      String responseBody = utf8.decode(response.bodyBytes);
      PlayerLegendData playerLegendData =
          PlayerLegendData.fromJson(jsonDecode(responseBody));
      await calculateLegendData(playerLegendData);
      return playerLegendData;
    } else {
      throw Exception('Failed to load seasons data');
    }
  }

  Future<void> calculateLegendData(PlayerLegendData playerLegendData) async {
    DateTime selectedDate = DateTime.now().toUtc().subtract(Duration(hours: 5));
    String date = DateFormat('yyyy-MM-dd').format(selectedDate);
    print(
        "${date} : ${playerLegendData.legendData.containsKey(date).toString()}");
    print("${playerLegendData.legendData[date]}");
    if (playerLegendData.legendData == {} ||
        !playerLegendData.legendData.containsKey(date)) {
      playerLegendData.firstTrophies = "0";
      playerLegendData.currentTrophies = "0";
      playerLegendData.diffTrophies = 0;
      playerLegendData.attacksList = [];
      playerLegendData.defensesList = [];
    } else {
      Map<String, dynamic> details = playerLegendData.legendData[date];
      String firstTrophies = '0';
      String currentTrophies = "0";
      int diffTrophies = 0;
      List<dynamic> attacksList = details.containsKey('new_attacks')
          ? details['new_attacks']
          : details['attacks'] ?? [];
      List<dynamic> defensesList = details.containsKey('new_defenses')
          ? details['new_defenses']
          : details['defenses'] ?? [];

      if (attacksList.isNotEmpty && defensesList.isNotEmpty) {
        Map<String, dynamic> lastAttack = attacksList.last;
        Map<String, dynamic> lastDefense = defensesList.last;
        currentTrophies = (lastAttack['time'] > lastDefense['time']
                ? lastAttack['trophies'].toString()
                : lastDefense['trophies'])
            .toString();
        Map<String, dynamic> firstAttack = attacksList.first;
        Map<String, dynamic> firstDefense = defensesList.first;
        firstTrophies = (firstAttack['time'] < firstDefense['time']
                ? (firstAttack['trophies'] - firstAttack['change'])
                : (firstDefense['trophies']) + firstDefense['change'])
            .toString();
        diffTrophies = int.parse(currentTrophies) - int.parse(firstTrophies);
      } else if (attacksList.isNotEmpty) {
        Map<String, dynamic> lastAttack = attacksList.last;
        currentTrophies = lastAttack['trophies'].toString();
        Map<String, dynamic> firstAttack = attacksList.first;
        firstTrophies =
            (firstAttack['trophies'] - firstAttack['change']).toString();
        diffTrophies = int.parse(currentTrophies) - int.parse(firstTrophies);
      } else if (defensesList.isNotEmpty) {
        Map<String, dynamic> lastDefense = defensesList.last;
        currentTrophies = lastDefense['trophies'].toString();
        Map<String, dynamic> firstDefense = defensesList.first;
        firstTrophies =
            (firstDefense['trophies'] + firstDefense['change']).toString();
        diffTrophies = int.parse(currentTrophies) - int.parse(firstTrophies);
      } else {
        currentTrophies = details['trophies'].toString();
        firstTrophies = details['trophies'].toString();
      }

      playerLegendData.firstTrophies = firstTrophies;
      playerLegendData.currentTrophies = currentTrophies;
      playerLegendData.diffTrophies = diffTrophies;
      playerLegendData.attacksList = attacksList;
      playerLegendData.defensesList = defensesList;
    }
  }
}
