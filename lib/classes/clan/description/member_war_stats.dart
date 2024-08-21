import 'dart:convert';
import 'package:http/http.dart' as http;

class MembersWarStats {
  final Map<String, MemberWarStats> _membersMap;

  MembersWarStats({required List<MemberWarStats> items})
      : _membersMap = {for (var member in items) member.tag: member};

  MemberWarStats? getMemberByTag(String tag) {
    return _membersMap[tag];
  }

  void addMemberStat(MemberWarStats memberStats) {
    _membersMap[memberStats.tag] = memberStats;
  }

  List<MemberWarStats> get allMembers => _membersMap.values.toList();

  @override
  String toString() {
    return _membersMap.values.map((member) => member.toString()).join('\n');
  }
}

class MemberWarStats {
  String tag;
  String name;
  int townhallLevel;
  int mapPosition;
  int opponentAttacks;
  List<Attack> attacks = [];
  List<Defense> defenses = [];

  MemberWarStats({
    required this.tag,
    required this.name,
    required this.townhallLevel,
    required this.mapPosition,
    this.opponentAttacks = 0,
  });

  void addAttack(Attack attack) {
    attacks.add(attack);
  }

  void addDefense(Defense defense) {
    defenses.add(defense);
  }

  double get averageStars => attacks.isNotEmpty
      ? attacks.map((attack) => attack.stars).reduce((a, b) => a + b) /
          attacks.length
      : 0.0;

  double get averageDestructionPercentage => attacks.isNotEmpty
      ? attacks
              .map((attack) => attack.destructionPercentage)
              .reduce((a, b) => a + b) /
          attacks.length
      : 0.0;

  double get averageDefenseStars => defenses.isNotEmpty
      ? defenses.map((defense) => defense.stars).reduce((a, b) => a + b) /
          defenses.length
      : 0.0;

  double get averageDefenseDestructionPercentage => defenses.isNotEmpty
      ? defenses
              .map((defense) => defense.destructionPercentage)
              .reduce((a, b) => a + b) /
          defenses.length
      : 0.0;

  @override
  String toString() {
    return '$name ($tag) - TH$townhallLevel\n'
        'Average stars: $averageStars\n'
        'Average destruction: $averageDestructionPercentage%\n'
        'Average defense stars: $averageDefenseStars\n'
        'Average defense destruction: $averageDefenseDestructionPercentage%\n';
  }
}

class Attack {
  final String attackerTag;
  final String defenderTag;
  final int stars;
  final double destructionPercentage;
  final int order;
  final int duration;
  final bool fresh;
  final Defender defender;

  Attack({
    required this.attackerTag,
    required this.defenderTag,
    required this.stars,
    required dynamic destructionPercentage, // Changement ici
    required this.order,
    required this.duration,
    required this.fresh,
    required this.defender,
  }) : destructionPercentage = destructionPercentage is int
            ? destructionPercentage.toDouble()
            : destructionPercentage;
}

class Defense {
  final String attackerTag;
  final String defenderTag;
  final int stars;
  final double destructionPercentage;
  final int order;
  final int duration;
  final bool fresh;
  final Attacker attacker;

  Defense({
    required this.attackerTag,
    required this.defenderTag,
    required this.stars,
    required dynamic destructionPercentage, // Changement ici
    required this.order,
    required this.duration,
    required this.fresh,
    required this.attacker,
  }) : destructionPercentage = destructionPercentage is int
            ? destructionPercentage.toDouble()
            : destructionPercentage;
}


class Defender {
  final String tag;
  final String name;
  final int townhallLevel;
  final int mapPosition;

  Defender({
    required this.tag,
    required this.name,
    required this.townhallLevel,
    required this.mapPosition,
  });
}

class Attacker {
  final String tag;
  final String name;
  final int townhallLevel;
  final int mapPosition;

  Attacker({
    required this.tag,
    required this.name,
    required this.townhallLevel,
    required this.mapPosition,
  });
  
}

class MembersWarStatsService {
  final String baseUrl = "https://api.clashking.xyz/war";

  Future<MembersWarStats> fetchWarLogsAndAnalyzeStats(String clanTag) async {
    final response = await http.get(Uri.parse('$baseUrl/$clanTag/previous'));

    if (response.statusCode == 200) {
      List<dynamic> warLogs = jsonDecode(utf8.decode(response.bodyBytes));
      return _analyzeMemberStats(clanTag, warLogs);
    } else {
      throw Exception('Failed to load war logs');
    }
  }

  MembersWarStats _analyzeMemberStats(String clanTag, List<dynamic> wars) {
    MembersWarStats membersWarStats = MembersWarStats(items: []);
    clanTag = clanTag.replaceFirst("!", "#");
    try {
      for (var war in wars) {
        var clanData;

        // Identifier si le clan est dans "clan" ou "opponent"
        if (war['clan']['tag'] == clanTag) {
          clanData = war['clan'];
        } else if (war['opponent']['tag'] == clanTag) {
          clanData = war['opponent'];
        } else {
          continue;
        }

        // Parcourir chaque membre du clan
        for (var member in clanData['members']) {
          var memberTag = member['tag'];
          var memberName = member['name'];
          var townhallLevel = member['townhallLevel'];
          var mapPosition = member['mapPosition'];
          var opponentAttacks = member['opponentAttacks'];

          var memberStats = membersWarStats.getMemberByTag(memberTag);

          if (memberStats == null) {
            memberStats = MemberWarStats(
              tag: memberTag,
              name: memberName,
              townhallLevel: townhallLevel,
              mapPosition: mapPosition,
              opponentAttacks: opponentAttacks,
            );
            membersWarStats.addMemberStat(memberStats);
          }

          // Ajouter les stats d'attaque si elles existent
          if (member['attacks'] != null) {
            for (var attack in member['attacks']) {
              var defender = Defender(
                tag: attack['defenderTag'],
                name: 'Unknown', 
                townhallLevel: 0,  
                mapPosition: 0,  
              );
              var attackObj = Attack(
                attackerTag: attack['attackerTag'],
                defenderTag: attack['defenderTag'],
                stars: attack['stars'],
                destructionPercentage: attack['destructionPercentage'],
                order: attack['order'],
                duration: attack['duration'],
                fresh: false,  
                defender: defender,
              );
              memberStats.addAttack(attackObj);
            }
          }

          // Ajouter les stats de défense si elles existent
          if (member['bestOpponentAttack'] != null) {
            var attacker = Attacker(
              tag: member['bestOpponentAttack']['attackerTag'],
              name: 'Unknown', 
              townhallLevel: 0,  
              mapPosition: 0,  
            );
            var defenseObj = Defense(
              attackerTag: member['bestOpponentAttack']['attackerTag'],
              defenderTag: member['tag'],
              stars: member['bestOpponentAttack']['stars'],
              destructionPercentage: member['bestOpponentAttack']['destructionPercentage'],
              order: member['bestOpponentAttack']['order'],
              duration: member['bestOpponentAttack']['duration'],
              fresh: false,  
              attacker: attacker,
            );
            memberStats.addDefense(defenseObj);
          }
        }
      }
    } catch (e) {
      print(e);
    }

    return membersWarStats;
  }
}
