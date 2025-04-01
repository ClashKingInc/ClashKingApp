import 'package:clashkingapp/features/player/models/player_legend_season.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PlayerLegendStats {
  final Map<String, PlayerLegendSeason> seasons;

  PlayerLegendStats({required this.seasons});

  factory PlayerLegendStats.fromJson(Map<String, dynamic> json) {
    return PlayerLegendStats(
      seasons: json.map(
        (key, value) => MapEntry(key, PlayerLegendSeason.fromJson(value)),
      ),
    );
  }

  List<PlayerLegendSeason> get allSeasons => seasons.values.toList();

  PlayerLegendSeason? get currentSeason {
    final now = DateTime.now();
    return seasons.values.firstWhere((season) =>
        now.isAfter(season.start) &&
        now.isBefore(season.end.add(Duration(days: 1))));
  }

  PlayerLegendSeason? getSpecificSeason(DateTime date) {
    try {
      return seasons.values.firstWhere(
        (season) =>
            (date.isAtSameMomentAs(season.start) ||
                date.isAfter(season.start)) &&
            (date.isAtSameMomentAs(season.end) || date.isBefore(season.end)),
      );
    } catch (_) {
      return null;
    }
  }

  static String convertToTimeAgo(int timestamp, context) {
    DateTime now = DateTime.now();
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    Duration diff = now.difference(date);

    if (diff.inDays >= 1) {
      return '${diff.inDays == 1 ? AppLocalizations.of(context)?.dayAgo(diff.inDays) : AppLocalizations.of(context)?.daysAgo(diff.inDays)}';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours == 1 ? AppLocalizations.of(context)?.hourAgo(diff.inHours) : AppLocalizations.of(context)?.hoursAgo(diff.inHours, "")}';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes == 1 ? AppLocalizations.of(context)?.minuteAgo(diff.inMinutes) : AppLocalizations.of(context)?.minutesAgo(diff.inMinutes)}';
    } else {
      return AppLocalizations.of(context)?.justNow ?? "Just now";
    }
  }
}
