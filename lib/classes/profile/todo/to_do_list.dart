import 'package:clashkingapp/classes/profile/todo/to_do.dart';

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
  late final int percentageDone;

  ToDoList({required this.items}) {
    final nowUtc = DateTime.now().toUtc();
    isInTimeFrameForRaid =
        (nowUtc.weekday == DateTime.friday && nowUtc.hour >= 6) ||
            (nowUtc.weekday == DateTime.saturday ||
                nowUtc.weekday == DateTime.sunday) ||
            (nowUtc.weekday == DateTime.monday && nowUtc.hour < 6);
    isInTimeFrameForClanGames = (nowUtc.day >= 22 && nowUtc.hour >= 8) &&
        (nowUtc.day <= 28 && nowUtc.hour <= 8);
    _calculateTotals();
  }

  void _calculateTotals() {
    totalLegends =
        items.fold(0, (sum, item) => sum + (item.legends?.numAttacks ?? 0));
    totalSeasonPass = items.fold(0, (sum, item) => sum + item.seasonPass);
    totalRaidsAttacks =
        items.fold(0, (sum, item) => sum + item.raids.attacksDone);
    totalCwlAttacks = items.fold(0, (sum, item) => sum + item.cwl.attacksDone);
    totalClanGamesPoints =
        items.fold(0, (sum, item) => sum + item.clanGames.points);

    numberAccounts = items.length;

    int totalDone = 0;
    int totalEvent = 0;

    for (ToDo item in items) {
      // Legend completed
      if (item.legends != null) {
        totalEvent += 100;
        double legendRatio = item.legends!.numAttacks / 8;
        totalDone += (legendRatio * 100).toInt();
      }

      // Clan games completed
      if (isInTimeFrameForClanGames) {
        totalEvent += 100;
        double clanGamesRatio = item.clanGames.points / 4000;
        totalDone += (clanGamesRatio * 100).toInt();
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
      }

      // Season pass completed
      totalEvent += 100;
      double seasonPassRatio = item.seasonPass.toDouble() / 2600;
      totalDone += (seasonPassRatio * 100).toInt();
    }

    // Calculate overall percentage done
    if (totalEvent > 0) {
      percentageDone = (totalDone / totalEvent * 100).toInt();
    } else {
      percentageDone = 0; // No events, so 0% done
    }
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
}
