import 'package:flutter/material.dart';
import 'package:clashkingapp/api/clan_info.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ClanInfoCard extends StatelessWidget {
  const ClanInfoCard({
    super.key,
    required this.clanInfo,
  });

  final ClanInfo clanInfo;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Row(
              children: [
                Stack(
                  children: [
                    SizedBox(
                        height: 90,
                        width: 90,
                        child: CachedNetworkImage(
                            imageUrl: clanInfo.badgeUrls.large)),
                    Positioned(
                      top: 68,
                      left: 37,
                      child: CachedNetworkImage(
                        imageUrl:
                            "https://clashkingfiles.b-cdn.net/country-flags/${clanInfo.location.countryCode}.png",
                        width: 16,
                        height: 20,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: [
                          Text(clanInfo.name,
                              style: Theme.of(context).textTheme.titleSmall),
                          Spacer(),
                          Text('${clanInfo.members.toString()}/50',
                              style: Theme.of(context).textTheme.titleSmall),
                          SizedBox(width: 8),
                        ],
                      ),
                      Text(clanInfo.tag,
                          style: Theme.of(context).textTheme.labelLarge),
                      SizedBox(height: 8),
                      Wrap(
                          alignment: WrapAlignment.spaceAround,
                          spacing: 8.0,
                          runSpacing: 0.0,
                          children: <Widget>[
                            Chip(
                              avatar: CircleAvatar(
                                backgroundColor: Colors.transparent,
                                child: CachedNetworkImage(
                                    imageUrl: clanInfo.badgeUrls.small),
                              ),
                              labelPadding:
                                  EdgeInsets.only(left: 2.0, right: 2.0),
                              label: Text(
                                clanInfo.warLeague.name
                                    .toString()
                                    .replaceFirst('League', ''),
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ),
                            Chip(
                              avatar: CircleAvatar(
                                backgroundColor: Colors.transparent,
                                child: CachedNetworkImage(
                                    imageUrl: clanInfo.badgeUrls.small),
                              ),
                              labelPadding:
                                  EdgeInsets.only(left: 2.0, right: 2.0),
                              label: Text(
                                clanInfo.type.toString(),
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ),
                          ]),
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
