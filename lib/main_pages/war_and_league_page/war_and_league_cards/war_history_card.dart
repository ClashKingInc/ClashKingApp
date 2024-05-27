import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/api/war_log.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/api/player_account_info.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_history/war_history_page.dart';
import 'package:lucide_icons/lucide_icons.dart';

class WarHistoryCard extends StatelessWidget {
  final PlayerAccountInfo playerStats;
  final List<String> discordUser;
  final List<WarLogDetails> warLogData;
  final Map<String, String> warLogStats;

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
            ),
          ),
        );
      },
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.labelLarge ?? TextStyle(),
        child: Card(
          margin: EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 8),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 70,
                  width: 70,
                  child: CachedNetworkImage(
                      imageUrl:
                          "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Clan_War.png"),
                ),
                SizedBox(width: 12),
                Expanded(
                  // Wrap the Column in an Expanded widget
                  child: Column(
                    children: [
                      Text(
                          AppLocalizations.of(context)?.warHistory ??
                              'War History',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelLarge),
                      Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 7.0,
                        runSpacing: -7.0,
                        children: [
                          Chip(
                            avatar: CircleAvatar(
                              backgroundColor: Colors.transparent,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            label: Text(warLogStats['totalWins'] ?? '0',
                                style: Theme.of(context).textTheme.labelLarge),
                          ),
                          Chip(
                            avatar: CircleAvatar(
                              backgroundColor: Colors.transparent,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            label: Text(warLogStats['totalLosses'] ?? '0',
                                style: Theme.of(context).textTheme.labelLarge),
                          ),
                          Chip(
                            avatar: CircleAvatar(
                              backgroundColor: Colors.transparent,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            label: Text(warLogStats['totalTies'] ?? '0',
                                style: Theme.of(context).textTheme.labelLarge),
                          ),
                          Chip(
                            avatar: CircleAvatar(
                              backgroundColor: Colors.transparent,
                              child: Icon(LucideIcons.users,
                                  size: 16,
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                            ),
                            label: Text(warLogStats['averageMembers'] ?? '0',
                                style: Theme.of(context).textTheme.labelLarge),
                          ),
                          Chip(
                            avatar: CircleAvatar(
                              backgroundColor: Colors.transparent,
                              child: Icon(LucideIcons.star,
                                  size: 16,
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                            ),
                            label: Text(
                                warLogStats['averageClanStarsPerMember'] ?? '0',
                                style: Theme.of(context).textTheme.labelLarge),
                          ),
                          Chip(
                            avatar: CircleAvatar(
                              backgroundColor: Colors.transparent,
                              child: Icon(LucideIcons.percent,
                                  size: 16,
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                            ),
                            label: Text(
                                warLogStats['averageClanDestruction'] ?? '0',
                                style: Theme.of(context).textTheme.labelLarge),
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
