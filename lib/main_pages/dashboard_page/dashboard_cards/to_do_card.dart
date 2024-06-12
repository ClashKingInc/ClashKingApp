import 'package:flutter/material.dart';
import 'package:clashkingapp/api/player_account_info.dart';
import 'package:clashkingapp/main_pages/dashboard_page/to_do_dashboard/to_do_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/api/to_do.dart';

class ToDoCard extends StatelessWidget {
  const ToDoCard({
    super.key,
    required this.playerStats,
    required this.tags,
  });

  final PlayerAccountInfo playerStats;
  final List<String> tags;

  Widget build(BuildContext context) {
    return FutureBuilder<PlayerToDoData>(
      future: PlayerDataService.fetchPlayerToDoData(tags),
      builder: (BuildContext context, AsyncSnapshot<PlayerToDoData> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox.shrink(); // Show a loading spinner while waiting
        } else if (snapshot.hasError) {
          return Text(
              'Error: ${snapshot.error}'); // Show error if something went wrong
        } else {
          PlayerToDoData? data = snapshot.data;
          /*if (data != null) {
            for (var item in data.items) {
              print(item.playerTag);
              print(item.currentClan);
              print(item.legends!.attacks);
              print(item.legends!.defenses);
              print(item.seasonPass);
              print(item.lastActive);
              print(item.raids.attacksDone);
              print(item.raids.attackLimit);
              print(item.cwl.attacksDone);
              print(item.cwl.attackLimit);

            }
          }*/

          // Your existing widget code goes here
          return GestureDetector(
            onTap: () {
              //Navigator.push(
              //  context,
              //  MaterialPageRoute(
              //    builder: (context) => ToDoScreen(playerStats: playerStats, discordUser: discordUser),
              //  ),
              //);
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
                                AppLocalizations.of(context)?.toDoList ??
                                    'To Do List',
                                style: (Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold)) ??
                                    TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 12),
                              SizedBox(
                                height: 100,
                                width: 100,
                                child: CachedNetworkImage(
                                    imageUrl:
                                        'https://clashkingfiles.b-cdn.net/icons/Magic_Item_Builder_Potion.png'),
                              ),
                            ],
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  AppLocalizations.of(context)?.comingSoon ??
                                      'Coming soon!',
                                  style:
                                      Theme.of(context).textTheme.labelLarge ??
                                          TextStyle(),
                                ),

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
