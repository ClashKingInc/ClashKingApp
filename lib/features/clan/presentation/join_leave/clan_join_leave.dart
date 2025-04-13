import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/presentation/join_leave/clan_join_leave_body.dart';
import 'package:clashkingapp/features/clan/presentation/join_leave/clan_join_leave_header.dart';
import 'package:flutter/material.dart';

class ClanJoinLeaveScreen extends StatefulWidget {
  final Clan clanInfo;

  ClanJoinLeaveScreen(
      {super.key, required this.clanInfo});

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
              child: ClanJoinLeaveHeader(clanInfo: widget.clanInfo),
            ),
            SizedBox(height: 8),
            ClanJoinLeaveBody(
                joinLeaveClan: widget.clanInfo.joinLeave),
          ])
        ]),
      ),
    );
  }
}
