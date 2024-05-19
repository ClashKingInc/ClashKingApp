import 'package:flutter/material.dart';
import 'package:clashkingapp/api/current_war_info.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_in_war_and_league/war_functions.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CurrentWarInfoCard extends StatelessWidget {
  const CurrentWarInfoCard(
      {super.key, required this.currentWarInfo, required this.clanTag});

  final CurrentWarInfo currentWarInfo;
  final String clanTag;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: () {
                switch (currentWarInfo.state) {
                  case 'preparation':
                    return _preparationState(context);
                  case 'inWar':
                    return _inWarState(context);
                  case 'warEnded':
                    return _warEnded(context, clanTag);
                  default:
                    return Text('Clan state unknown');
                }
              }(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _warEnded(BuildContext context, String clanTag) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Expanded(
            flex: 3,
            child: Column(
              children: <Widget>[
                SizedBox(
                  width: 70,
                  height: 70,
                  child: CachedNetworkImage(imageUrl: currentWarInfo.clan.badgeUrls.large,
                      fit: BoxFit.cover),
                ),
                Text(currentWarInfo.clan.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            )),
        Expanded(
          flex: 4,
          child: Column(
            children: <Widget>[
              Text(AppLocalizations.of(context)?.warEnded ?? 'War ended',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              ((currentWarInfo.clan.tag == clanTag &&
                          currentWarInfo.clan.stars >
                              currentWarInfo.opponent.stars) ||
                      (currentWarInfo.opponent.tag == clanTag &&
                          currentWarInfo.clan.stars <
                              currentWarInfo.opponent.stars) ||
                      (currentWarInfo.clan.tag == clanTag &&
                          currentWarInfo.clan.destructionPercentage >
                              currentWarInfo.opponent.destructionPercentage) ||
                      (currentWarInfo.opponent.tag == clanTag &&
                          currentWarInfo.clan.destructionPercentage <
                              currentWarInfo.opponent.destructionPercentage))
                  ? Text(AppLocalizations.of(context)?.victory ?? 'Victory',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold, color: Colors.green))
                  : ((currentWarInfo.clan.tag == clanTag &&
                              currentWarInfo.clan.stars <
                                  currentWarInfo.opponent.stars) ||
                          currentWarInfo.opponent.tag == clanTag &&
                              currentWarInfo.clan.stars >
                                  currentWarInfo.opponent.stars ||
                          (currentWarInfo.clan.tag == clanTag &&
                              currentWarInfo.clan.destructionPercentage <
                                  currentWarInfo
                                      .opponent.destructionPercentage) ||
                          (currentWarInfo.opponent.tag == clanTag &&
                              currentWarInfo.clan.destructionPercentage >
                                  currentWarInfo
                                      .opponent.destructionPercentage))
                      ? Text(AppLocalizations.of(context)?.defeat ?? 'Defeat',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red))
                      : Text(AppLocalizations.of(context)?.draw ?? 'Tie',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
              Text(
                  '${currentWarInfo.clan.stars.toString().padRight(2, ' ')} - ${currentWarInfo.opponent.stars.toString().padRight(2, ' ')} ',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(
                  '${currentWarInfo.clan.destructionPercentage.toStringAsFixed(2).padLeft(5, '0')}%    ${currentWarInfo.opponent.destructionPercentage.toStringAsFixed(2).padLeft(5, ' ')}%'),
              Text('')
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            children: <Widget>[
              SizedBox(
                width: 70,
                height: 70,
                child: CachedNetworkImage(imageUrl: currentWarInfo.opponent.badgeUrls.large,
                    fit: BoxFit.cover),
              ),
              Text(currentWarInfo.opponent.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _preparationState(BuildContext context) {
    DateTime now = DateTime.now();
    Duration difference = currentWarInfo.startTime.difference(now);

    String hours = difference.inHours.toString().padLeft(2, '0');
    String minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');

    return Row(
      children: <Widget>[
        Expanded(
          flex: 3,
          child: Column(
            children: <Widget>[
              SizedBox(
                width: 70,
                height: 70,
                child: CachedNetworkImage(imageUrl: currentWarInfo.clan.badgeUrls.large,
                    fit: BoxFit.cover),
              ),
              Text(currentWarInfo.clan.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall)
            ],
          ),
        ),
        Expanded(
          flex: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(AppLocalizations.of(context)?.preparation ?? 'Preparation',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall),
              SizedBox(height: 20),
              Text('${AppLocalizations.of(context)?.startsIn} $hours:$minutes',
                  textAlign: TextAlign.center),
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
                height: 70,
                child: CachedNetworkImage(imageUrl: currentWarInfo.opponent.badgeUrls.large,
                    fit: BoxFit.cover),
              ),
              Text(currentWarInfo.opponent.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        )
      ],
    );
  }

  Widget _inWarState(BuildContext context) {
    Widget timeLeftText = timeLeft(currentWarInfo, context, Theme.of(context).textTheme.bodyMedium);

    return Row(
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
                  child: CachedNetworkImage(imageUrl: currentWarInfo.clan.badgeUrls.large,
                      fit: BoxFit.cover),
                ),
                Text(currentWarInfo.clan.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            )),
        Expanded(
            flex: 4,
            child: Column(
              children: <Widget>[
                timeLeftText,
                Center(
                    child: Text(
                        '${currentWarInfo.clan.stars.toString().padRight(2, ' ')} - ${currentWarInfo.opponent.stars.toString().padRight(2, ' ')} ',
                        style: Theme.of(context)
                      .textTheme
                      .titleMedium)),
                Center(
                    child: Text(
                        '${currentWarInfo.clan.destructionPercentage.toStringAsFixed(2).padLeft(5, '0')}%    ${currentWarInfo.opponent.destructionPercentage.toStringAsFixed(2).padLeft(5, ' ')}%')),
                Center(child: Text(' ')),
              ],
            )),
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 70,
                height:70,
                child: CachedNetworkImage(imageUrl: currentWarInfo.opponent.badgeUrls.large,
                    fit: BoxFit.cover),
              ),
              Text(currentWarInfo.opponent.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        )
      ],
    );
  }
}
