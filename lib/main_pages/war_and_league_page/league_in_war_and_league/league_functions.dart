import 'package:flutter/material.dart';
import 'package:clashkingapp/api/current_league_info.dart';
Widget buildWarsTab(BuildContext context) {
  return Column(
    children: [
      ListTile(
        title: Text('Wars', style: Theme.of(context).textTheme.titleLarge),
      ),
    ],
  );
}

Future<Map<String, Map<String, dynamic>>> calculateTotalStarsAndPercentage(
    List<ClanLeagueRounds> rounds) async {
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
