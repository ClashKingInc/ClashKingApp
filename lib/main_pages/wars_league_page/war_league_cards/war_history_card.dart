import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/classes/clan/war_league/war_log.dart';
import 'package:clashkingapp/classes/profile/profile_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war_history/war_history_page.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:clashkingapp/components/chip.dart';

class WarHistoryCard extends StatelessWidget {
  final ProfileInfo playerStats;
  final List<String> discordUser;
  final List<WarLogDetails> warLogData;
  final WarLogStats warLogStats;

  const WarHistoryCard(
      {super.key,
      required this.warLogStats,
      required this.playerStats,
      required this.discordUser,
      required this.warLogData});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WarHistoryScreen(
              clanTag: playerStats.clan!.tag,
              discordUser: discordUser,
              warLogData: warLogData,
              warLogStats: warLogStats,
              clanName: playerStats.clan!.name,
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
                      imageUrl:
                          "https://assets.clashk.ing/icons/Icon_HV_Clan_War.png"),
                ),
                SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
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
                                    warLogStats.totalWins),
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
                                    warLogStats.totalLosses),
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
                                    warLogStats.totalTies),
                          ),
                          ImageChip(
                            imageUrl:
                                "https://assets.clashk.ing/icons/Icon_HV_Attack_Star.png",
                            label: warLogStats.averageClanStarsPerMember
                                .toString(),
                            description: AppLocalizations.of(context)!
                                .warHistoryAverageWarStarsDescription(
                                    warLogStats.averageClanStarsPerMember),
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
