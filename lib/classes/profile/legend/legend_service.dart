import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:clashkingapp/classes/profile/legend/legend_data.dart';
import 'package:clashkingapp/classes/profile/legend/legend_attack.dart';
import 'package:clashkingapp/classes/profile/legend/legend_defense.dart';
import 'package:clashkingapp/classes/profile/legend/legend_day.dart';
import 'package:clashkingapp/classes/profile/legend/legend_season.dart';

class PlayerLegendService {
  Future<PlayerLegendData?> fetchLegendData(String tag) async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.clashking.xyz/player/${tag.substring(1)}/legends'));

      if (response.statusCode == 200) {
        String responseBody = utf8.decode(response.bodyBytes);
        PlayerLegendData playerLegendData =
            PlayerLegendData.fromJson(jsonDecode(responseBody));

        playerLegendData.legendSeasons = await fetchSeasonsData(tag);

        await calculateLegendData(playerLegendData);
        return playerLegendData;
      } else {
        return null;
      }
    } catch (exception, stackTrace) {
      final hint = Hint.withMap({
        'tag': tag,
      });
      Sentry.captureException(exception, stackTrace: stackTrace);
      Sentry.captureMessage('Failed to fetch Legend Data, hint: $hint');
      return null;
    }
  }

  Future<void> calculateLegendData(PlayerLegendData playerLegendData) async {
    DateTime selectedDate = DateTime.now().toUtc().subtract(Duration(hours: 5));
    String date = DateFormat('yyyy-MM-dd').format(selectedDate);
    DateTime selectedDateMinusOne = DateTime.now()
        .toUtc()
        .subtract(Duration(hours: 5))
        .subtract(Duration(days: 1));
    String dateMinusOne = DateFormat('yyyy-MM-dd').format(selectedDateMinusOne);

    if (playerLegendData.legendData.containsKey(date) &&
        playerLegendData.legendData.isNotEmpty) {
      LegendDay details = playerLegendData.legendData[date]!;
      String firstTrophies = '0';
      String currentTrophies = "0";
      int diffTrophies = 0;
      List<dynamic> attacksList =
          details.newAttacks.isNotEmpty ? details.newAttacks : details.attacks;
      List<dynamic> defensesList = details.newDefenses.isNotEmpty
          ? details.newDefenses
          : details.defenses;

      if (attacksList.isNotEmpty && defensesList.isNotEmpty) {
        var lastAttack = attacksList.last as Attack;
        var lastDefense = defensesList.last as Defense;
        currentTrophies = (lastAttack.time > lastDefense.time
            ? lastAttack.trophies.toString()
            : lastDefense.trophies.toString());

        var firstAttack = attacksList.first as Attack;
        var firstDefense = defensesList.first as Defense;
        firstTrophies = (firstAttack.time < firstDefense.time
                ? (firstAttack.trophies - firstAttack.change)
                : (firstDefense.trophies + firstDefense.change))
            .toString();
        diffTrophies = int.parse(currentTrophies) - int.parse(firstTrophies);
      } else if (attacksList.isNotEmpty) {
        var lastAttack = attacksList.last as Attack;
        currentTrophies = lastAttack.trophies.toString();
        var firstAttack = attacksList.first as Attack;
        firstTrophies = (firstAttack.trophies - firstAttack.change).toString();
        diffTrophies = int.parse(currentTrophies) - int.parse(firstTrophies);
      } else if (defensesList.isNotEmpty) {
        var lastDefense = defensesList.last as Defense;
        currentTrophies = lastDefense.trophies.toString();
        var firstDefense = defensesList.first as Defense;
        firstTrophies =
            (firstDefense.trophies + firstDefense.change).toString();
        diffTrophies = int.parse(currentTrophies) - int.parse(firstTrophies);
      } else {
        currentTrophies = details.defenses.isNotEmpty
            ? details.defenses.last.toString()
            : '0';
        firstTrophies = details.defenses.isNotEmpty
            ? details.defenses.first.toString()
            : '0';
      }

      playerLegendData.firstTrophies = firstTrophies;
      playerLegendData.currentTrophies = currentTrophies;
      playerLegendData.diffTrophies = diffTrophies;
      playerLegendData.attacksList = attacksList;
      playerLegendData.defensesList = defensesList;
    } else if (playerLegendData.legendData.isEmpty ||
        !playerLegendData.legendData.containsKey(dateMinusOne)) {
      playerLegendData.firstTrophies = "0";
      playerLegendData.currentTrophies = "0";
      playerLegendData.diffTrophies = 0;
      playerLegendData.attacksList = [];
      playerLegendData.defensesList = [];
    } else {
      LegendDay details = playerLegendData.legendData[dateMinusOne]!;
      String firstTrophies = '0';
      String currentTrophies = "0";
      List<dynamic> attacksList =
          details.newAttacks.isNotEmpty ? details.newAttacks : details.attacks;
      List<dynamic> defensesList = details.newDefenses.isNotEmpty
          ? details.newDefenses
          : details.defenses;

      if (attacksList.isNotEmpty && defensesList.isNotEmpty) {
        var lastAttack = attacksList.last as Attack;
        var lastDefense = defensesList.last as Defense;
        currentTrophies = (lastAttack.time > lastDefense.time
            ? lastAttack.trophies.toString()
            : lastDefense.trophies.toString());

        var firstAttack = attacksList.first as Attack;
        var firstDefense = defensesList.first as Defense;
        firstTrophies = (firstAttack.time < firstDefense.time
                ? (firstAttack.trophies - firstAttack.change)
                : (firstDefense.trophies + firstDefense.change))
            .toString();
      } else if (attacksList.isNotEmpty) {
        var lastAttack = attacksList.last as Attack;
        currentTrophies = lastAttack.trophies.toString();
        var firstAttack = attacksList.first as Attack;
        firstTrophies = (firstAttack.trophies - firstAttack.change).toString();
      } else if (defensesList.isNotEmpty) {
        var lastDefense = defensesList.last as Defense;
        currentTrophies = lastDefense.trophies.toString();
        var firstDefense = defensesList.first as Defense;
        firstTrophies =
            (firstDefense.trophies + firstDefense.change).toString();
      } else {
        currentTrophies = details.defenses.isNotEmpty
            ? details.defenses.last.toString()
            : '0';
        firstTrophies = details.defenses.isNotEmpty
            ? details.defenses.first.toString()
            : '0';
      }

      playerLegendData.diffTrophies = 0;
      playerLegendData.attacksList = [];
      playerLegendData.defensesList = [];
      playerLegendData.firstTrophies = firstTrophies;
      playerLegendData.currentTrophies = currentTrophies;
    }
  }
}
