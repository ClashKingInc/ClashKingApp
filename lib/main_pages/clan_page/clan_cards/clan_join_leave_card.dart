import 'package:flutter/material.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_join_leave/clan_join_leave.dart';
import 'package:clashkingapp/classes/clan/clan_info.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ClanJoinLeaveCard extends StatelessWidget {
  const ClanJoinLeaveCard(
      {super.key, required this.discordUser, required this.clanInfo});

  final List<String> discordUser;
  final Clan? clanInfo;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final navigator = Navigator.of(context);

        navigator.push(
          MaterialPageRoute(
            builder: (context) =>
                ClanJoinLeaveScreen(user: discordUser, clanInfo: clanInfo),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          CachedNetworkImage(
                              height: 70,
                              width: 70,
                              imageUrl:
                                  "https://clashkingfiles.b-cdn.net/stickers/Troop_HV_Goblin.png"),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: Column(
                        children: <Widget>[
                          Text(
                            AppLocalizations.of(context)!.joinLeaveLogs,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                            softWrap: true, // Explicitly allowing text to wrap
                          ),
                          Wrap(
                            alignment: WrapAlignment.start,
                            spacing: 7.0,
                            runSpacing: -7.0,
                            children: <Widget>[
                              Chip(
                                avatar: CircleAvatar(
                                    backgroundColor: Colors.transparent,
                                    child: Icon(LucideIcons.logOut,
                                        size: 16, color: Colors.red)),
                                labelPadding: EdgeInsets.symmetric(horizontal: 2),
                                label: Text(
                                  clanInfo!.joinLeaveClan.leaveNumber
                                      .toString(),
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                              Chip(
                                avatar: CircleAvatar(
                                    backgroundColor: Colors.transparent,
                                    child: Icon(LucideIcons.logIn,
                                        size: 16, color: Colors.green)),
                                labelPadding: EdgeInsets.symmetric(horizontal: 2),
                                label: Text(
                                  clanInfo!.joinLeaveClan.joinNumber.toString(),
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                              Chip(
                                avatar: CircleAvatar(
                                    backgroundColor: Colors.transparent,
                                    child: Icon(LucideIcons.arrowUpDown,
                                        size: 16, color: Colors.blue)),
                                labelPadding: EdgeInsets.symmetric(horizontal: 2),
                                label: Text(
                                  (clanInfo!.joinLeaveClan.joinNumber -
                                          clanInfo!.joinLeaveClan.leaveNumber)
                                      .toString(),
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
