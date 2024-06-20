import 'package:flutter/material.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war/war_functions.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/classes/clan/war_league/current_war_info.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WarStatisticsCard extends StatelessWidget {
  const WarStatisticsCard({
    super.key,
    required this.currentWarInfo,
  });

  final CurrentWarInfo currentWarInfo;

  @override
  Widget build(BuildContext context) {
    Map<int, int> clanStarCounts = countStars(currentWarInfo.clan.members);
    Map<int, int> opponentStarCounts =
        countStars(currentWarInfo.opponent.members);

    String getWarStatus() {
      if (currentWarInfo.clan.stars < currentWarInfo.opponent.stars) {
        return AppLocalizations.of(context)?.starsNeededToTakeTheLead(
                currentWarInfo.clan.name,
                currentWarInfo.opponent.stars - currentWarInfo.clan.stars + 1,
                currentWarInfo.opponent.stars - currentWarInfo.clan.stars,
                (currentWarInfo.opponent.destructionPercentage -
                        currentWarInfo.clan.destructionPercentage +
                        0.01)
                    .toStringAsFixed(2),
                currentWarInfo.opponent.stars - currentWarInfo.clan.stars) ??
            "";
      } else if (currentWarInfo.clan.stars > currentWarInfo.opponent.stars) {
        return AppLocalizations.of(context)?.starsNeededToTakeTheLead(
                currentWarInfo.opponent.name,
                currentWarInfo.clan.stars - currentWarInfo.opponent.stars + 1,
                currentWarInfo.clan.stars - currentWarInfo.opponent.stars,
                (currentWarInfo.clan.destructionPercentage -
                        currentWarInfo.opponent.destructionPercentage +
                        0.01)
                    .toStringAsFixed(2),
                currentWarInfo.clan.stars - currentWarInfo.opponent.stars) ??
            "";
      } else if (currentWarInfo.clan.destructionPercentage >
          currentWarInfo.opponent.destructionPercentage) {
        return AppLocalizations.of(context)?.starsAndPercentNeededToTakeTheLead(
              currentWarInfo.clan.name,
              (currentWarInfo.clan.destructionPercentage -
                      currentWarInfo.opponent.destructionPercentage +
                      0.01)
                  .toStringAsFixed(2),
            ) ??
            '';
      } else if (currentWarInfo.clan.destructionPercentage <
          currentWarInfo.opponent.destructionPercentage) {
        return AppLocalizations.of(context)?.starsAndPercentNeededToTakeTheLead(
              currentWarInfo.opponent.name,
              (currentWarInfo.opponent.destructionPercentage -
                      currentWarInfo.clan.destructionPercentage +
                      0.01)
                  .toStringAsFixed(2),
            ) ??
            "";
      } else {
        return '${AppLocalizations.of(context)?.clanDraw ?? 'The two clans are tied'}.';
      }
    }

    int numberOfAttacks = currentWarInfo.type == 'cwl'
        ? currentWarInfo.teamSize
        : currentWarInfo.teamSize * 2;
    final double clanStarsPercentage =
        currentWarInfo.clan.stars / (currentWarInfo.teamSize * 3);
    final double opponentStarsPercentage =
        currentWarInfo.opponent.stars / (currentWarInfo.teamSize * 3);
    final double clanAttacksPercentage =
        currentWarInfo.clan.attacks / numberOfAttacks;
    final double opponentAttacksPercentage =
        currentWarInfo.opponent.attacks / numberOfAttacks;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(AppLocalizations.of(context)?.stars ?? 'Stars'),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: LinearProgressIndicator(
                          value: clanStarsPercentage,
                          backgroundColor: Colors.grey[300],
                          color: Colors.blue,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Center(
                          child: Text(
                            '${currentWarInfo.clan.stars}/${currentWarInfo.teamSize * 3}',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                    width: 25,
                    child: CachedNetworkImage(
                        imageUrl:
                            "https://clashkingfiles.b-cdn.net/icons/Icon_BB_Star.png")),
                Expanded(
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: LinearProgressIndicator(
                          value: opponentStarsPercentage,
                          backgroundColor: Colors.grey[300],
                          color: Colors.red,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Center(
                          child: Text(
                            '${currentWarInfo.opponent.stars}/${currentWarInfo.teamSize * 3}',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(AppLocalizations.of(context)?.attacks ?? 'Attacks'),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: LinearProgressIndicator(
                          value: clanAttacksPercentage,
                          backgroundColor: Colors.grey[300],
                          color: Colors.blue,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Center(
                          child: Text(
                            '${currentWarInfo.clan.attacks}/$numberOfAttacks',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                    width: 25,
                    child: CachedNetworkImage(
                        imageUrl:
                            "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Sword.png")),
                Expanded(
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: LinearProgressIndicator(
                          value: opponentAttacksPercentage,
                          backgroundColor: Colors.grey[300],
                          color: Colors.red,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Center(
                          child: Text(
                            '${currentWarInfo.opponent.attacks}/$numberOfAttacks',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(AppLocalizations.of(context)?.destructionRate ??
                'Destruction rate'),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: LinearProgressIndicator(
                          value: currentWarInfo.clan.destructionPercentage
                                  .toDouble() /
                              100,
                          backgroundColor: Colors.grey[300],
                          color: Colors.blue,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Center(
                          child: Text(
                            '${currentWarInfo.clan.destructionPercentage.toStringAsFixed(2)}%',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                    width: 25,
                    child: Icon(LucideIcons.percent,
                        size: 25,
                        color: Theme.of(context).colorScheme.onSurface)),
                Expanded(
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: LinearProgressIndicator(
                          value: currentWarInfo.opponent.destructionPercentage
                                  .toDouble() /
                              100,
                          backgroundColor: Colors.grey[300],
                          color: Colors.red,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Center(
                          child: Text(
                            '${currentWarInfo.opponent.destructionPercentage.toStringAsFixed(2)}%',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(AppLocalizations.of(context)?.numberOfStars ??
                "Number of stars"),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(clanStarCounts[0].toString()),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      SizedBox(
                          width: 25,
                          child: CachedNetworkImage(
                              imageUrl:
                                  "https://clashkingfiles.b-cdn.net/icons/Icon_BB_Empty_Star.png")),
                      SizedBox(
                          width: 25,
                          child: CachedNetworkImage(
                              imageUrl:
                                  "https://clashkingfiles.b-cdn.net/icons/Icon_BB_Empty_Star.png")),
                      SizedBox(
                          width: 25,
                          child: CachedNetworkImage(
                              imageUrl:
                                  "https://clashkingfiles.b-cdn.net/icons/Icon_BB_Empty_Star.png")),
                    ]),
                Text(opponentStarCounts[0].toString()),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(clanStarCounts[1].toString()),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      SizedBox(
                          width: 25,
                          child: CachedNetworkImage(
                              imageUrl:
                                  "https://clashkingfiles.b-cdn.net/icons/Icon_BB_Star.png")),
                      SizedBox(
                          width: 25,
                          child: CachedNetworkImage(
                              imageUrl:
                                  "https://clashkingfiles.b-cdn.net/icons/Icon_BB_Empty_Star.png")),
                      SizedBox(
                          width: 25,
                          child: CachedNetworkImage(
                              imageUrl:
                                  "https://clashkingfiles.b-cdn.net/icons/Icon_BB_Empty_Star.png")),
                    ]),
                Text(opponentStarCounts[1].toString()),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(clanStarCounts[2].toString()),
                Row(
                  children: [
                    SizedBox(
                      width: 25,
                      child: CachedNetworkImage(
                          imageUrl:
                              "https://clashkingfiles.b-cdn.net/icons/Icon_BB_Star.png"),
                    ),
                    SizedBox(
                      width: 25,
                      child: CachedNetworkImage(
                          imageUrl:
                              "https://clashkingfiles.b-cdn.net/icons/Icon_BB_Star.png"),
                    ),
                    SizedBox(
                        width: 25,
                        child: CachedNetworkImage(
                            imageUrl:
                                "https://clashkingfiles.b-cdn.net/icons/Icon_BB_Empty_Star.png")),
                  ],
                ),
                Text(opponentStarCounts[2].toString()),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(clanStarCounts[3].toString()),
                Row(children: [
                  SizedBox(
                    width: 25,
                    child: CachedNetworkImage(
                        imageUrl:
                            "https://clashkingfiles.b-cdn.net/icons/Icon_BB_Star.png"),
                  ),
                  SizedBox(
                    width: 25,
                    child: CachedNetworkImage(
                        imageUrl:
                            "https://clashkingfiles.b-cdn.net/icons/Icon_BB_Star.png"),
                  ),
                  SizedBox(
                    width: 25,
                    child: CachedNetworkImage(
                        imageUrl:
                            "https://clashkingfiles.b-cdn.net/icons/Icon_BB_Star.png"),
                  ),
                ]),
                Text(opponentStarCounts[3].toString()),
              ],
            ),
            if (currentWarInfo.state == 'inWar') ...{
              SizedBox(height: 20),
              Text(AppLocalizations.of(context)?.stateOfTheWar ??
                  'State of the war'),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      getWarStatus(),
                      softWrap: true,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            }
          ],
        ),
      ),
    );
  }
}
