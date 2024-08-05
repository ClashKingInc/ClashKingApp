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
  late final int totalWarAttacks;
  late int numberActiveAccounts = 0;
  late int numberInactiveAccounts = 0;
  late int percentageDone;
  late double totalDone;
  late double totalEvent;
  late int requiredLegendsAttacks = 0;
  late int requiredClanGamesPoints = 0;
  late int requiredRaidsAttacks = 0;
  late int requiredSeasonPass = 0;
  late int requiredCwlAttacks = 0;
  late int requiredWarAttacks = 0;
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
    totalDone = 0;
    totalEvent = 0;

    totalLegends =
        items.fold(0, (sum, item) => sum + (item.legends?.numAttacks ?? 0));
    totalSeasonPass = items.fold(0, (sum, item) => sum + item.seasonPass);
    totalRaidsAttacks =
        items.fold(0, (sum, item) => sum + item.raids.attacksDone);
    totalCwlAttacks = items.fold(0, (sum, item) => sum + item.cwl.attacksDone);
    totalClanGamesPoints =
        items.fold(0, (sum, item) => sum + item.clanGames.points);
    totalWarAttacks =
        items.fold(0, (sum, item) => sum + (item.war?.attacksDone ?? 0));

    numberAccounts = items.length;

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
          totalEvent += 8;
          totalDone +=
              item.legends != null ? item.legends!.numAttacks.toDouble() : 0;
          requiredLegendsAttacks += 8;
        }

        // War attacks completed
        if (item.war != null && item.war!.attackLimit != 0) {
          totalEvent += item.war!.attackLimit;
          totalDone += item.war!.attacksDone.toDouble();
          requiredWarAttacks += item.war!.attackLimit;
        }

        // CWL attacks completed
        if (item.cwl.attackLimit != 0) {
          totalEvent += item.cwl.attackLimit;
          totalDone += item.cwl.attacksDone.toDouble();
          requiredCwlAttacks += item.cwl.attackLimit;
        }

        // Clan games completed
        if (isInTimeFrameForClanGames) {
          DateTime now = DateTime.now();
          DateTime clanGamesStart =
              DateTime(now.year, now.month, 22, 8); // Start of Clan Games
          int daysPassed = now.difference(clanGamesStart).inDays + 1;
          double clanGamesDaily =
              (4000 / 8) * daysPassed; // Total points divided by days
          double clanGamesRatio =
              (item.clanGames.points.toDouble() / clanGamesDaily) > 1
                  ? 1
                  : item.clanGames.points.toDouble() / clanGamesDaily;
          totalEvent += 2;
          totalDone += clanGamesRatio * 2;
          requiredClanGamesPoints += 4000;
        }

        // Raids completed
        if (isInTimeFrameForRaid) {
          totalEvent += item.raids.attackLimit == 0
              ? 5
              : item.raids
                  .attackLimit; // Assuming default raid attacks limit is 5
          totalDone += item.raids.attacksDone.toDouble();
          requiredRaidsAttacks +=
              item.raids.attackLimit == 0 ? 5 : item.raids.attackLimit;
        }

        // Season pass completed
        DateTime now = DateTime.now();
        int totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
        int daysPassed = now.day;
        double seasonPassDaily = ((daysPassed * 2600) / totalDaysInMonth);
        double seasonPassRatio =
            (item.seasonPass.toDouble() / seasonPassDaily) > 1
                ? 1
                : (item.seasonPass.toDouble() / seasonPassDaily);
        totalEvent += 2;
        totalDone += seasonPassRatio.toDouble() * 2;
        requiredSeasonPass += 2600;
      } else {
        numberInactiveAccounts++;
      }
    }

    // Calculate overall percentage done
    if (totalEvent > 0) {
      percentageDone = ((totalDone / totalEvent) * 100).toInt();
    } else {
      percentageDone = 0; // No events, so 0% done
    }

    isInitialized = true;
  }

  static Future<ToDoList> fromJson(Map<String, dynamic> json) async {
    var itemList = json['items'] != null
        ? await Future.wait(
            (json['items'] as List).map((itemJson) async {
              return await ToDo.createToDoFromJson(itemJson);
            }).toList(),
          )
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
