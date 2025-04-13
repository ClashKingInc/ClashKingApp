import 'package:clashkingapp/common/widgets/buttons/chip.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class ClanCapitaleCard extends StatelessWidget {
  const ClanCapitaleCard({super.key});

  @override
  Widget build(BuildContext context) {
    final playerService = context.watch<PlayerService>();
    final cocService = context.watch<CocAccountService>();
    final player = playerService.getSelectedProfile(cocService);
    final clanInfo = player?.clan;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  children: <Widget>[
                    SizedBox(
                      height: 100,
                      width: 100,
                      child: MobileWebImage(
                          imageUrl:
                              'https://assets.clashk.ing/capital-base/capital-hall-pics/Building_CC_Capital_Hall_level_${clanInfo?.clanCapital?.capitalHallLevel}.png'),
                    ),
                    SizedBox(
                      width: 100,
                    ),
                  ],
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 7,
                  child: Column(
                    children: <Widget>[
                      Text(
                        AppLocalizations.of(context)!.clanCapital,
                        style: Theme.of(context).textTheme.labelLarge,
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
                      SizedBox(height: 2.0),
                      Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 7.0,
                        runSpacing: -7.0,
                        children: <Widget>[
                          ImageChip(
                            imageUrl:
                                'https://assets.clashk.ing/capital-base/capital-hall-pics/Building_CC_Capital_Hall_level_${clanInfo?.clanCapital?.capitalHallLevel}.png',
                            labelPadding: 2,
                            label: clanInfo!.clanCapital?.capitalHallLevel
                                    .toString() ??
                                '0',
                            //description: AppLocalizations.of(context)!.comingSoon,
                          ),
                          ImageChip(
                            imageUrl:
                                'https://assets.clashk.ing/bot/icons/capital_trophy.png',
                            labelPadding: 2,
                            label: clanInfo.clanCapitalPoints.toString(),
                            //description: AppLocalizations.of(context)!.comingSoon,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
