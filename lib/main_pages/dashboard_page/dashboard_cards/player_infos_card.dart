import 'package:flutter/material.dart';
import 'package:clashkingapp/api/player_account_info.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:clashkingapp/main_pages/dashboard_page/player_dashboard/player_info_page.dart';

class PlayerInfosCard extends StatelessWidget {
  const PlayerInfosCard({
    super.key,
    required this.playerStats,
  });

  final PlayerAccountInfo playerStats;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StatsScreen(playerStats: playerStats),
          ),
        );
      },
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.labelLarge ?? TextStyle(),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        SizedBox(
                          height: 100,
                          width: 100,
                          child: Image.network(playerStats.townHallPic),
                        ),
                        Text(
                          playerStats.name,
                          style: (Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)) ??
                              TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          playerStats.tag,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 4.0, // gap between adjacent chips
                            runSpacing: 0.0, // gap between lines
                            children: <Widget>[
                              Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: Colors
                                      .transparent, // Set to a suitable color for your design.
                                  child: Image.network(
                                      playerStats.clan.badgeUrls.small),
                                ),
                                labelPadding:
                                    EdgeInsets.only(left: 2.0, right: 2.0),
                                label: Text(
                                  playerStats.clan.name,
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                              Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: Colors
                                      .transparent, // Set to a suitable color for your design.
                                  child: playerStats.warPreference == 'in'
                                      ? Image.network(
                                          "https://clashkingfiles.b-cdn.net/icons/Icon_HV_In.png")
                                      : Image.network(
                                          'https://clashkingfiles.b-cdn.net/icons/Icon_HV_Out.png'),
                                ),
                                labelPadding:
                                    EdgeInsets.only(left: 2.0, right: 2.0),
                                label: Text(
                                  playerStats.warPreference.toString(),
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                              Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: Colors
                                      .transparent, // Set to a suitable color for your design.
                                  child: Image.network(playerStats.townHallPic),
                                ),
                                label: Text('${playerStats.townHallLevel}',
                                    style:
                                        Theme.of(context).textTheme.labelLarge),
                                labelPadding: EdgeInsets.zero,
                              ),
                              Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: Colors
                                      .transparent, // Set to a suitable color for your design.
                                  child: Image.network(
                                      "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Trophy.png"),
                                ),
                                label: Text('${playerStats.trophies}',
                                    style:
                                        Theme.of(context).textTheme.labelLarge),
                                labelPadding: EdgeInsets.zero,
                              ),
                              Chip(
                                avatar: Icon(LucideIcons.chevronsUpDown,
                                    color: Color.fromARGB(255, 0, 136, 255)),
                                labelPadding: EdgeInsets.zero,
                                label: Text(
                                  (playerStats.donations /
                                          (playerStats.donationsReceived == 0
                                              ? 1
                                              : playerStats.donationsReceived))
                                      .toStringAsFixed(2),
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                              Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: Colors
                                      .transparent, // Set to a suitable color for your design.
                                  child:
                                      Image.network(playerStats.builderHallPic),
                                ),
                                label: Text('${playerStats.builderHallLevel}',
                                    style:
                                        Theme.of(context).textTheme.labelLarge),
                                labelPadding: EdgeInsets.zero,
                              ),
                              Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: Colors
                                      .transparent, // Set to a suitable color for your design.
                                  child: Image.network(
                                      "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Trophy.png"),
                                ),
                                label: Text(
                                    '${playerStats.builderBaseTrophies}',
                                    style:
                                        Theme.of(context).textTheme.labelLarge),
                                labelPadding: EdgeInsets.zero,
                              ),
                              Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: Colors
                                      .transparent, // Set to a suitable color for your design.
                                  child: Image.network(
                                      "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Attack_Star.png"),
                                ),
                                labelPadding:
                                    EdgeInsets.only(left: 2.0, right: 2.0),
                                label: Text(
                                  '${playerStats.warStars}',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}