import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/presentation/clan_info/clan_header.dart';
import 'package:clashkingapp/features/clan/presentation/clan_info/clan_members.dart';
import 'package:flutter/material.dart';

class ClanInfoScreen extends StatelessWidget {
  final Clan clanInfo;

  const ClanInfoScreen(
      {super.key, required this.clanInfo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Theme.of(context).colorScheme.surface,
              child: ClanInfoHeaderCard(clanInfo: clanInfo),
            ),
            const SizedBox(height: 8),
            ClanMembers(clanInfo: clanInfo),
          ],
        ),
      ),
    );
  }
}
