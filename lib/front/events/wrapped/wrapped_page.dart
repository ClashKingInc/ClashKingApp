import 'package:clashkingapp/classes/events/wrapped/clash_wrapped.dart';
import 'package:clashkingapp/front/events/wrapped/legends_page.dart';
import 'package:clashkingapp/front/events/wrapped/intro_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class WrappedScreen extends StatelessWidget {
  final ClashWrappedData wrappedData;

  WrappedScreen({required this.wrappedData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        foregroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: PageView(
        scrollDirection: Axis.vertical,
        children: [
          IntroPage(),
          // LegendsPage(data: wrappedData.playerInfo),
          // WarsPage(data: wrappedData.wars),
          /*CWLPage(data: wrappedData.cwl),
          CapitalPage(data: wrappedData.capital),
          ClanActivityPage(data: wrappedData.clanActivity),
          DiscordPage(data: wrappedData.discord),
          SharePage(data: wrappedData),*/
        ],
      ),
    );
  }
}
