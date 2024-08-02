import 'package:clashkingapp/classes/profile/legend/legend_day.dart';

class SeasonTrophies {
  final DateTime seasonStart;
  final DateTime seasonEnd;
  final List<LegendDay> seasonLegendDays;
  final int totalAttacks;
  final int totalDefenses;
  final int totalAttacksTrophies;
  final int totalDefensesTrophies;
  final int totalTrophies;
  final int totalDays;
  final int seasonDuration;
  final int averageAttacksTrophies;
  final int averageDefensesTrophies;
  final double percentageThreeStarsAttacks;
  final double percentageThreeStarsDefenses;
  final double percentageTwoStarsAttacks;
  final double percentageTwoStarsDefenses;
  final double percentageOneStarsAttacks;
  final double percentageOneStarsDefenses;
  final double percentageNoStarsAttacks;
  final double percentageNoStarsDefenses;

  SeasonTrophies(
      {required this.seasonStart,
      required this.seasonEnd,
      required this.seasonDuration,
      required this.seasonLegendDays,
      required this.totalAttacks,
      required this.totalDefenses,
      required this.totalAttacksTrophies,
      required this.totalDefensesTrophies,
      required this.totalTrophies,
      required this.totalDays,
      required this.averageAttacksTrophies,
      required this.averageDefensesTrophies,
      required this.percentageNoStarsAttacks,
      required this.percentageNoStarsDefenses,
      required this.percentageOneStarsAttacks,
      required this.percentageOneStarsDefenses,
      required this.percentageTwoStarsAttacks,
      required this.percentageTwoStarsDefenses,
      required this.percentageThreeStarsAttacks,
      required this.percentageThreeStarsDefenses});

  bool get isEmpty => seasonLegendDays.isEmpty;

  @override
  String toString() =>
      'SeasonTrophies(seasonStart: $seasonStart, seasonLegendDays: $seasonLegendDays, totalAttacks: $totalAttacks, totalDefenses: $totalDefenses, totalAttacksTrophies: $totalAttacksTrophies, totalDefensesTrophies: $totalDefensesTrophies, totalTrophies: $totalTrophies, totalDays: $totalDays, seasonDuration: $seasonDuration, averageAttacksTrophies: $averageAttacksTrophies, averageDefensesTrophies: $averageDefensesTrophies, percentageThreeStarsAttacks: $percentageThreeStarsAttacks, percentageThreeStarsDefenses: $percentageThreeStarsDefenses, percentageTwoStarsAttacks: $percentageTwoStarsAttacks, percentageTwoStarsDefenses: $percentageTwoStarsDefenses, percentageOneStarsAttacks: $percentageOneStarsAttacks, percentageOneStarsDefenses: $percentageOneStarsDefenses, percentageNoStarsAttacks: $percentageNoStarsAttacks, percentageNoStarsDefenses: $percentageNoStarsDefenses)';
}
