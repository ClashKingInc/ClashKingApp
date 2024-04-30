import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:clashkingapp/api/player_account_info.dart';
import 'package:intl/intl.dart';

class PlayerLegendService {
  static Future<Map<String, dynamic>> fetchLegendData(String tag) async {
    final response = await http.get(Uri.parse(
        'https://api.clashking.xyz/player/${tag.substring(1)}/legends'));
    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);
      return json.decode(body);
    } else {
      throw Exception('Failed to load seasons data');
    }
  }
}

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
  final PlayerAccountInfo playerStats;
  final Map<String, dynamic> legendData;
  List<dynamic> seasonsData = [];
  String firstTrophies = '0';
  String currentTrophies = "0";
  int diffTrophies = 0;
  List<dynamic> attacksList = [];
  List<dynamic> defensesList = [];

  PlayerLegendData({required this.playerStats, required this.legendData}) {
    PlayerLegendService.fetchLegendData(playerStats.tag).then((value) async {
      DateTime selectedDate =
          DateTime.now().toUtc().subtract(Duration(hours: 5));
      String date = DateFormat('yyyy-MM-dd').format(selectedDate);
      if (!legendData['legends'].containsKey(date)) {
        firstTrophies = "0";
        currentTrophies = "0";
        diffTrophies = 0;
        attacksList = [];
        defensesList = [];
      } else {
        Map<String, dynamic> details = legendData['legends'][date];
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
      }
    });
  }
}
