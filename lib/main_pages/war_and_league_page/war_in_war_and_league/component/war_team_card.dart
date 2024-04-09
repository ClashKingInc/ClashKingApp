import 'package:flutter/material.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_in_war_and_league/war_functions.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_in_war_and_league/current_war_info_page.dart';
import 'package:clashkingapp/api/current_war_info.dart';

class WarTeamCard extends StatelessWidget {
  const WarTeamCard({
    super.key,
    required this.playerTab,
    required this.details,
    required this.widget,
    required this.member,
  });

  final List<PlayerTab> playerTab;
  final List<Widget> details;
  final CurrentWarInfoScreen widget;
  final WarMember member;

  @override
  Widget build(BuildContext context) {
    return Card(
        child: Padding(
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          ListTile(
            title: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${member.mapPosition}. ${member.name} ',
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 26,
                  height: 26,
                  child: Image.network(
                      'https://clashkingfiles.b-cdn.net/home-base/town-hall-pics/town-hall-${getPlayerTownhallByTag(member.tag, playerTab)}.png'),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...details,
              ],
            ),
            trailing: Padding(
              padding: EdgeInsets.only(left: 0),
              child: Icon(
                (member.attacks?.length ?? 0) ==
                        widget.currentWarInfo.attacksPerMember
                    ? Icons.check
                    : Icons.close,
                color: (member.attacks?.length ?? 0) ==
                        widget.currentWarInfo.attacksPerMember
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ),
        ],
      ),
    ));
  }
}



