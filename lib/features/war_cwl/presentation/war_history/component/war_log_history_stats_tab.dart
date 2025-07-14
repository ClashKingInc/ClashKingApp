import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/common/widgets/labels/beta_label.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';

class WarLogHistoryStats extends StatefulWidget {
  final Clan clan;

  WarLogHistoryStats(
      {super.key,
      required this.clan});

  @override
  WarLogHistoryStatsState createState() => WarLogHistoryStatsState();
}

class WarLogHistoryStatsState extends State<WarLogHistoryStats>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final warLogStats = widget.clan.clanWarLog!.warLogStats;
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
                                "~${warLogStats.averageMembers.toStringAsFixed(0)}",
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.percent, size: 16),
                            SizedBox(width: 8),
                            Text(
                                warLogStats
                                            .averageDestructionDifference >
                                        0
                                    ? "+${warLogStats.averageDestructionDifference.toStringAsFixed(2)}"
                                    : warLogStats
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
                        Text(AppLocalizations.of(context)!.warAttacksTitle,
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
                                    warLogStats.averageClanDestruction
                                        .toStringAsFixed(2),
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(AppLocalizations.of(context)!.statsMembers,
                                style: Theme.of(context).textTheme.bodyMedium),
                            Row(
                              children: [
                                CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                                    imageUrl:
                                        "https://assets.clashk.ing/icons/Icon_HV_Attack_Star.png",
                                    height: 16),
                                SizedBox(width: 8),
                                Text(
                                    warLogStats.averageClanStarsPerMember
                                        .toStringAsFixed(2),
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                            Row(
                              children: [
                                CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                                    imageUrl:
                                        "https://assets.clashk.ing/icons/Icon_HV_Sword.png",
                                    height: 16),
                                SizedBox(width: 8),
                                Text(
                                    warLogStats.averageAttacksPerMember
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
                        Text(AppLocalizations.of(context)!.warDefensesTitle,
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
                                    warLogStats
                                        .averageOpponentStarsPercentage
                                        .toStringAsFixed(2),
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(AppLocalizations.of(context)!.statsMembers,
                                style: Theme.of(context).textTheme.bodyMedium),
                            Row(
                              children: [
                                CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                                    imageUrl:
                                        "https://assets.clashk.ing/icons/Icon_HV_Attack_Star.png",
                                    height: 16),
                                SizedBox(width: 8),
                                Text(
                                    warLogStats
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
                  /*widget.clan.membersWarStats ??= await MembersWarStatsService()
                      .fetchWarLogsAndAnalyzeStats(widget.clan.tag);
                  navigator.pop();
                  navigator.push(
                    MaterialPageRoute(
                      builder: (context) => PlayersWarHistoryScreen(
                          clan: widget.clan, discordUser: widget.discordUser),
                    ),
                  );*/
                } catch (error) {
                  navigator.pop();
                  DebugUtils.debugError(" An error occurred: $error");
                }
              },
              child: Stack(
                children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            flex: 2,
                            child: CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                              imageUrl:
                                  'https://assets.clashk.ing/stickers/Villager_HV_Villager_7.png',
                              height: 90,
                              width: 90,
                            ),
                          ),
                          Expanded(
                            flex: 6,
                            child: Text(
                                AppLocalizations.of(context)!.statsMembers,
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
                  BetaLabel(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
