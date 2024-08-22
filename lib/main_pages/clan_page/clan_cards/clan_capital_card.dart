import 'package:clashkingapp/classes/clan/clan_info.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_capital/clan_capital_page.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ClanCapitaleCard extends StatelessWidget {
  const ClanCapitaleCard({
    super.key, required this.user, required this.clanInfo
  });

  final List<String> user;
  final Clan? clanInfo;

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CapitalScreen(
              user: user,
              clanInfo: clanInfo,
            ),
          ),
        );
      },
      child : Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        ClipRect(
                          child: Transform.scale(
                            scale: (clanInfo?.clanCapital?.capitalHallLevel == 8) ? 0.98 : 1.4,
                            child: CachedNetworkImage(
                              height: 70,
                              width: 70,
                              fit: BoxFit.cover,
                              imageUrl: 'https://assets.clashk.ing/capital-base/capital-hall-pics/Building_CC_Capital_Hall_level_${clanInfo?.clanCapital?.capitalHallLevel}.png',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    flex : 7,
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)?.clanCapital ?? 'Clan Capital',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}