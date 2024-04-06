import 'package:flutter/material.dart';
import 'package:clashkingapp/api/player_account_info.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class NotInWarCard extends StatelessWidget {
  const NotInWarCard({
    super.key,
    required this.playerStats,
  });

  final PlayerAccountInfo playerStats;

  @override
  Widget build(BuildContext context) {
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                      child:
                        Column(
                          children: <Widget>[
                            SizedBox(
                              width: 70, // Maximum width
                              height: 70, // Maximum height
                              child: Center(
                                child: Image.network(
                                    playerStats.clan.badgeUrls.large,
                                    fit: BoxFit.cover),
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${playerStats.clan.name} ${AppLocalizations.of(context)?.isNotInWar ?? "is not in war."}',
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  AppLocalizations.of(context)?.askForWar ??
                                      'Contact a leader or co-leader to start a war.',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ],
                        )
                      )]))
                );
  }
}