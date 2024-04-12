import 'package:flutter/material.dart';
import 'package:clashkingapp/api/clan_info.dart';

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
                SizedBox(
                    height: 90,
                    width: 90,
                    child: Image.network(clanInfo.badgeUrls.large)),
                SizedBox(width: 8),
                Flexible(  // Replace Expanded with Flexible
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(clanInfo.name,
                          style: Theme.of(context).textTheme.titleSmall),
                      Text(clanInfo.tag, style: Theme.of(context).textTheme.labelLarge),
                      SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.spaceAround,
                        spacing: 8.0, // gap between adjacent chips
                        runSpacing: 0.0, // gap between lines
                        children: <Widget>[
                          Chip(
                            avatar: CircleAvatar(
                              backgroundColor: Colors
                                  .transparent,
                              child: Image.network(
                                  clanInfo.badgeUrls.small),
                            ),
                            labelPadding:
                                EdgeInsets.only(left: 2.0, right: 2.0),
                            label: Text(
                              clanInfo.warLeague.name.toString().replaceFirst('League', ''),
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                          Chip(
                            avatar: CircleAvatar(
                              backgroundColor: Colors
                                  .transparent,
                              child: Image.network(
                                  clanInfo.badgeUrls.small),
                            ),
                            labelPadding:
                                EdgeInsets.only(left: 2.0, right: 2.0),
                            label: Text(
                              clanInfo.members.toString(),
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                        ]),
                    ],
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}