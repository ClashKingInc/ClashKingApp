import 'package:flutter/material.dart';
import 'package:clashkingapp/classes/clan/clan_info.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ClanInfoCard extends StatelessWidget {
  const ClanInfoCard({
    super.key,
    required this.clanInfo,
  });

  final Clan? clanInfo;

  @override
  Widget build(
    BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 70,
                        width: 70,
                        child: CachedNetworkImage(imageUrl: clanInfo!.badgeUrls.large),
                      ),
                      Text(
                        clanInfo!.tag,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ]
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: [
                        if(clanInfo!.location!.countryCode != "No countryCode")
                        CachedNetworkImage(
                          imageUrl: "https://clashkingfiles.b-cdn.net/country-flags/${clanInfo!.location!.countryCode}.png",
                          width: 16,
                          height: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          clanInfo!.name,
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
                          '${clanInfo!.members.toString()}/50   |   ',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        SizedBox(
                          height: 16,
                          width: 16,
                          child: CachedNetworkImage(imageUrl: "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Trophy.png"),
                        ),
                        SizedBox(width: 4),
                        Text(
                          clanInfo!.clanPoints.toString(),
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
                          child: CachedNetworkImage(imageUrl: clanInfo!.warLeague!.imageUrl),
                        ),
                        SizedBox(width: 8),
                        Text(
                          clanInfo!.warLeague!.name.toString(),
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
