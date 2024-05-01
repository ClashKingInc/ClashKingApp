import 'package:flutter/material.dart';
import 'package:clashkingapp/api/player_account_info.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_history/war_history_page.dart';

class WarHistoryCard extends StatelessWidget {
  final List<dynamic> warHistoryData;
  final PlayerAccountInfo playerStats;
  final List<String> discordUser;

  const WarHistoryCard({super.key, required this.warHistoryData, required this.playerStats, required this.discordUser});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WarHistoryScreen(
              clanTag: playerStats.clan.tag,
              discordUser: discordUser,
              warHistoryData: warHistoryData,
            ),
          ),
        );
      },
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.labelLarge ?? TextStyle(),
        child: Card(
          margin: EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Center(
                      child: Text(
                        'War History'
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