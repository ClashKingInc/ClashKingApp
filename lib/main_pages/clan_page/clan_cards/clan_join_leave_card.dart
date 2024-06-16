import 'package:flutter/material.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_join_leave/clan_join_leave.dart';
import 'package:clashkingapp/api/join_leave.dart';
import 'package:clashkingapp/api/clan_info.dart';

class ClanJoinLeaveCard extends StatelessWidget {
  const ClanJoinLeaveCard({
    super.key,
    required this.discordUser,
    required this.clanInfo
  });

  final List<String> discordUser;
  final ClanInfo clanInfo;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
        JoinLeaveClan joinLeaveClan =
            await JoinLeaveClanService().fetchJoinLeaveData(clanInfo.tag);
        navigator.pop(); 
        navigator.push(
          MaterialPageRoute(
            builder: (context) => ClanJoinLeaveScreen(
                user: discordUser,
                joinLeaveClan: joinLeaveClan,
                clanInfo: clanInfo),
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
                    Text(
                      "Join/Leave",
                      style: (Theme.of(context).textTheme.labelLarge),
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
