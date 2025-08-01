import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class WarCard extends StatelessWidget {
  const WarCard(
      {super.key, required this.currentWarInfo, required this.clanTag});

  final WarInfo currentWarInfo;
  final String clanTag;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
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
    );
  }

  Widget _warEnded(BuildContext context, String clanTag) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          flex: 3,
          child: Column(
            children: <Widget>[
              SizedBox(
                width: 70,
                height: 70,
                child: CachedNetworkImage(
                    errorWidget: (context, url, error) => Icon(Icons.error),
                    imageUrl: currentWarInfo.clan!.badgeUrls.large,
                    fit: BoxFit.cover),
              ),
              Text(currentWarInfo.clan!.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        Expanded(
          flex: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(AppLocalizations.of(context)?.warEnded ?? 'War ended',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              ((currentWarInfo.clan!.tag == clanTag &&
                          currentWarInfo.clan!.stars >
                              currentWarInfo.opponent!.stars) ||
                      (currentWarInfo.opponent!.tag == clanTag &&
                          currentWarInfo.clan!.stars <
                              currentWarInfo.opponent!.stars) ||
                      (currentWarInfo.clan!.tag == clanTag &&
                          currentWarInfo.clan!.destructionPercentage >
                              currentWarInfo.opponent!.destructionPercentage) ||
                      (currentWarInfo.opponent!.tag == clanTag &&
                          currentWarInfo.clan!.destructionPercentage <
                              currentWarInfo.opponent!.destructionPercentage))
                  ? Text(
                      AppLocalizations.of(context)?.warVictory ?? 'Victory',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold, color: Colors.green),
                    )
                  : ((currentWarInfo.clan!.tag == clanTag &&
                              currentWarInfo.clan!.stars <
                                  currentWarInfo.opponent!.stars) ||
                          (currentWarInfo.opponent!.tag == clanTag &&
                              currentWarInfo.clan!.stars >
                                  currentWarInfo.opponent!.stars) ||
                          (currentWarInfo.clan!.tag == clanTag &&
                              currentWarInfo.clan!.destructionPercentage <
                                  currentWarInfo
                                      .opponent!.destructionPercentage) ||
                          (currentWarInfo.opponent!.tag == clanTag &&
                              currentWarInfo.clan!.destructionPercentage >
                                  currentWarInfo
                                      .opponent!.destructionPercentage))
                      ? Text(
                          AppLocalizations.of(context)?.warDefeat ?? 'Defeat',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red),
                        )
                      : Text(
                          AppLocalizations.of(context)?.warDraw ?? 'Draw',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
              Text(
                '${currentWarInfo.clan!.stars.toString().padLeft(2, ' ')} - ${currentWarInfo.opponent!.stars.toString().padRight(2, ' ')} ',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                  '${currentWarInfo.clan!.destructionPercentage % 1 == 0 ? currentWarInfo.clan!.destructionPercentage.toInt().toString().padLeft(6, ' ') : currentWarInfo.clan!.destructionPercentage.toStringAsFixed(2).padLeft(5, '0')}%    ${currentWarInfo.opponent!.destructionPercentage % 1 == 0 ? ('${currentWarInfo.opponent!.destructionPercentage.toInt()}%').padRight(7, ' ') : ('${currentWarInfo.opponent!.destructionPercentage.toStringAsFixed(2)}%').padLeft(5, ' ')}'),
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
                child: CachedNetworkImage(
                    errorWidget: (context, url, error) => Icon(Icons.error),
                    imageUrl: currentWarInfo.opponent!.badgeUrls.large,
                    fit: BoxFit.cover),
              ),
              Text(currentWarInfo.opponent!.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _preparationState(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Expanded(
        flex: 3,
        child: Column(
          children: <Widget>[
            SizedBox(
              width: 70,
              height: 70,
              child: CachedNetworkImage(
                  errorWidget: (context, url, error) => Icon(Icons.error),
                  imageUrl: currentWarInfo.clan!.badgeUrls.large,
                  fit: BoxFit.cover),
            ),
            Text(
              currentWarInfo.clan!.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      Expanded(
        flex: 4,
        child: Column(
          children: [
            Text(
              '${AppLocalizations.of(context)?.timeStartsAt(DateFormat('HH:mm').format(currentWarInfo.startTime!.toLocal()))}',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              AppLocalizations.of(context)?.warPreparation ?? 'Preparation',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
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
              child: CachedNetworkImage(
                  errorWidget: (context, url, error) => Icon(Icons.error),
                  imageUrl: currentWarInfo.opponent!.badgeUrls.large,
                  fit: BoxFit.cover),
            ),
            Text(
              currentWarInfo.opponent!.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _inWarState(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 70,
                height: 70,
                child: CachedNetworkImage(
                    errorWidget: (context, url, error) => Icon(Icons.error),
                    imageUrl: currentWarInfo.clan!.badgeUrls.large,
                    fit: BoxFit.cover),
              ),
              Text(
                currentWarInfo.clan!.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Expanded(
          flex: 4,
          child: Column(
            children: <Widget>[
              Text(
                  "${AppLocalizations.of(context)?.timeEndsAt(DateFormat('HH:mm').format(currentWarInfo.endTime!.toLocal()))}",
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center),
              Center(
                child: Text(
                  '${currentWarInfo.clan!.stars.toString().padLeft(2, ' ')} - ${currentWarInfo.opponent!.stars.toString().padRight(2, ' ')} ',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Center(
                child: Text(
                    '${currentWarInfo.clan!.destructionPercentage % 1 == 0 ? currentWarInfo.clan!.destructionPercentage.toInt().toString().padLeft(6, ' ') : currentWarInfo.clan!.destructionPercentage.toStringAsFixed(2).padLeft(5, '0')}%    ${currentWarInfo.opponent!.destructionPercentage % 1 == 0 ? ('${currentWarInfo.opponent!.destructionPercentage.toInt()}%').padRight(7, ' ') : ('${currentWarInfo.opponent!.destructionPercentage.toStringAsFixed(2)}%').padLeft(5, ' ')}',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
              SizedBox(height: 10),
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
                child: CachedNetworkImage(
                    errorWidget: (context, url, error) => Icon(Icons.error),
                    imageUrl: currentWarInfo.opponent!.badgeUrls.large,
                    fit: BoxFit.cover),
              ),
              Text(
                currentWarInfo.opponent!.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        )
      ],
    );
  }
}
