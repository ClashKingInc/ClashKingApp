import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

class ClanInfoCard extends StatelessWidget {
  const ClanInfoCard({
    super.key,
  });

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
          children: <Widget>[
            Row(
              children: [
                Column(
                  children: <Widget>[
                    SizedBox(
                      height: 70,
                      width: 70,
                      child:
                          MobileWebImage(imageUrl: clanInfo!.badgeUrls.large),
                    ),
                    SizedBox(
                      width: 100,
                      child: Text(
                        clanInfo.tag,
                        style: Theme.of(context).textTheme.labelLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: [
                        if (clanInfo.location != null &&
                            clanInfo.location!.countryCode != "No countryCode")
                          MobileWebImage(
                            imageUrl: ImageAssets.flag(
                                clanInfo.location!.countryCode!.toLowerCase()),
                            height: 10,
                          ),
                        SizedBox(width: 8),
                        Text(
                          clanInfo.name,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.users,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${clanInfo.members.toString()}/50   |   ',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        SizedBox(
                            height: 16,
                            width: 16,
                            child:
                                MobileWebImage(imageUrl: ImageAssets.trophies)),
                        SizedBox(width: 4),
                        Text(
                          clanInfo.clanPoints.toString(),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: MobileWebImage(
                              imageUrl: ImageAssets
                                      .leagues[clanInfo.warLeague!.name] ??
                                  ImageAssets.leagues["Unranked"]!),
                        ),
                        SizedBox(width: 8),
                        Text(
                          clanInfo.warLeague!.name.toString(),
                          style: Theme.of(context).textTheme.labelLarge,
                        )
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
