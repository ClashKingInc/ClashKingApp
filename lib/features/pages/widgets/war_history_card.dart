import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war_history/war_history_page.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:clashkingapp/common/widgets/buttons/chip.dart';

class WarHistoryCard extends StatelessWidget {
  final Clan clan;

  const WarHistoryCard(
      {super.key,
      required this.clan});

  @override
  Widget build(BuildContext context) {

    if (clan.clanWarLog == null) {
      return const SizedBox.shrink();
    }
    
    final warLogStats = clan.clanWarLog!.warLogStats;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WarHistoryScreen(
              clan: clan
            ),
          ),
        );
      },
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.labelLarge ?? TextStyle(),
        child: Card(
          margin: EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 70,
                  width: 70,
                  child: CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                      imageUrl:
                          "https://assets.clashk.ing/icons/Icon_HV_Clan_War.png"),
                ),
                SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                          AppLocalizations.of(context)!.warHistory,
                          style: Theme.of(context).textTheme.labelLarge),
                      Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 7.0,
                        runSpacing: -7.0,
                        children: [
                          CustomChip(
                            icon: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            labelPadding: 8,
                            label: warLogStats.totalWins.toString(),
                            description: AppLocalizations.of(context)!
                                .warHistoryWinsDescription(
                                    warLogStats.totalWins, warLogStats.winPercentage),
                          ),
                          CustomChip(
                            icon: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            labelPadding: 8,
                            label: warLogStats.totalLosses.toString(),
                            description: AppLocalizations.of(context)!
                                .warHistoryLossesDescription(
                                    warLogStats.totalLosses, warLogStats.lossPercentage),
                          ),
                          CustomChip(
                            icon: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                            labelPadding: 8,
                            label: warLogStats.totalTies.toString(),
                            description: AppLocalizations.of(context)!
                                .warHistoryDrawsDescription(
                                    warLogStats.totalTies, warLogStats.tiePercentage),
                          ),
                          ImageChip(
                            imageUrl:
                                "https://assets.clashk.ing/icons/Icon_HV_Attack_Star.png",
                            label: warLogStats.averageClanStarsPerMember
                                .toString(),
                            description: AppLocalizations.of(context)!
                                .warHistoryAverageWarStarsDescription(
                                    warLogStats.averageClanStarsPerMember, warLogStats.averageClanStarsPercentage.toStringAsFixed(2)),
                          ),
                          IconChip(
                            icon: LucideIcons.users,
                            size: 16,
                            label: warLogStats.averageMembers.toString(),
                            description: AppLocalizations.of(context)!
                                .warHistoryAverageMembersDescription(
                                    warLogStats.averageMembers),
                          ),
                          IconChip(
                            icon: LucideIcons.percent,
                            size: 16,
                            label:
                                warLogStats.averageClanDestruction.toString(),
                            description: AppLocalizations.of(context)!
                                .warHistoryAverageHitRateDescription(warLogStats
                                    .averageClanDestruction
                                    .toStringAsFixed(2)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
