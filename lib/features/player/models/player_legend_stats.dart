import 'package:clashkingapp/features/player/models/player_legend_season.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

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
    try {
      final now = DateTime.now();
      return seasons.values.firstWhere((season) =>
          now.isAfter(season.start) &&
          now.isBefore(season.end.add(Duration(days: 1))));
    } catch (_) {
      return null;
    }
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
      return '${diff.inDays == 1 ? AppLocalizations.of(context)?.timeDayAgo(diff.inDays) : AppLocalizations.of(context)?.timeDaysAgo(diff.inDays)}';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours == 1 ? AppLocalizations.of(context)?.timeHourAgo(diff.inHours) : AppLocalizations.of(context)?.timeHoursAgo(diff.inHours)}';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes == 1 ? AppLocalizations.of(context)?.timeMinuteAgo(diff.inMinutes) : AppLocalizations.of(context)?.timeMinutesAgo(diff.inMinutes)}';
    } else {
      return AppLocalizations.of(context)?.timeJustNow ?? "Just now";
    }
  }
}
