import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/summary_chips.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:clashkingapp/features/war_cwl/models/war_clan.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war/war.dart';
import 'package:clashkingapp/common/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class ClanWarLog extends StatelessWidget {
  final Clan clan;
  final List<String> selectedTypes;
  final String? selectedFilter;
  final String searchQuery;

  const ClanWarLog({
    super.key,
    required this.clan,
    required this.selectedTypes,
    required this.selectedFilter,
    required this.searchQuery,
  });

  String formatWarTime(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (!difference.isNegative) {
      if (difference.inHours < 1) {
        final minutes = difference.inMinutes.clamp(1, 59);
        return '${minutes}m ago';
      }
      if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      }
      if (difference.inDays < 30) {
        return difference.inDays == 1
            ? '1 day ago'
            : '${difference.inDays} days ago';
      }
      if (difference.inDays < 60) {
        return '1 month ago';
      }
    }

    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).format(date);
  }

  List<WarInfo> getFilteredWarLogData() {
    List<WarInfo> filteredData =
        clan.clanWarStats?.wars
            .where(
              (war) =>
                  war.warDetails.warType != null &&
                  selectedTypes.contains(war.warDetails.warType!.toLowerCase()),
            )
            .map((war) => war.warDetails)
            .toList() ??
        [];

    final normalizedSearch = searchQuery.trim().toLowerCase();
    if (normalizedSearch.isNotEmpty) {
      filteredData = filteredData.where((war) {
        return _matchesWarSide(war.clan, normalizedSearch) ||
            _matchesWarSide(war.opponent, normalizedSearch);
      }).toList();
    }

    if (selectedFilter == null) {
      return filteredData;
    }

    switch (selectedFilter) {
      case 'victory':
        return filteredData
            .where((war) => war.getWarResult(clan.tag) == 'won')
            .toList();
      case 'defeat':
        return filteredData
            .where((war) => war.getWarResult(clan.tag) == 'lost')
            .toList();
      case 'draw':
        return filteredData
            .where((war) => war.getWarResult(clan.tag) == 'tie')
            .toList();
      case 'perfectWar':
        return filteredData
            .where((war) => war.getWarResult(clan.tag) == 'perfectWar')
            .toList();
      case 'newest':
        return filteredData;
      case 'oldest':
        return filteredData.reversed.toList();
      case '5':
      case '10':
      case '15':
      case '20':
      case '25':
      case '30':
      case '40':
      case '50':
        final teamSize = int.parse(selectedFilter!);
        return filteredData.where((war) => war.teamSize == teamSize).toList();
      default:
        return filteredData;
    }
  }

  bool _matchesWarSide(WarClan? side, String query) {
    if (side == null) return false;
    final name = side.name.toLowerCase();
    final tag = side.tag.toLowerCase();
    return name.contains(query) || tag.contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final filteredWarLogData = getFilteredWarLogData();

    return Column(
      children: [
        filteredWarLogData.isEmpty
            ? AppEmptyState(
                title: AppLocalizations.of(context)!.generalNoDataAvailable,
                body: searchQuery.trim().isNotEmpty
                    ? AppLocalizations.of(context)!.generalAdjustFilters
                    : null,
                icon: searchQuery.trim().isNotEmpty
                    ? Icons.search_off_rounded
                    : Icons.history_toggle_off_rounded,
                stickerHeight: 250,
                stickerWidth: 200,
              )
            : buildAllLog(context, filteredWarLogData, clan.tag),
      ],
    );
  }

  Widget buildAllLog(
    BuildContext context,
    List<WarInfo> warLogData,
    String clanTag,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: 2),
          Center(
            child: Column(
              children: List<Widget>.generate(warLogData.length, (index) {
                final war = warLogData[index];
                final navigator = Navigator.of(context);

                return _WarLogEntryCard(
                  war: war,
                  clanTag: clanTag,
                  timeLabel: formatWarTime(
                    war.endTime ?? DateTime.now(),
                    context,
                  ),
                  expEarned: _findExpEarned(clan, war, clanTag),
                  onTap: () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return Center(child: CircularProgressIndicator());
                      },
                    );
                    try {
                      final currentWarInfo =
                          await WarCwlService.fetchWarDataFromTime(
                            clan.tag,
                            war.endTime ?? DateTime.now(),
                          );
                      if (!context.mounted) return;
                      navigator.pop();
                      if (currentWarInfo == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Center(
                              child: Text(
                                AppLocalizations.of(
                                      context,
                                    )?.warNoDataAvailableForThisWar ??
                                    'No data available for this war',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            duration: Duration(seconds: 1),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surface,
                          ),
                        );
                        return;
                      }
                      navigator.push(
                        MaterialPageRoute(
                          builder: (context) => WarScreen(war: currentWarInfo),
                        ),
                      );
                    } catch (error, stackTrace) {
                      Sentry.captureException(error, stackTrace: stackTrace);
                      if (!context.mounted) return;
                      navigator.pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Center(
                            child: Text(
                              AppLocalizations.of(
                                    context,
                                  )?.warNoDataAvailableForThisWar ??
                                  'No data available for this war',
                            ),
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// The bulk war-stats endpoint (`clan.clanWarStats`) that feeds this log
/// doesn't carry exp gained. The clan's raw CoC warlog (`clan.clanWarLog`,
/// fetched separately and much shorter) does — so look up a match there by
/// end time when one exists, rather than fetching a second data source.
int? _findExpEarned(Clan clan, WarInfo war, String clanTag) {
  final items = clan.clanWarLog?.items;
  final endTime = war.endTime;
  if (items == null || endTime == null) return null;

  for (final item in items) {
    if (item.endTime.difference(endTime).abs() > const Duration(minutes: 2)) {
      continue;
    }
    if (item.clan.tag == clanTag) return item.clan.expEarned;
    if (item.opponent.tag == clanTag) return item.opponent.expEarned;
  }
  return null;
}

/// Win/tie/loss + streak summary for the clan's war log, shown next to
/// the sort dropdown above the log list.
class WarLogSummary extends StatelessWidget {
  final Clan clan;

  const WarLogSummary({super.key, required this.clan});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final publicRecord = clan.isWarLogPublic;
    final stats = <Widget>[
      ClanSummaryChip(
        label: loc.warWinsTitle,
        value: clan.warWins.toString(),
        color: StatColors.win,
      ),
      if (publicRecord)
        ClanSummaryChip(
          label: loc.warDrawsTitle,
          value: clan.warTies.toString(),
          color: StatColors.tie,
        ),
      if (publicRecord)
        ClanSummaryChip(
          label: loc.warLossesTitle,
          value: clan.warLosses.toString(),
          color: StatColors.loss,
        ),
      if (clan.warWinStreak > 0)
        ClanSummaryChip(
          label: loc.clanWinStreakTitle,
          value: clan.warWinStreak.toString(),
          color: const Color(0xFFE35D4F),
          icon: Icons.local_fire_department_rounded,
        ),
    ];

    return ClanSummaryChips(padding: EdgeInsets.zero, children: stats);
  }
}

class _WarLogEntryCard extends StatelessWidget {
  final WarInfo war;
  final String clanTag;
  final String timeLabel;
  final int? expEarned;
  final VoidCallback onTap;

  const _WarLogEntryCard({
    required this.war,
    required this.clanTag,
    required this.timeLabel,
    this.expEarned,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isUs = war.clan?.tag == clanTag;
    final own = isUs ? war.clan : war.opponent;
    final enemy = isUs ? war.opponent : war.clan;
    if (own == null || enemy == null) return const SizedBox.shrink();

    final weWon =
        own.stars > enemy.stars ||
        (own.stars == enemy.stars &&
            own.destructionPercentage > enemy.destructionPercentage);
    final weLost =
        own.stars < enemy.stars ||
        (own.stars == enemy.stars &&
            own.destructionPercentage < enemy.destructionPercentage);
    final result = weWon ? 'win' : (weLost ? 'lose' : 'tie');
    final loc = AppLocalizations.of(context);
    final resultLabel = switch (result) {
      'win' => loc?.warVictory ?? 'Victory',
      'lose' => loc?.warDefeat ?? 'Defeat',
      _ => loc?.warDraw ?? 'Draw',
    };
    final resultColor = switch (result) {
      'win' => StatColors.win,
      'lose' => StatColors.loss,
      _ => StatColors.tie,
    };

    return Material(
      color: theme.cardTheme.color ?? colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _WarClanSide(
                  badgeUrl: own.badgeUrls.large,
                  name: own.name,
                ),
              ),
              SizedBox(
                width: 120,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (war.teamSize != null)
                      _WarMiniPill(value: '${war.teamSize}v${war.teamSize}'),
                    const SizedBox(height: 5),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        timeLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _WarResultPill(label: resultLabel, color: resultColor),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _WarScoreText(
                        ownStars: own.stars,
                        opponentStars: enemy.stars,
                        result: result,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_formatPercent(own.destructionPercentage)} - ${_formatPercent(enemy.destructionPercentage)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (expEarned != null) ...[
                      const SizedBox(height: 6),
                      _WarMiniPill(
                        value: '+$expEarned',
                        imageUrl: ImageAssets.xp,
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: _WarClanSide(
                  badgeUrl: enemy.badgeUrls.large,
                  name: enemy.name,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPercent(double value) {
    return value % 1 == 0
        ? '${value.toInt()}%'
        : '${value.toStringAsFixed(2)}%';
  }
}

class _WarResultPill extends StatelessWidget {
  final String label;
  final Color color;

  const _WarResultPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _WarScoreText extends StatelessWidget {
  final int ownStars;
  final int opponentStars;
  final String result;

  const _WarScoreText({
    required this.ownStars,
    required this.opponentStars,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final baseStyle = theme.textTheme.titleLarge?.copyWith(
      fontSize: (theme.textTheme.titleLarge?.fontSize ?? 22) * 1.05,
      color: colorScheme.onSurface,
      fontWeight: FontWeight.w900,
      height: 1,
    );
    final ownColor = switch (result) {
      'win' => StatColors.win,
      'tie' => StatColors.tie,
      _ => colorScheme.onSurface,
    };
    final opponentColor = switch (result) {
      'lose' => StatColors.loss,
      'tie' => StatColors.tie,
      _ => colorScheme.onSurface,
    };
    final separatorColor = result == 'tie'
        ? StatColors.tie
        : colorScheme.onSurface;

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(
            text: '$ownStars',
            style: TextStyle(color: ownColor),
          ),
          TextSpan(
            text: ' - ',
            style: TextStyle(color: separatorColor),
          ),
          TextSpan(
            text: '$opponentStars',
            style: TextStyle(color: opponentColor),
          ),
        ],
      ),
    );
  }
}

class _WarClanSide extends StatelessWidget {
  final String badgeUrl;
  final String name;

  const _WarClanSide({required this.badgeUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MobileWebImage(imageUrl: badgeUrl, width: 48, height: 48),
        const SizedBox(height: 6),
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _WarMiniPill extends StatelessWidget {
  final String value;
  final String? imageUrl;

  const _WarMiniPill({required this.value, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageUrl != null) ...[
            MobileWebImage(imageUrl: imageUrl!, width: 13, height: 13),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
