import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/classes/clan/clan_info.dart';
import 'package:clashkingapp/classes/clan/war_league/member_war_stats.dart';
import 'package:clashkingapp/classes/clan/war_league/war_log.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war_history/war_history_players.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';

class WarLogHistoryStats extends StatefulWidget {
  final Clan clan;
  final List<String> discordUser;
  final List<WarLogDetails> warLogData;
  final WarLogStats warLogStats;

  WarLogHistoryStats(
      {super.key,
      required this.clan,
      required this.discordUser,
      required this.warLogData,
      required this.warLogStats});

  @override
  WarLogHistoryStatsState createState() => WarLogHistoryStatsState();
}

class WarLogHistoryStatsState extends State<WarLogHistoryStats>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.all(2),
          child: SizedBox(
            width: double.infinity,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(AppLocalizations.of(context)!.warStats,
                        style: Theme.of(context).textTheme.titleSmall),
                    SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.users, size: 16),
                            SizedBox(width: 8),
                            Text(
                                "~${widget.warLogStats.averageMembers.toStringAsFixed(0)}",
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.percent, size: 16),
                            SizedBox(width: 8),
                            Text(
                                widget.warLogStats
                                            .averageDestructionDifference >
                                        0
                                    ? "+${widget.warLogStats.averageDestructionDifference.toStringAsFixed(2)}"
                                    : widget.warLogStats
                                        .averageDestructionDifference
                                        .toStringAsFixed(2),
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(2),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        Text(AppLocalizations.of(context)!.attacks,
                            style: Theme.of(context).textTheme.bodyLarge),
                        SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.warStats,
                                style: Theme.of(context).textTheme.bodyMedium),
                            Row(
                              children: [
                                Icon(LucideIcons.percent, size: 16),
                                SizedBox(width: 8),
                                Text(
                                    widget
                                        .warLogStats.averageClanStarsPercentage
                                        .toStringAsFixed(2),
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(AppLocalizations.of(context)!.membersStats,
                                style: Theme.of(context).textTheme.bodyMedium),
                            Row(
                              children: [
                                CachedNetworkImage(
                                    imageUrl:
                                        "https://assets.clashk.ing/icons/Icon_HV_Attack_Star.png",
                                    height: 16),
                                SizedBox(width: 8),
                                Text(
                                    widget.warLogStats.averageClanStarsPerMember
                                        .toStringAsFixed(2),
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                            Row(
                              children: [
                                CachedNetworkImage(
                                    imageUrl:
                                        "https://assets.clashk.ing/icons/Icon_HV_Sword.png",
                                    height: 16),
                                SizedBox(width: 8),
                                Text(
                                    widget.warLogStats.averageAttacksPerMember
                                        .toStringAsFixed(2),
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(2),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        Text(AppLocalizations.of(context)!.defenses,
                            style: Theme.of(context).textTheme.bodyLarge),
                        SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.warStats,
                                style: Theme.of(context).textTheme.bodyMedium),
                            Row(
                              children: [
                                Icon(LucideIcons.percent, size: 16),
                                SizedBox(width: 8),
                                Text(
                                    widget.warLogStats
                                        .averageOpponentStarsPercentage
                                        .toStringAsFixed(2),
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(AppLocalizations.of(context)!.membersStats,
                                style: Theme.of(context).textTheme.bodyMedium),
                            Row(
                              children: [
                                CachedNetworkImage(
                                    imageUrl:
                                        "https://assets.clashk.ing/icons/Icon_HV_Attack_Star.png",
                                    height: 16),
                                SizedBox(width: 8),
                                Text(
                                    widget.warLogStats
                                        .averageOpponentStarsPerMember
                                        .toStringAsFixed(2),
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                            Row(
                              children: [
                                Text(" ",
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.all(2),
          child: SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () async {
                final navigator = Navigator.of(context);
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                );
                try {
                  if (widget.clan.membersWarStats == null) {
                    print("Fetching members war stats");
                    widget.clan.membersWarStats = await MembersWarStatsService()
                        .fetchWarLogsAndAnalyzeStats(widget.clan.tag);
                  }
                  navigator.pop();
                  navigator.push(
                    MaterialPageRoute(
                      builder: (context) => PlayersWarHistoryScreen(
                          clan: widget.clan, discordUser: widget.discordUser),
                    ),
                  );
                } catch (error) {
                  navigator.pop();
                  print("An error occurred: $error");
                }
              },
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        flex: 2,
                        child: CachedNetworkImage(
                          imageUrl:
                              'https://assets.clashk.ing/stickers/Villager_HV_Villager_7.png',
                          height: 90,
                          width: 90,
                        ),
                      ),
                      Expanded(
                        flex: 6,
                        child: Text(AppLocalizations.of(context)!.membersStats,
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center),
                      ),
                      Expanded(
                        flex: 2,
                        child: Icon(LucideIcons.chevronRight, size: 24),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
