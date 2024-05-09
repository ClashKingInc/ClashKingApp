import 'package:flutter/material.dart';
import 'package:clashkingapp/api/clan_info.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_info_page/components/clan_members_tab.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_info_page/components/clan_info_header_card.dart';

class ClanInfoScreen extends StatefulWidget {
  final ClanInfo clanInfo;

  ClanInfoScreen({super.key, required this.clanInfo});

  @override
  ClanInfoScreenState createState() => ClanInfoScreenState();
}

class ClanInfoScreenState extends State<ClanInfoScreen>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Theme.of(context).colorScheme.surface,
              child: ClanInfoHeaderCard(clanInfo: widget.clanInfo),
            ),
            SizedBox(height: 8),
            ClanMembers(clanInfo: widget.clanInfo),
          ],
        ),
      ),
    );
  }
}
