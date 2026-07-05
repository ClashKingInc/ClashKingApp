import 'package:clashkingapp/common/widgets/inputs/filter_dropdown.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/models/clan_war_log.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war/war.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

const _warWinColor = Color(0xFF58C76A);
const _warLossColor = Color(0xFFFF5656);
const _warTieColor = Color(0xFF4EA6FF);

class WarLogHistoryTab extends StatefulWidget {
  final Clan clan;

  const WarLogHistoryTab({super.key, required this.clan});

  @override
  WarLogHistoryTabState createState() => WarLogHistoryTabState();
}

class WarLogHistoryTabState extends State<WarLogHistoryTab> {
  String? selectedFilter;

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

  List<WarLogDetails> getFilteredWarLogData() {
    List<WarLogDetails> filteredData = widget.clan.clanWarLog!.items
        .where((warLogDetail) => warLogDetail.attacksPerMember == 2)
        .toList();
    if (selectedFilter == null) {
      return filteredData;
    }

    switch (selectedFilter) {
      case 'victory':
        return filteredData
            .where((warLogDetail) => warLogDetail.result == 'win')
            .toList();
      case 'defeat':
        return filteredData
            .where((warLogDetail) => warLogDetail.result == 'lose')
            .toList();
      case 'draw':
        return filteredData
            .where((warLogDetail) => warLogDetail.result == 'tie')
            .toList();
      case 'perfectWar':
        return filteredData
            .where(
              (warLogDetail) =>
                  (warLogDetail.clan.destructionPercentage == 100 ||
                  warLogDetail.opponent.destructionPercentage == 100),
            )
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
        return filteredData
            .where((warLogDetail) => warLogDetail.teamSize == teamSize)
            .toList();
      default:
        return filteredData;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredWarLogData = getFilteredWarLogData();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Center(
            child: FilterDropdown(
              sortBy: selectedFilter ?? 'newest',
              updateSortBy: (String newValue) {
                setState(() {
                  selectedFilter = newValue;
                });
              },
              sortByOptions: {
                AppLocalizations.of(context)?.warEventsNewest ?? 'Newest':
                    'newest',
                AppLocalizations.of(context)?.warEventsOldest ?? 'Oldest':
                    'oldest',
                AppLocalizations.of(context)?.warVictory ?? 'Victory':
                    'victory',
                AppLocalizations.of(context)?.warDefeat ?? 'Defeat': 'defeat',
                AppLocalizations.of(context)?.warDraw ?? 'Draw': 'draw',
                AppLocalizations.of(context)?.warPerfectWar ?? 'Perfect War':
                    'perfectWar',
                '5v5': '5',
                '10v10': '10',
                '15v15': '15',
                '20v20': '20',
                '25v25': '25',
                '30v30': '30',
                '40v40': '40',
                '50v50': '50',
              },
              maxWidth: 150,
            ),
          ),
        ),
        if (filteredWarLogData.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Center(child: _WarLogSummary(clan: widget.clan)),
          ),
        ],
        filteredWarLogData.isEmpty
            ? Column(
                children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        AppLocalizations.of(context)?.generalNoDataAvailable ??
                            'No data available',
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                  CachedNetworkImage(
                    errorWidget: (context, url, error) => Icon(Icons.error),
                    imageUrl:
                        'https://assets.clashk.ing/stickers/Villager_HV_Villager_7.png',
                    height: 250,
                    width: 200,
                  ),
                ],
              )
            : buildAllLog(context, filteredWarLogData),
      ],
    );
  }

  Widget buildAllLog(BuildContext context, List<WarLogDetails> warLogData) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Column(
              children: List<Widget>.generate(warLogData.length, (index) {
                final warLogDetail = warLogData[index];
                final navigator = Navigator.of(context);

                return _WarLogCard(
                  detail: warLogDetail,
                  timeLabel: formatWarTime(warLogDetail.endTime, context),
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return Center(child: CircularProgressIndicator());
                      },
                    );
                    WarCwlService.fetchWarDataFromTime(
                          widget.clan.tag,
                          warLogDetail.endTime,
                        )
                        .then((currentWarInfo) {
                          navigator.pop();
                          if (currentWarInfo == null) {
                            if (context.mounted) {
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
                            }
                          } else {
                            navigator.push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    WarScreen(war: currentWarInfo),
                              ),
                            );
                          }
                        })
                        .catchError((error, stackTrace) {
                          Sentry.captureException(
                            error,
                            stackTrace: stackTrace,
                          );
                          return null;
                        });
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

class _WarLogSummary extends StatelessWidget {
  final Clan clan;

  const _WarLogSummary({required this.clan});

  @override
  Widget build(BuildContext context) {
    final publicRecord = clan.isWarLogPublic;
    final stats = <Widget>[
      _WarSummaryText(value: '${clan.warWins} wins', color: _warWinColor),
      if (publicRecord)
        _WarSummaryText(value: '${clan.warTies} ties', color: _warTieColor),
      if (publicRecord)
        _WarSummaryText(
          value: '${clan.warLosses} losses',
          color: _warLossColor,
        ),
      if (clan.warWinStreak > 0)
        _WarSummaryText(
          value: '${clan.warWinStreak} streak',
          color: const Color(0xFFE35D4F),
          icon: Icons.local_fire_department_rounded,
        ),
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 4,
      children: stats,
    );
  }
}

class _WarSummaryText extends StatelessWidget {
  final String value;
  final Color color;
  final IconData? icon;

  const _WarSummaryText({required this.value, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 3),
        ],
        Text(
          value,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _WarLogCard extends StatelessWidget {
  final WarLogDetails detail;
  final String timeLabel;
  final VoidCallback onTap;

  const _WarLogCard({
    required this.detail,
    required this.timeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                  badgeUrl: detail.clan.badgeUrls.large,
                  name: detail.clan.name,
                ),
              ),
              SizedBox(
                width: 132,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _WarMiniPill(
                      value: '${detail.teamSize}v${detail.teamSize}',
                    ),
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
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _WarScoreText(
                        ownStars: detail.clan.stars,
                        opponentStars: detail.opponent.stars,
                        result: detail.result,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_formatPercent(detail.clan.destructionPercentage)} - ${_formatPercent(detail.opponent.destructionPercentage)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _WarMiniPill(
                      value: '+${detail.clan.expEarned}',
                      imageUrl: ImageAssets.xp,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _WarClanSide(
                  badgeUrl: detail.opponent.badgeUrls.large,
                  name: detail.opponent.name,
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
      'win' => _warWinColor,
      'tie' => _warTieColor,
      _ => colorScheme.onSurface,
    };
    final opponentColor = switch (result) {
      'lose' => _warLossColor,
      'tie' => _warTieColor,
      _ => colorScheme.onSurface,
    };
    final separatorColor = result == 'tie'
        ? _warTieColor
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
        CachedNetworkImage(
          errorWidget: (context, url, error) => const Icon(Icons.error),
          imageUrl: badgeUrl,
          width: 48,
          height: 48,
        ),
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

    return SizedBox(
      width: 76,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageUrl != null)
              CachedNetworkImage(
                errorWidget: (context, url, error) => const Icon(Icons.error),
                imageUrl: imageUrl!,
                width: 15,
                height: 15,
              ),
            if (imageUrl != null) const SizedBox(width: 4),
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
      ),
    );
  }
}
