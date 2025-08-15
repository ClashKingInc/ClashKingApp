import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/classes/clan/clan_info.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

class ClanWarsStatsCard extends StatefulWidget {
  final Clan clanInfo;

  const ClanWarsStatsCard({required this.clanInfo});

  @override
  ClanWarsStatsCardState createState() => ClanWarsStatsCardState();
}

class ClanWarsStatsCardState extends State<ClanWarsStatsCard> {
  String currentFilter = 'trophies';

  void updateFilter(String newFilter) {
    setState(() {
      currentFilter = newFilter;
    });
  }

  @override
  Widget build(BuildContext context) {
    double winRate = ((widget.clanInfo.warWins + widget.clanInfo.warTies) == 0
            ? 1
            : widget.clanInfo.warWins + widget.clanInfo.warTies) /
        (widget.clanInfo.warLosses +
            widget.clanInfo.warTies +
            widget.clanInfo.warWins) *
        100;

    return AlertDialog(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Row(
          children: [
            CachedNetworkImage(
              imageUrl: widget.clanInfo.badgeUrls.medium,
              width: 64,
              height: 64,
            ),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.clanInfo.name,
                    style: Theme.of(context).textTheme.titleMedium),
                Text(widget.clanInfo.tag,
                    style: Theme.of(context).textTheme.labelLarge),
              ],
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              Text(AppLocalizations.of(context)!.warStats, style: Theme.of(context).textTheme.titleMedium),
              Wrap(
                  spacing: 8,
                  runSpacing: 0,
                  alignment: WrapAlignment.center,
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
                      label: Text(widget.clanInfo.warWins.toString(),
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
                      label: Text(widget.clanInfo.warTies.toString(),
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
                      label: Text(widget.clanInfo.warLosses.toString(),
                          style: Theme.of(context).textTheme.labelLarge),
                    ),
                    Chip(
                      avatar: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        child: Icon(
                          LucideIcons.lock,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 16,
                        ),
                      ),
                      label: Text(
                        widget.clanInfo.isWarLogPublic ? "Public" : "Private",
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    Chip(
                      avatar: Icon(
                        LucideIcons.flame,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 16,
                      ),
                      label: Text(
                        widget.clanInfo.warWinStreak.toString(),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    Chip(
                      avatar: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        child: CachedNetworkImage(
                          imageUrl:
                              "https://assets.clashk.ing/icons/Icon_DC_War.png",
                        ),
                      ),
                      label: Text(
                        () {
                          switch (widget.clanInfo.warFrequency.toString()) {
                            case 'unknown':
                              return AppLocalizations.of(context)!.unknown;
                            case 'always':
                              return AppLocalizations.of(context)!.always;
                            case 'never':
                              return AppLocalizations.of(context)!.never;
                            case 'oncePerWeek':
                              return AppLocalizations.of(context)!.oncePerWeek;
                            case 'moreThanOncePerWeek':
                              return AppLocalizations.of(context)!.twicePerWeek;
                            case 'lessThanOncePerWeek':
                              return AppLocalizations.of(context)!.rarely;
                            default:
                              return widget.clanInfo.warFrequency.toString();
                          }
                        }(),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ]),
              widget.clanInfo.isWarLogPublic && winRate.isFinite
                  ? Text(
                      "WinRate : ${winRate.toStringAsFixed(2)}%",
                      style: Theme.of(context).textTheme.labelLarge,
                    )
                  : Container(),
            ],
          ),
        ));
  }
}
