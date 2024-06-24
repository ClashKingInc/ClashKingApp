import 'package:clashkingapp/classes/account/accounts.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/classes/profile/profile_info.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/classes/profile/to_do.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/main_pages/dashboard_page/to_do_dashboard/to_do_page.dart';

class ToDoCard extends StatefulWidget {
  const ToDoCard({
    super.key,
    required this.playerStats,
    required this.tags,
    required this.accounts,
  });

  final ProfileInfo playerStats;
  final List<String> tags;
  final Accounts accounts;

  @override
  ToDoCardState createState() => ToDoCardState();
}

class ToDoCardState extends State<ToDoCard> {
  late Future<PlayerToDoData> futurePlayerToDoData;

  @override
  void initState() {
    super.initState();
    futurePlayerToDoData = PlayerDataService.fetchPlayerToDoData(widget.tags);
  }

  @override
  Widget build(BuildContext context) {
    DateTime nowUtc = DateTime.now().toUtc();
    bool isInTimeFrame = false;

    print('iuazehrfiuzhr${widget.playerStats.tag}');

    if (nowUtc.weekday == DateTime.friday && nowUtc.hour >= 6) {
      isInTimeFrame = true;
    } else if (nowUtc.weekday == DateTime.saturday ||
        nowUtc.weekday == DateTime.sunday) {
      isInTimeFrame = true;
    } else if (nowUtc.weekday == DateTime.monday && nowUtc.hour < 6) {
      isInTimeFrame = true;
    }

    return FutureBuilder<PlayerToDoData>(
      future: futurePlayerToDoData,
      builder: (BuildContext context, AsyncSnapshot<PlayerToDoData> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox.shrink(); // Show a loading spinner while waiting
        } else if (snapshot.hasError) {
          return Text(
              'Error: ${snapshot.error}'); // Show error if something went wrong
        } else {
          PlayerToDoData? data = snapshot.data;
          if (data != null) {
            for (var item in data.items) {
              print(item.clanGames?.points);
              print(item.cwl.attacksDone);
            }
          }

          return GestureDetector(
            onTap: () {
              if (data != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ToDoScreen(
                      playerStats: widget.playerStats,
                      tags: widget.tags,
                      isInTimeFrame: isInTimeFrame,
                      data: data,
                      accounts: widget.accounts),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('No data available'),
                  ),
                );
              }
            },
            child: DefaultTextStyle(
              style: Theme.of(context).textTheme.labelLarge ?? TextStyle(),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, top: 16, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Column(
                            children: <Widget>[
                              Text(
                                AppLocalizations.of(context)?.toDoList ?? 'To Do List',
                                style: (Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.bold)) ??
                                  TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 12),
                              SizedBox(
                                height: 100,
                                width: 100,
                                child: CachedNetworkImage(imageUrl: 'https://clashkingfiles.b-cdn.net/icons/Magic_Item_Builder_Potion.png'),
                              ),
                            ],
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  AppLocalizations.of(context)?.comingSoon ?? 'Coming soon!',
                                  style: Theme.of(context).textTheme.labelLarge ?? TextStyle(),
                                ),
                                if (data != null) ...{
                                  for (var playerData in data.items.where(
                                      (item) =>item.playerTag ==widget.playerStats.tag)) ...[
                                    Text('Last Active: ${DateFormat('dd/MM/yy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(playerData.lastActive * 1000))}'),
                                    if (isInTimeFrame)
                                      if (playerData.raids.attackLimit == 0)
                                        Text('Raids: 0/5')
                                      else
                                        Text('Raids: ${playerData.raids.attacksDone}/${playerData.raids.attackLimit}'),
                                    if (playerData.cwl.attackLimit != 0)
                                      Text('CWL: ${playerData.cwl.attacksDone}/${playerData.cwl.attackLimit}'),
                                  ],
                                }
                                //Text(
                                //  'Legends hits 8/8 - Total 8/16',
                                //  style: Theme.of(context).textTheme.labelLarge ?? TextStyle(),
                                //),
                                //Text(
                                //  'Clan Games',
                                //  style: Theme.of(context).textTheme.labelLarge ?? TextStyle(),
                                //),
                                //Text(
                                //  'War attacks',
                                //  style: Theme.of(context).textTheme.labelLarge ?? TextStyle(),
                                //),
                                //Text(
                                //  'Season pass',
                                //  style: Theme.of(context).textTheme.labelLarge ?? TextStyle(),
                                //),
                                //Text(
                                //  'War Castle',
                                //  style: Theme.of(context).textTheme.labelLarge ?? TextStyle(),
                                //),
                                //Text(
                                //  'Season pass',
                                //  style: Theme.of(context).textTheme.labelLarge ?? TextStyle(),
                                //),
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
      },
    );
  }
}
