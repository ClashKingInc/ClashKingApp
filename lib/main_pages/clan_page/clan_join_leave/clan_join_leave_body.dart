import 'package:flutter/material.dart';
import 'package:clashkingapp/api/join_leave.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/main_pages/dashboard_page/player_dashboard/player_info_page.dart';
import 'package:clashkingapp/api/player_account_info.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ClanJoinLeaveBody extends StatefulWidget {
  final List<String> user;
  final JoinLeaveClan joinLeaveClan;

  ClanJoinLeaveBody(
      {super.key, required this.user, required this.joinLeaveClan});

  @override
  ClanJoinLeaveBodyState createState() => ClanJoinLeaveBodyState();
}

class ClanJoinLeaveBodyState extends State<ClanJoinLeaveBody>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Column(children: [
        for (var item in widget.joinLeaveClan.items)
          GestureDetector(
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
              PlayerAccountInfo playerStats =
                  await PlayerService().fetchPlayerStats(item.tag);
              navigator.pop();
              navigator.push(
                MaterialPageRoute(
                  builder: (context) => StatsScreen(
                      playerStats: playerStats, discordUser: widget.user),
                ),
              );
            },
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                        flex: 3,
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.network(item.townHallPic,
                                  width: 60, height: 60)
                            ])),
                    Expanded(
                      flex: 6,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name,
                              style: Theme.of(context).textTheme.bodyLarge,
                              overflow: TextOverflow.ellipsis),
                          Text(item.tag,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .tertiary)),
                          Text(
                            item.type == "join"
                                ? AppLocalizations.of(context)?.joinedOnAt(
                                        DateFormat('dd/MM/yyyy')
                                            .format(item.time.toLocal()),
                                        DateFormat('HH:mm')
                                            .format(item.time.toLocal())) ??
                                    "Joined on ${DateFormat('dd/MM/yyyy').format(item.time.toLocal())} at ${DateFormat('HH:mm').format(item.time.toLocal())}."
                                : AppLocalizations.of(context)?.leftOnAt(
                                        DateFormat('dd/MM/yyyy')
                                            .format(item.time.toLocal()),
                                        DateFormat('HH:mm')
                                            .format(item.time.toLocal())) ??
                                    "Left on ${DateFormat('dd/MM/yyyy').format(item.time.toLocal())} at ${DateFormat('HH:mm').format(item.time.toLocal())}.",
                            style: Theme.of(context).textTheme.bodySmall,
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: item.type == "join"
                                ? Icon(LucideIcons.logIn,
                                    size: 24, color: Colors.green)
                                : Icon(LucideIcons.logOut,
                                    size: 24, color: Colors.red),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
      ]),
    ]);
  }
}
