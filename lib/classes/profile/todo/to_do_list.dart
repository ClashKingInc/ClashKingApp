import 'package:clashkingapp/classes/profile/todo/to_do.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class ToDoList {
  final List<ToDo> items;
  late final bool isInTimeFrameForRaid;
  late final bool isInTimeFrameForClanGames;
  late final int totalLegends;
  late final int totalSeasonPass;
  late final int totalRaidsAttacks;
  late final int totalCwlAttacks;
  late final int totalClanGamesPoints;
  late final int numberAccounts;
  late int numberActiveAccounts = 0;
  late int numberInactiveAccounts = 0;
  late int percentageDone;
  late int totalDone;
  late int totalEvent;
  late int requiredLegendsAttacks = 0;
  late int requiredClanGamesPoints = 0;
  late int requiredRaidsAttacks = 0;
  late int requiredSeasonPass = 0;
  late int requiredCwlAttacks = 0;
  late bool isInitialized = false;

  ToDoList({required this.items}) {
    final nowUtc = DateTime.now().toUtc();
    isInTimeFrameForRaid =
        (nowUtc.weekday == DateTime.friday && nowUtc.hour >= 6) ||
            (nowUtc.weekday == DateTime.saturday ||
                nowUtc.weekday == DateTime.sunday) ||
            (nowUtc.weekday == DateTime.monday && nowUtc.hour < 6);
    isInTimeFrameForClanGames = (nowUtc.day >= 22 && nowUtc.hour >= 8) &&
        (nowUtc.day <= 28 && nowUtc.hour <= 8);
  }

  void calculateTotals() {
    totalLegends =
        items.fold(0, (sum, item) => sum + (item.legends?.numAttacks ?? 0));
    totalSeasonPass = items.fold(0, (sum, item) => sum + item.seasonPass);
    totalRaidsAttacks =
        items.fold(0, (sum, item) => sum + item.raids.attacksDone);
    totalCwlAttacks = items.fold(0, (sum, item) => sum + item.cwl.attacksDone);
    totalClanGamesPoints =
        items.fold(0, (sum, item) => sum + item.clanGames.points);

    numberAccounts = items.length;

    totalDone = 0;
    totalEvent = 0;

    for (ToDo item in items) {
      // Active accounts
      DateTime now = DateTime.now().toUtc();
      if (now
              .difference(
                  DateTime.fromMillisecondsSinceEpoch(item.lastActive * 1000))
              .inDays <
          14) {
        numberActiveAccounts++;

        // Legend completed
        if (item.isLegend) {
          totalEvent += 100;
          double legendRatio = item.legends!.numAttacks / 8;
          totalDone += (legendRatio * 100).toInt();
          requiredLegendsAttacks += 8;
        }

        // CWL attacks completed
        if (item.cwl.attackLimit != 0) {
          totalEvent += 100;
          double cwlRatio =
              item.cwl.attacksDone.toDouble() / item.cwl.attackLimit.toDouble();
          totalDone += (cwlRatio * 100).toInt();
          requiredCwlAttacks += item.cwl.attackLimit;
        }

        // Clan games completed
        if (isInTimeFrameForClanGames) {
          totalEvent += 100;
          double clanGamesRatio = item.clanGames.points / 4000;
          totalDone += (clanGamesRatio * 100).toInt();
          requiredClanGamesPoints += 4000;
        }

        // Raids completed
        if (isInTimeFrameForRaid) {
          totalEvent += 100;
          if (item.raids.attackLimit == 0) {
            item.raids.attackLimit = 5;
          }
          double raidRatio = item.raids.attacksDone.toDouble() /
              item.raids.attackLimit.toDouble();
          totalDone += (raidRatio * 100).toInt();
          requiredRaidsAttacks += item.raids.attackLimit;
        }

        // Season pass completed
        totalEvent += 100;
        double seasonPassRatio = item.seasonPass.toDouble() / 2600;
        totalDone += (seasonPassRatio * 100).toInt();
        requiredSeasonPass += 2600;
      } else {
        numberInactiveAccounts++;
      }
    }

    // Calculate overall percentage done
    if (totalEvent > 0) {
      percentageDone = (totalDone / totalEvent * 100).toInt();
    } else {
      percentageDone = 0; // No events, so 0% done
    }

    isInitialized = true;
  }

  factory ToDoList.fromJson(Map<String, dynamic> json) {
    var itemList = json['items'] != null
        ? (json['items'] as List)
            .map((itemJson) => ToDo.fromJson(itemJson as Map<String, dynamic>))
            .toList()
        : [];
    return ToDoList(items: itemList.cast<ToDo>());
  }

  @override
  String toString() {
    return 'PlayerToDoData: ${items.toString()}';
  }

  ToDo? findTodotByTag(String tag) {
    try {
      return items.firstWhere((todo) => todo.playerTag == tag);
    } catch (exception, stackTrace) {
      final hint = Hint.withMap({
        'custom_message': 'No to-do found for this tag',
        'tag': tag,
      });
      Sentry.captureException(exception, stackTrace: stackTrace, hint: hint);

      return null;
    }
  }
}
