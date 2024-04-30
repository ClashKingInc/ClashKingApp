import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/api/clan_info.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ClanWarsStatsCard extends StatefulWidget {
  final ClanInfo clanInfo;

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
    return AlertDialog(
        surfaceTintColor: Colors.transparent,
        title: Row(children: [
          CachedNetworkImage(
              imageUrl: widget.clanInfo.badgeUrls.medium,
              width: 64,
              height: 64),
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
        ]),
        content: SingleChildScrollView(
          // Ensures content fits and is scrollable if too long
          child: Column(
            children: [
              Text("War stats", style: Theme.of(context).textTheme.titleMedium),
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
                          color: Theme.of(context).colorScheme.onBackground,
                          size: 16,
                        ),
                      ),
                      label: Text(
                          widget.clanInfo.isWarLogPublic ? "Public" : "Private",
                          style: Theme.of(context).textTheme.labelLarge),
                    ),
                    Chip(
                      avatar: Icon(
                        LucideIcons.flame,
                        color: Theme.of(context).colorScheme.onBackground,
                        size: 16,
                      ),
                      label: Text(widget.clanInfo.warWinStreak.toString(),
                          style: Theme.of(context).textTheme.labelLarge),
                    ),
                    Chip(
                      avatar: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        child: CachedNetworkImage(
                            imageUrl:
                                "https://clashkingfiles.b-cdn.net/icons/Icon_DC_War.png"),
                      ),
                      label: Text(widget.clanInfo.warFrequency.toString(),
                          style: Theme.of(context).textTheme.labelLarge),
                    ),
                  ]),
              Text(
                  "WinRate : ${(((widget.clanInfo.warWins + widget.clanInfo.warTies) == 0 ? 1 : widget.clanInfo.warWins + widget.clanInfo.warTies) / (widget.clanInfo.warLosses + widget.clanInfo.warTies + widget.clanInfo.warWins) * 100).toStringAsFixed(2)}%",
                  style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ));
  }
}
