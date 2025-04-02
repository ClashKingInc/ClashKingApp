import 'package:clashkingapp/features/player/models/player_legend_day.dart';

class PlayerLegendSeason {
  final DateTime start;
  final DateTime end;
  final int dayOfSeason;
  final int duration;
  final int daysInLegend;
  final int endTrophies;
  final int trophiesGainedTotal;
  final int trophiesLostTotal;
  final int trophiesNet;
  final int trophiesNetRevised;
  final int totalAttacks;
  final int totalDefenses;
  final double avgGainedPerAttack;
  final double avgLostPerDefense;
  final int totalPossible;
  final int gainedLostPossible;
  final double gainedRatio;
  final double lostRatio;
  final double attackRatio;
  final double defenseRatio;
  final Map<String, PlayerLegendDay> days;

  final Map<int, int> attackStarsDistribution;
  final Map<int, int> defenseStarsDistribution;
  final Map<int, double> attackStarsDistributionPercentages;
  final Map<int, double> defenseStarsDistributionPercentages;

  PlayerLegendDay? get currentDay {
    final now = DateTime.now().toUtc();
    final adjusted = now.hour < 5 ? now.subtract(const Duration(days: 1)) : now;
    final todayKey = adjusted.toIso8601String().split("T").first;
    return days[todayKey];
  }

  PlayerLegendSeason({
    required this.start,
    required this.end,
    required this.dayOfSeason,
    required this.duration,
    required this.daysInLegend,
    required this.endTrophies,
    required this.trophiesGainedTotal,
    required this.trophiesLostTotal,
    required this.trophiesNet,
    required this.trophiesNetRevised,
    required this.totalAttacks,
    required this.totalDefenses,
    required this.avgGainedPerAttack,
    required this.avgLostPerDefense,
    required this.totalPossible,
    required this.gainedLostPossible,
    required this.gainedRatio,
    required this.lostRatio,
    required this.attackRatio,
    required this.defenseRatio,
    required this.days,
    required this.attackStarsDistribution,
    required this.defenseStarsDistribution,
    required this.attackStarsDistributionPercentages,
    required this.defenseStarsDistributionPercentages,
  });

  factory PlayerLegendSeason.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> attackPercentJson =
        json['season_stars_distribution_attacks_percentages'] ?? {};
    Map<String, dynamic> defensePercentJson =
        json['season_stars_distribution_defenses_percentages'] ?? {};

    return PlayerLegendSeason(
      start: DateTime.parse(json['season_start']),
      end: DateTime.parse(json['season_end']),
      duration: json['season_duration'] ?? 0,
      daysInLegend: json['season_days_in_legend'] ?? 0,
      dayOfSeason: DateTime.now()
                  .difference(DateTime.parse(json['season_start']))
                  .inDays + 1>
              json['season_duration']
          ? json['season_duration']
          : DateTime.now()
              .difference(DateTime.parse(json['season_start']))
              .inDays + 1,
      endTrophies: json['season_end_trophies'] ?? 0,
      trophiesGainedTotal: json['season_trophies_gained_total'] ?? 0,
      trophiesLostTotal: json['season_trophies_lost_total'] ?? 0,
      trophiesNet: json['season_trophies_net'] ?? 0,
      trophiesNetRevised:
          5000 - (json['season_trophies_net_revised'] ?? 0) as int,
      totalAttacks: json['season_total_attacks'] ?? 0,
      totalDefenses: json['season_total_defenses'] ?? 0,
      avgGainedPerAttack:
          (json['season_average_trophies_gained_per_attack'] ?? 0).toDouble(),
      avgLostPerDefense:
          (json['season_average_trophies_lost_per_defense'] ?? 0).toDouble(),
      totalPossible: json['season_total_attacks_defenses_possible'] ?? 0,
      gainedLostPossible: json['season_total_gained_lost_possible'] ?? 0,
      gainedRatio: (json['season_trophies_gained_ratio'] ?? 0).toDouble(),
      lostRatio: (json['season_trophies_lost_ratio'] ?? 0).toDouble(),
      attackRatio: (json['season_total_attacks_ratio'] ?? 0).toDouble(),
      defenseRatio: (json['season_total_defenses_ratio'] ?? 0).toDouble(),
      days: (json['days'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, PlayerLegendDay.fromJson(value)),
          ) ??
          {},
      attackStarsDistribution: Map<int, int>.from(
        (json['season_stars_distribution_attacks'] ?? {})
            .map((key, value) => MapEntry(int.parse(key), value)),
      ),
      defenseStarsDistribution: Map<int, int>.from(
        (json['season_stars_distribution_defenses'] ?? {})
            .map((key, value) => MapEntry(int.parse(key), value)),
      ),
      attackStarsDistributionPercentages: Map<int, double>.from(
        attackPercentJson
            .map((key, value) => MapEntry(int.parse(key), value.toDouble())),
      ),
      defenseStarsDistributionPercentages: Map<int, double>.from(
        defensePercentJson
            .map((key, value) => MapEntry(int.parse(key), value.toDouble())),
      ),
    );
  }
}
