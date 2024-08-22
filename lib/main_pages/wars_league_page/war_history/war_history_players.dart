import 'package:clashkingapp/classes/clan/clan_info.dart';
import 'package:flutter/material.dart';


class PlayersWarHistoryScreen extends StatefulWidget {
  final Clan clan;
  final List<String> discordUser;

  PlayersWarHistoryScreen(
      {super.key,
      required this.clan,
      required this.discordUser});

  @override
  PlayersWarHistoryScreenState createState() => PlayersWarHistoryScreenState();
}

class PlayersWarHistoryScreenState extends State<PlayersWarHistoryScreen>
    with TickerProviderStateMixin {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
           Text("Players War History"),
          ],
        ),
      ),
    );
  }
}
