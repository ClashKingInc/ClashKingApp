import 'package:clashkingapp/main_pages/clan_page/clan_join_leave/clan_join_leave_body.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_join_leave/clan_join_leave_header.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/classes/clan/clan_info.dart';

class ClanJoinLeaveScreen extends StatefulWidget {
  final List<String> user;
  final Clan? clanInfo;

  ClanJoinLeaveScreen(
      {super.key,
      required this.user,
      required this.clanInfo});

  @override
  ClanJoinLeaveScreenState createState() => ClanJoinLeaveScreenState();
}

class ClanJoinLeaveScreenState extends State<ClanJoinLeaveScreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(children: [
          Column(children: [
            Container(
              color: Theme.of(context).colorScheme.surface,
              child : ClanJoinLeaveHeader(
                  user: widget.user,
                  joinLeaveClan: widget.clanInfo!.joinLeaveClan,
                  clanInfo: widget.clanInfo),
            ),
            SizedBox(height: 8),
            ClanJoinLeaveBody(
                user: widget.user, joinLeaveClan: widget.clanInfo!.joinLeaveClan)
          ])
        ]),
      ),
    );
  }
}
