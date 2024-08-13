import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:clashkingapp/classes/profile/stats/player_war_stats.dart';
import 'package:clashkingapp/classes/profile/legend/legend_functions.dart';

class PlayerStatsService {
  final String playerTag;
  late int timestampStart;
  late int timestampEnd;
  final int limit;
  late String season;

  PlayerStatsService({
    required this.playerTag,
    this.timestampStart = 0,
    this.timestampEnd = 2527625513,
    this.limit = 50,
  }) {
    timestampStart =
        findSeasonStartDate(DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    timestampEnd = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    season = "August 2024";
  }
  Future<WarStats> fetchPlayerWarHits() async {
    final url =
        'https://api.clashking.xyz/player/${playerTag.replaceFirst("#", "%23")}/warhits?timestamp_start=$timestampStart&timestamp_end=$timestampEnd&limit=$limit';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final List<dynamic> items = jsonResponse['items'];

      WarStats aggregatedStats = WarStats(
        season: season,
        timeStampsEnd: 0,
        timeStampsStart: 0,
        playerTag: '',
        playerName: '',
        townhallLevel: 0,
        mapPosition: 0,
        opponentAttacks: 0,
        attacks: [],
        defenses: [],
      );

      for (var warData in items) {
        final memberData = warData['member_data'];
        final attacksData = warData['attacks'] as List<dynamic>;
        final defensesData = warData['defenses'] as List<dynamic>;

        List<Attack> attacks = attacksData.map((attackData) {
          final defender = Defender(
            tag: attackData['defender']['tag'],
            name: attackData['defender']['name'],
            townhallLevel: attackData['defender']['townhallLevel'],
            mapPosition: attackData['defender']['mapPosition'],
            opponentAttacks: attackData['defender']['opponentAttacks'],
          );

          return Attack(
            attackerTag: attackData['attackerTag'],
            defenderTag: attackData['defenderTag'],
            stars: attackData['stars'],
            destructionPercentage:
                attackData['destructionPercentage'].toDouble(),
            order: attackData['order'],
            duration: attackData['duration'],
            fresh: attackData['fresh'],
            defender: defender,
            attackOrder: attackData['attack_order'],
          );
        }).toList();

        List<Defense> defenses = defensesData.map((defenseData) {
          final attacker = Attacker(
            tag: defenseData['attacker']['tag'],
            name: defenseData['attacker']['name'],
            townhallLevel: defenseData['attacker']['townhallLevel'],
            mapPosition: defenseData['attacker']['mapPosition'],
            opponentAttacks: defenseData['attacker']['opponentAttacks'],
          );

          return Defense(
            attackerTag: defenseData['attackerTag'],
            defenderTag: defenseData['defenderTag'],
            stars: defenseData['stars'],
            destructionPercentage:
                defenseData['destructionPercentage'].toDouble(),
            order: defenseData['order'],
            duration: defenseData['duration'],
            fresh: defenseData['fresh'],
            attacker: attacker,
            attackOrder: defenseData['attack_order'],
          );
        }).toList();

        // Mise à jour des statistiques agrégées
        aggregatedStats = WarStats(
          season: season,
          timeStampsStart: aggregatedStats.timeStampsStart,
          timeStampsEnd: aggregatedStats.timeStampsEnd,
          playerTag: memberData['tag'],
          playerName: memberData['name'],
          townhallLevel: memberData['townhallLevel'],
          mapPosition:
              (aggregatedStats.mapPosition + memberData['mapPosition']).toInt(),
          opponentAttacks:
              (aggregatedStats.opponentAttacks + memberData['opponentAttacks'])
                  .toInt(),
          attacks: [...aggregatedStats.attacks, ...attacks],
          defenses: [...aggregatedStats.defenses, ...defenses],
        );
      }

      // Calcul des moyennes après agrégation
      return WarStats(
        season: aggregatedStats.season,
        timeStampsStart: timestampStart,
        timeStampsEnd: timestampEnd,
        playerTag: aggregatedStats.playerTag,
        playerName: aggregatedStats.playerName,
        townhallLevel: aggregatedStats.townhallLevel,
        mapPosition: (aggregatedStats.mapPosition / items.length).round(),
        opponentAttacks: aggregatedStats.opponentAttacks,
        attacks: aggregatedStats.attacks,
        defenses: aggregatedStats.defenses,
      );
    } else {
      throw Exception(
          'Failed to load player war hits. Status code: ${response.statusCode}');
    }
  }
}
