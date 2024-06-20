import 'package:flutter/material.dart';
import 'package:clashkingapp/classes/profile/profile_info.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ToDoCard extends StatelessWidget {
  
  const ToDoCard({
    super.key,
    required this.playerStats,
    required this.discordUser,
  });

  final ProfileInfo playerStats;
  final List<String> discordUser;

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Text(
                          AppLocalizations.of(context)?.toDoList ?? 'To Do List',
                          style: (
                            Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)) 
                            ?? TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 12),
                        SizedBox(
                          height: 100,
                          width: 100,
                          child: CachedNetworkImage(
                              imageUrl: 'https://clashkingfiles.b-cdn.net/icons/Magic_Item_Builder_Potion.png'),
                        ),
                      ],
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Text(AppLocalizations.of(context)?.comingSoon ?? 'Coming soon!',
                            style: Theme.of(context).textTheme.labelLarge ?? TextStyle(),
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
}
