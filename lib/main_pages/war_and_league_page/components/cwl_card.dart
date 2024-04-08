import 'package:flutter/material.dart';
import 'package:clashkingapp/api/player_account_info.dart';

class CwlCard extends StatelessWidget {
  const CwlCard({
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
                      child: Column(
                    children: <Widget>[
                      SizedBox(
                        width: 70, // Maximum width
                        height: 70, // Maximum height
                        child: Center(
                          child: Image.network(playerStats.clan.badgeUrls.large,
                              fit: BoxFit.cover),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "We are in league !",
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ],
                  ))
                ])));
  }
}
