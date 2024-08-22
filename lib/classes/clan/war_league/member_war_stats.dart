import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sentry_flutter/sentry_flutter.dart';

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
  List<Attacks> warAttacks = [];
  List<Defense> defenses = [];

  // New fields for percentages
  double percentageNoStarsDefenses = 0;
  double percentageNoStarsAttacks = 0;
  double percentageOneStarsDefenses = 0;
  double percentageOneStarsAttacks = 0;
  double percentageTwoStarsDefenses = 0;
  double percentageTwoStarsAttacks = 0;
  double percentageThreeStarsDefenses = 0;
  double percentageThreeStarsAttacks = 0;

  // Other fields for stats calculation
  int totalAttacks = 0;
  int totalDefenses = 0;
  int warsParticipated = 0;
  int expectedAttacks = 0;
  int missedAttacks = 0;

  MemberWarStats({
    required this.tag,
    required this.name,
    required this.townhallLevel,
    required this.mapPosition,
    this.opponentAttacks = 0,
  });

  void addWarAttacks(Attacks warAttacks) {
    this.warAttacks.add(warAttacks);
    warsParticipated++;
    expectedAttacks += warAttacks.attacksExpected;
    totalAttacks += warAttacks.attacks.length;
    missedAttacks += warAttacks.attacksExpected - warAttacks.attacks.length;
  }

  void addDefense(Defense defense) {
    defenses.add(defense);
  }

  void calculatePercentages() {
    totalAttacks = warAttacks.fold(0, (sum, war) => sum + war.attacks.length);
    if (totalAttacks > 0) {
      percentageNoStarsAttacks = warAttacks.fold(
              0,
              (sum, war) =>
                  sum + war.attacks.where((a) => a.stars == 0).length) /
          totalAttacks *
          100;
      percentageOneStarsAttacks = warAttacks.fold(
              0,
              (sum, war) =>
                  sum + war.attacks.where((a) => a.stars == 1).length) /
          totalAttacks *
          100;
      percentageTwoStarsAttacks = warAttacks.fold(
              0,
              (sum, war) =>
                  sum + war.attacks.where((a) => a.stars == 2).length) /
          totalAttacks *
          100;
      percentageThreeStarsAttacks = warAttacks.fold(
              0,
              (sum, war) =>
                  sum + war.attacks.where((a) => a.stars == 3).length) /
          totalAttacks *
          100;
    }

    totalDefenses = defenses.length;
    if (totalDefenses > 0) {
      percentageNoStarsDefenses =
          defenses.where((d) => d.stars == 0).length / totalDefenses * 100;
      percentageOneStarsDefenses =
          defenses.where((d) => d.stars == 1).length / totalDefenses * 100;
      percentageTwoStarsDefenses =
          defenses.where((d) => d.stars == 2).length / totalDefenses * 100;
      percentageThreeStarsDefenses =
          defenses.where((d) => d.stars == 3).length / totalDefenses * 100;
    }
  }

  double get averageStars => totalAttacks > 0
      ? warAttacks.fold(
              0,
              (sum, war) =>
                  sum +
                  war.attacks
                      .fold(0, (subSum, attack) => subSum + attack.stars)) /
          totalAttacks
      : 0.0;

  double get averageDestructionPercentage => totalAttacks > 0
      ? warAttacks.fold(
              0,
              (sum, war) =>
                  sum +
                  war.attacks.fold(
                      0,
                      (subSum, attack) =>
                          (subSum + attack.destructionPercentage).toInt())) /
          totalAttacks
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

  int numberOfStarsAttacks(int numberOfStars) {
    return warAttacks.fold(
        0,
        (sum, war) =>
            sum +
            war.attacks
                .where((attack) => attack.stars == numberOfStars)
                .length);
  }
}

class Attacks {
  final String warType;
  final int attacksExpected;
  final List<Attack> attacks;

  Attacks({
    required this.warType,
    required this.attacksExpected,
    required this.attacks,
  });
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
  final String type;

  Attack({
    required this.attackerTag,
    required this.defenderTag,
    required this.stars,
    required dynamic destructionPercentage, // Changement ici
    required this.order,
    required this.duration,
    required this.fresh,
    required this.defender,
    required this.type,
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
    clanTag = clanTag.replaceFirst("#", "!");
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

    List<int> prepList = [
      5 * 60,
      15 * 60,
      30 * 60,
      60 * 60,
      2 * 60,
      4 * 60,
      6 * 60,
      8 * 60,
      12 * 60,
      16 * 60,
      20 * 60,
      24 * 60,
    ];

    try {
      for (var war in wars) {
        var clanData;

        if (war['clan']['tag'] == clanTag) {
          clanData = war['clan'];
        } else if (war['opponent']['tag'] == clanTag) {
          clanData = war['opponent'];
        } else {
          continue;
        }

        var preparationStartTime = DateTime.parse(war['startTime'])
            .difference(DateTime.parse(war['preparationStartTime']));
        var preparationStartTimeInMinutes = preparationStartTime.inMinutes;

        String type;
        if (prepList.contains(preparationStartTimeInMinutes)) {
          type = "friendly";
        } else if (war["attacksPerMember"] == null) {
          type = "cwl";
        } else {
          type = "random";
        }

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

          int expectedAttacks = war["attacksPerMember"] != null
              ? (war["attacksPerMember"] is int
                  ? war["attacksPerMember"] as int
                  : int.parse(war["attacksPerMember"].toString()))
              : 1;

          var attacksList =
              (member['attacks'] as List<dynamic>?)?.map<Attack>((attack) {
                    var defender = Defender(
                      tag: attack['defenderTag'],
                      name: 'Unknown', // Replace with actual data if available
                      townhallLevel: 0, // Replace with actual data if available
                      mapPosition: 0, // Replace with actual data if available
                    );
                    return Attack(
                      attackerTag: attack['attackerTag'],
                      defenderTag: attack['defenderTag'],
                      stars: attack['stars'],
                      destructionPercentage: attack['destructionPercentage'],
                      order: attack['order'],
                      duration: attack['duration'],
                      fresh: false,
                      defender: defender,
                      type: type, // This is the war type determined earlier
                    );
                  }).toList() ??
                  [];

          var attacksObject = Attacks(
            warType: type,
            attacksExpected: expectedAttacks,
            attacks: attacksList,
          );

          memberStats.addWarAttacks(attacksObject);

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
              destructionPercentage: member['bestOpponentAttack']
                  ['destructionPercentage'],
              order: member['bestOpponentAttack']['order'],
              duration: member['bestOpponentAttack']['duration'],
              fresh: false,
              attacker: attacker,
            );
            memberStats.addDefense(defenseObj);
          }
        }
      }

      // Calculate percentages for all members
      for (var memberStats in membersWarStats.allMembers) {
        memberStats.calculatePercentages();
      }
    } catch (exception, stackTrace) {
      Sentry.captureException(exception, stackTrace: stackTrace);
    }

    return membersWarStats;
  }
}
