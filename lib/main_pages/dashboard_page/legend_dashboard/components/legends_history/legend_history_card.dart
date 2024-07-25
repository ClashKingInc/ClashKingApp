import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LegendHistoryCard extends StatelessWidget {
  const LegendHistoryCard({
    super.key,
    required this.legendSeasons,
  });

  final List legendSeasons;

  @override
  Widget build(BuildContext context) {
    String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

    return Column(
      children: [
        ...legendSeasons.map((legendsSeason) {
          return Card(
            margin: EdgeInsets.only(top: 4, bottom: 4, left: 16, right: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Column(
                        children: <Widget>[
                          SizedBox(
                            height: 90,
                            width: 100,
                            child: Stack(
                              children: <Widget>[
                                Center(
                                  child: CachedNetworkImage(
                                    imageUrl:
                                        "https://clashkingfiles.b-cdn.net/icons/Icon_HV_League_Legend_3_No_Padding.png",
                                    height: 80,
                                  ),
                                ),
                                Align(
                                  alignment: Alignment(0, -0.1),
                                  child: Text(
                                    capitalize(
                                      DateFormat('MMMM\nyyyy', Localizations.localeOf(context).languageCode).format(
                                        DateTime(
                                          int.parse( legendsSeason.season.split('-')[0]),
                                          int.parse( legendsSeason.season.split('-')[1]),
                                        ),
                                      ),
                                    ),
                                    style: Theme.of(context).textTheme.labelMedium!.copyWith(color: Colors.white),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "${legendsSeason.clan != null ? legendsSeason.clan.name : AppLocalizations.of(context)!.noClan}",
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 4.0,
                              runSpacing: 0.0,
                              children: <Widget>[
                                Chip(
                                  avatar: CircleAvatar(
                                    backgroundColor: Colors.transparent,
                                    child: CachedNetworkImage(imageUrl: "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Trophy_Best.png",),
                                  ),
                                  label: Text('${legendsSeason.trophies}', style: Theme.of(context).textTheme.labelLarge,),
                                ),
                                Chip(
                                  avatar: CircleAvatar(
                                    backgroundColor: Colors.transparent,
                                    child: CachedNetworkImage(imageUrl: "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Planet.png"),
                                  ),
                                  label: Text(
                                    NumberFormat('#,###', 'fr_FR').format(legendsSeason.rank),
                                    style: Theme.of(context).textTheme.labelLarge,
                                  ),
                                ),
                                Chip(
                                  avatar: CircleAvatar(
                                    backgroundColor: Colors.transparent,
                                    child: CachedNetworkImage(imageUrl: "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Sword.png",),
                                  ),
                                  label: Text('${legendsSeason.attackWins}', style: Theme.of(context).textTheme.labelLarge,),
                                ),
                                Chip(
                                  avatar: CircleAvatar(
                                    backgroundColor: Colors.transparent,
                                    child: CachedNetworkImage(imageUrl: "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Shield.png",),
                                  ),
                                  label: Text('${legendsSeason.defenseWins}', style: Theme.of(context).textTheme.labelLarge,),
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
        }),
      ],
    );
  }
}
