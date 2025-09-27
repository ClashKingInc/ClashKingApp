import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:clashkingapp/classes/profile/stats/player_war_stats.dart';

class PlayerStatsService {
  final String playerTag;
  late int timestampStart;
  late int timestampEnd;
  final int limit;

  PlayerStatsService({
    required this.playerTag,
    this.timestampStart = 0,
    this.timestampEnd = 2527625513,
    this.limit = 100,
  });
  Future<WarStats> fetchPlayerWarHits() async {
    final url =
        'https://api.clashk.ing/player/${playerTag.replaceFirst("#", "%23")}/warhits?timestamp_start=$timestampStart&timestamp_end=$timestampEnd&limit=$limit';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      final List<dynamic> items = jsonResponse['items'];
      
      if(items.isEmpty) {
        return WarStats(
          numberOfWars: 0,
          timeStampsEnd: 0,
          timeStampsStart: 0,
          playerTag: '',
          playerName: '',
          townhallLevel: 0,
          mapPosition: 0,
          opponentAttacks: 0,
          attacks: [],
          defenses: [],
          warType: ''
        );
      }

      WarStats aggregatedStats = WarStats(
          numberOfWars: 0,
          timeStampsEnd: 0,
          timeStampsStart: 0,
          playerTag: '',
          playerName: '',
          townhallLevel: 0,
          mapPosition: 0,
          opponentAttacks: 0,
          attacks: [],
          defenses: [],
          warType: '');

      for (var warData in items) {
        final warInfo = warData['war_data'];
        String warType = warInfo['type'];
        final memberData = warData['member_data'];
        final warStartTime = DateTime.parse(warInfo['startTime']).millisecondsSinceEpoch;
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
            warType: warType,
            warStartTime: warStartTime,
          );
        }).toList();

        List<Defense> defenses = defensesData.map((defenseData) {
          final attacker = Attacker(
              tag: defenseData['attacker']['tag'],
              name: defenseData['attacker']['name'],
              townhallLevel: defenseData['attacker']['townhallLevel'],
              mapPosition: defenseData['attacker']['mapPosition'],
              opponentAttacks: defenseData['attacker']['opponentAttacks']);

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
            warType: warType,
            warStartTime: warStartTime,
          );
        }).toList();

        // Mise à jour des statistiques agrégées
        aggregatedStats = WarStats(
            numberOfWars: limit,
            timeStampsStart: aggregatedStats.timeStampsStart,
            timeStampsEnd: aggregatedStats.timeStampsEnd,
            playerTag: memberData['tag'],
            playerName: memberData['name'],
            townhallLevel: memberData['townhallLevel'],
            mapPosition:
                (aggregatedStats.mapPosition + memberData['mapPosition'])
                    .toInt(),
            opponentAttacks: (aggregatedStats.opponentAttacks +
                    memberData['opponentAttacks'])
                .toInt(),
            attacks: [...aggregatedStats.attacks, ...attacks],
            defenses: [...aggregatedStats.defenses, ...defenses],
            warType: aggregatedStats.warType);
      }

      // Calcul des moyennes après agrégation
      return WarStats(
          numberOfWars: aggregatedStats.numberOfWars,
          timeStampsStart: timestampStart,
          timeStampsEnd: timestampEnd,
          playerTag: aggregatedStats.playerTag,
          playerName: aggregatedStats.playerName,
          townhallLevel: aggregatedStats.townhallLevel,
          mapPosition: (aggregatedStats.mapPosition / items.length).round(),
          opponentAttacks: aggregatedStats.opponentAttacks,
          attacks: aggregatedStats.attacks,
          defenses: aggregatedStats.defenses,
          warType: aggregatedStats.warType);
    } else {
      throw Exception(
          'Failed to load player war hits. Status code: ${response.statusCode}');
    }
  }

  WarStats filterWarStats(
      WarStats originalStats, List<String> warTypesToFilter) {
    List<Attack> filteredAttacks = originalStats.attacks
        .where((attack) => warTypesToFilter.contains(attack.warType))
        .toList();
    List<Defense> filteredDefenses = originalStats.defenses
        .where((defense) => warTypesToFilter.contains(defense.warType))
        .toList();

    return WarStats(
        numberOfWars: filteredAttacks.length + filteredDefenses.length,
        timeStampsStart: originalStats.timeStampsStart,
        timeStampsEnd: originalStats.timeStampsEnd,
        playerTag: originalStats.playerTag,
        playerName: originalStats.playerName,
        townhallLevel: originalStats.townhallLevel,
        mapPosition: originalStats.mapPosition,
        opponentAttacks: originalStats.opponentAttacks,
        attacks: filteredAttacks,
        defenses: filteredDefenses,
        warType: warTypesToFilter.join(", "));
  }
}
