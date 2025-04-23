import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/shapes/stat_tile.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/functions/functions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/features/clan/models/clan_join_leave.dart';

class ClanJoinLeaveStats extends StatefulWidget {
  final ClanJoinLeave? joinLeaveClan;

  const ClanJoinLeaveStats({super.key, required this.joinLeaveClan});

  @override
  State<ClanJoinLeaveStats> createState() => _ClanJoinLeaveStatsState();
}

class _ClanJoinLeaveStatsState extends State<ClanJoinLeaveStats> {
  @override
  Widget build(BuildContext context) {
    final stats = widget.joinLeaveClan?.stats;
    if (stats == null) return const SizedBox.shrink();
    final List<String> podiumIcons = ['🥇', '🥈', '🥉'];
    final locale = Localizations.localeOf(context).toString();
    final formattedStart = DateFormat.yMMMd(locale).format(
      DateTime.fromMillisecondsSinceEpoch(
          (widget.joinLeaveClan?.timeStampStart ?? 0) * 1000),
    );
    final formattedEnd = DateFormat.yMMMd(locale).format(
      DateTime.fromMillisecondsSinceEpoch((widget.joinLeaveClan?.timeStampEnd ?? 0) * 1000),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: Column(
            children: [
              Text(AppLocalizations.of(context)!.statistics,
                  style: Theme.of(context).textTheme.titleSmall),
              Text(
                "($formattedStart - $formattedEnd)",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  StatTile(
                    label: AppLocalizations.of(context)!.events,
                    value: '${stats.totalEvents}',
                    icon: Icon(Icons.event),
                  ),
                  StatTile(
                    label: AppLocalizations.of(context)!.joins,
                    value: '${stats.totalJoins}',
                    icon:
                        Icon(LucideIcons.logIn, size: 24, color: Colors.green),
                  ),
                  StatTile(
                    label: AppLocalizations.of(context)!.leaves,
                    value: '${stats.totalLeaves}',
                    icon: Icon(LucideIcons.logOut, size: 24, color: Colors.red),
                  ),
                  StatTile(
                    label: AppLocalizations.of(context)!.uniquePlayers,
                    value: '${stats.uniquePlayers}',
                    icon: Icon(Icons.group),
                  ),
                  StatTile(
                    label: AppLocalizations.of(context)!.movingPlayers,
                    value: '${stats.movingPlayers}',
                    icon: Icon(LucideIcons.activity,
                        color: const Color.fromARGB(255, 255, 196, 0)),
                  ),
                  StatTile(
                    label: AppLocalizations.of(context)!.stillInClan,
                    value: '${stats.playerStillInClan}',
                    icon: MobileWebImage(
                      imageUrl: ImageAssets.clanCastle,
                      width: 24,
                      height: 24,
                    ),
                  ),
                  StatTile(
                    label: AppLocalizations.of(context)!.leftForever,
                    value: '${stats.playerLeftClan}',
                    icon: Icon(Icons.waving_hand),
                  ),
                  StatTile(
                    label: AppLocalizations.of(context)!.rejoinedPlayers,
                    value: '${stats.rejoinedPlayers}',
                    icon: Icon(Icons.repeat),
                  ),
                  if (stats.avgTimeBetweenJoinLeave != null)
                    StatTile(
                      label: AppLocalizations.of(context)!.avgTimeJoinLeave,
                      value: formatSecondsToHHMM(
                          stats.avgTimeBetweenJoinLeave ?? 0),
                      icon: Icon(Icons.timer),
                    ),
                  if (stats.mostMovingHour != null)
                    StatTile(
                      label: AppLocalizations.of(context)!.peakHour,
                      value: '${stats.mostMovingHour}:00',
                      icon: Icon(Icons.access_time),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(AppLocalizations.of(context)!.mostMovingPlayers,
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  ...stats.mostMovingPlayers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final player = entry.value;
                    final icon = index < podiumIcons.length
                        ? Text(podiumIcons[index],
                            style: TextStyle(fontSize: 20))
                        : Icon(LucideIcons.user);

                    return StatTile(
                      label: player.name,
                      value: '${player.count}',
                      icon: icon,
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
