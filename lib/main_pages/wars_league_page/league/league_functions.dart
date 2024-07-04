import 'package:flutter/material.dart';
import 'package:clashkingapp/classes/clan/war_league/current_league_info.dart';

Widget buildWarsTab(BuildContext context) {
  return Column(
    children: [
      Text('Wars', style: Theme.of(context).textTheme.titleLarge),
    ],
  );
}

Future<Map<String, Map<String, dynamic>>> calculateTotalStarsAndPercentage(
    List<ClanLeagueRounds> rounds, String sortTeamsBy) async {
  Map<String, Map<String, dynamic>> totalByClan = {};

  for (var round in rounds) {
    var wars = await round.warLeagueInfos;
    for (var war in wars) {
      if (!totalByClan.containsKey(war.clan.tag)) {
        totalByClan[war.clan.tag] = {'stars': 0, 'percentage': 0.0};
      }
      if (!totalByClan.containsKey(war.opponent.tag)) {
        totalByClan[war.opponent.tag] = {'stars': 0, 'percentage': 0.0};
      }

      bool warEnded = war.endTime.isBefore(DateTime.now());
      bool clanWon = war.clan.stars > war.opponent.stars ||
          (war.clan.stars == war.opponent.stars &&
              war.clan.destructionPercentage >
                  war.opponent.destructionPercentage);

      totalByClan[war.clan.tag]?['stars'] +=
          war.clan.stars + (warEnded && clanWon ? 10 : 0);
      totalByClan[war.opponent.tag]?['stars'] +=
          war.opponent.stars + (warEnded && !clanWon ? 10 : 0);

      totalByClan[war.clan.tag]?['percentage'] +=
          war.clan.destructionPercentage * war.teamSize;
      totalByClan[war.opponent.tag]?['percentage'] +=
          war.opponent.destructionPercentage * war.teamSize;
    }
  }

  return totalByClan;
}

Future<Map<String, dynamic>> calculateTotalStarsAndPercentageForMember(
    List<ClanLeagueRounds> rounds, String clanTag, String sortBy) async {
  Map<String, Map<String, dynamic>> totalByMember = {};
  int numberOfRounds = 0;

  for (var round in rounds) {
    var wars = await round.warLeagueInfos;
    numberOfRounds++;
    for (var war in wars) {
      if (war.clan.tag == clanTag) {
        for (var member in war.clan.members) {
          if (!totalByMember.containsKey(member.tag)) {
            totalByMember[member.tag] = {
              'stars': 0,
              'percentage': 0.0,
              'townHallLevel': member.townhallLevel,
              'name': member.name,
              'attacksDone': 0,
              'warParticipated': 0,
              'averageStars': 0,
              'averagePercentage': 0.0,
            };
          }
          if (member.attacks != null) {
            for (var attack in member.attacks!) {
              totalByMember[member.tag]?['stars'] += attack.stars;
              totalByMember[member.tag]?['percentage'] +=
                  attack.destructionPercentage;
              totalByMember[member.tag]?['attacksDone'] += 1;
            }
          }
          if (war.state != "preparation") {
            totalByMember[member.tag]!['warParticipated'] += 1;
          }
        }
      }
      if (war.opponent.tag == clanTag) {
        for (var member in war.opponent.members) {
          if (!totalByMember.containsKey(member.tag)) {
            totalByMember[member.tag] = {
              'stars': 0,
              'percentage': 0.0,
              'townHallLevel': member.townhallLevel,
              'name': member.name,
              'attacksDone': 0,
              'warParticipated': 0,
              'averageStars': 0,
              'averagePercentage': 0.0,
            };
          }
          if (member.attacks != null) {
            for (var attack in member.attacks!) {
              totalByMember[member.tag]?['stars'] += attack.stars;
              totalByMember[member.tag]?['percentage'] +=
                  attack.destructionPercentage;
              totalByMember[member.tag]?['attacksDone'] += 1;
            }
          }
          totalByMember[member.tag]?['warParticipated'] += 1;
        }
      }
    }
  }

  for (var member in totalByMember.keys) {
    if (totalByMember[member]!['warParticipated'] == 0) {
      totalByMember[member]?['averageStars'] = 0;
      totalByMember[member]?['averagePercentage'] = 0;
    } else {
      totalByMember[member]?['averageStars'] = totalByMember[member]!['stars'] /
          totalByMember[member]!['warParticipated'];
      totalByMember[member]?['averagePercentage'] =
          totalByMember[member]!['percentage'] /
              totalByMember[member]!['warParticipated'];
    }
  }

  // Convert the map to a list of entries
  List<MapEntry<String, Map<String, dynamic>>> entries =
      totalByMember.entries.toList();

  // Sort the list of entries by the number of stars
  entries.sort((a, b) {
    int comparison = b.value[sortBy].compareTo(a.value[sortBy]);
    if (comparison == 0 && (sortBy == 'stars' || sortBy == 'averageStars')) {
      // En cas d'égalité sur les étoiles, trie par pourcentage de destruction
      comparison = b.value['percentage'].compareTo(a.value['percentage']);
    }
    return comparison;
  });

  // Convert the sorted list of entries back to a map
  totalByMember = Map<String, Map<String, dynamic>>.fromEntries(entries);

  return {
    'totalByMember': totalByMember,
    'numberOfRounds': numberOfRounds,
  };
}
