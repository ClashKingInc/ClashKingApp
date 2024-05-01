import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WarLogHistoryCard extends StatelessWidget {
  const WarLogHistoryCard({
    super.key,
    required this.warHistoryData,
    required this.discordUser,
    required this.clanTag,
  });

  final List<dynamic> warHistoryData;
  final List<String> discordUser;
  final String clanTag;

  @override
  Widget build(BuildContext context) {

    String determineWarResult(war, clanTag) {
      bool isClan = war['clan']['tag'] == clanTag;
      int clanStars = war['clan']['stars'];
      int opponentStars = war['opponent']['stars'];
      double clanDestruction = war['clan']['destructionPercentage'];
      double opponentDestruction = war['opponent']['destructionPercentage'];

      if (clanStars > opponentStars) {
        return isClan ? 'victory' : 'defeat';
      } else if (clanStars < opponentStars) {
        return isClan ? 'defeat' : 'victory';
      } else {
        if (clanDestruction > opponentDestruction) {
          return isClan ? 'victory' : 'defeat';
        } else if (clanDestruction < opponentDestruction) {
          return isClan ? 'defeat' : 'victory';
        } else {
          return 'draw';
        }
      }
    }

    List<Widget> warHistoryWidgets = [];

    for (var war in warHistoryData) {
      String warResult = determineWarResult(war, clanTag);
      Color color;
      String warResultString;
      if (warResult == 'victory') {
        color = Colors.green;
        warResultString = AppLocalizations.of(context)?.victory ?? 'Victory';
      } else if (warResult == 'defeat') {
        color = Colors.red;
        warResultString = AppLocalizations.of(context)?.defeat ?? 'Defeat';
      } else {
        color = Colors.blue;
        warResultString = AppLocalizations.of(context)?.draw ?? 'Draw';
      }
      warHistoryWidgets.add(
        Container(
          margin: EdgeInsets.only(top: 10),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(
                          width: 70,
                          height: 70,
                          child: CachedNetworkImage(imageUrl: war['clan']['badgeUrls']['large'],
                              fit: BoxFit.cover),
                        ),
                        Text(war['clan']['name'],
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: <Widget>[
                        Text(
                          AppLocalizations.of(context)?.warEnded ?? 'War ended',
                          style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)
                        ),
                        Text(
                          warResultString,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold, color: color),
                        ),
                        Center(
                          child: Text(
                              '${war['clan']['stars'].toString().padRight(2, ' ')} - ${war['opponent']['stars'].toString().padRight(2, ' ')} ',
                              style: Theme.of(context)
                            .textTheme
                            .titleMedium
                          ),
                        ),
                        Center(
                            child: Text(
                                '${war['clan']['destructionPercentage'].toStringAsFixed(2).padLeft(5, '0')}%    ${war['opponent']['destructionPercentage'].toStringAsFixed(2).padLeft(5, ' ')}%')),
                        Center(child: Text(' ')),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(
                          width: 70,
                          height:70,
                          child: CachedNetworkImage(imageUrl: war['opponent']['badgeUrls']['large'],
                              fit: BoxFit.cover),
                        ),
                        Text(war['opponent']['name'],
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall),
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
    return Column(children: warHistoryWidgets);
  }
}