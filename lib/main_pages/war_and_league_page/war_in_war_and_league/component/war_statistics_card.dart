import 'package:flutter/material.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_in_war_and_league/war_functions.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/api/current_war_info.dart';
import 'package:lucide_icons/lucide_icons.dart';

class WarStatisticsCard extends StatelessWidget {
  const WarStatisticsCard({
    super.key,
    required this.currentWarInfo,
  });

  final CurrentWarInfo currentWarInfo;

  @override
  Widget build(BuildContext context) {
    Map<int, int> clanStarCounts =
        countStars(currentWarInfo.clan.members);
    Map<int, int> opponentStarCounts =
        countStars(currentWarInfo.opponent.members);

    int numberOfAttacks = currentWarInfo.type == 'cwl'
        ? currentWarInfo.teamSize
        : currentWarInfo.teamSize * 2;
    final double clanStarsPercentage =
        currentWarInfo.clan.stars / (currentWarInfo.teamSize * 3);
    final double opponentStarsPercentage =
        currentWarInfo.opponent.stars /
            (currentWarInfo.teamSize * 3);
    final double clanAttacksPercentage =
        currentWarInfo.clan.attacks / numberOfAttacks;
    final double opponentAttacksPercentage =
        currentWarInfo.opponent.attacks / numberOfAttacks;
 return 
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                              currentWarInfo.clan.badgeUrls.small),
                          Text(currentWarInfo.clan.name),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                              currentWarInfo.opponent.badgeUrls.small),
                          Text(currentWarInfo.opponent.name),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
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
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                        width: 25,
                        child: Image.network(
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
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface),
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
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                        width: 25,
                        child: Image.network(
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
                            padding: const EdgeInsets.only(
                                top:
                                    5), // Ajoute de l'espace vertical au-dessus du texte
                            child: Center(
                              child: Text(
                                '${currentWarInfo.opponent.attacks}/$numberOfAttacks',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface),
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
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                        width: 25, child: Icon(LucideIcons.percent, size: 25)),
                    Expanded(
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: LinearProgressIndicator(
                              value: currentWarInfo.opponent
                                      .destructionPercentage
                                      .toDouble() /
                                  100,
                              backgroundColor: Colors.grey[300],
                              color: Colors.red,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                top:
                                    5), // Ajoute de l'espace vertical au-dessus du texte
                            child: Center(
                              child: Text(
                                '${currentWarInfo.opponent.destructionPercentage.toStringAsFixed(2)}%',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text("Number of stars"),
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
                              child: Image.network(
                                  "https://clashkingfiles.b-cdn.net/icons/Icon_BB_Empty_Star.png")),
                          SizedBox(
                              width: 25,
                              child: Image.network(
                                  "https://clashkingfiles.b-cdn.net/icons/Icon_BB_Empty_Star.png")),
                          SizedBox(
                              width: 25,
                              child: Image.network(
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
                              child: Image.network(
                                  "https://clashkingfiles.b-cdn.net/icons/Icon_BB_Star.png")),
                          SizedBox(
                              width: 25,
                              child: Image.network(
                                  "https://clashkingfiles.b-cdn.net/icons/Icon_BB_Empty_Star.png")),
                          SizedBox(
                              width: 25,
                              child: Image.network(
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
                          child: Image.network(
                              "https://clashkingfiles.b-cdn.net/icons/Icon_BB_Star.png"),
                        ),
                        SizedBox(
                          width: 25,
                          child: Image.network(
                              "https://clashkingfiles.b-cdn.net/icons/Icon_BB_Star.png"),
                        ),
                        SizedBox(
                            width: 25,
                            child: Image.network(
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
                        child: Image.network(
                            "https://clashkingfiles.b-cdn.net/icons/Icon_BB_Star.png"),
                      ),
                      SizedBox(
                        width: 25,
                        child: Image.network(
                            "https://clashkingfiles.b-cdn.net/icons/Icon_BB_Star.png"),
                      ),
                      SizedBox(
                        width: 25,
                        child: Image.network(
                            "https://clashkingfiles.b-cdn.net/icons/Icon_BB_Star.png"),
                      ),
                    ]),
                    Text(opponentStarCounts[3].toString()),
                  ],
                ),
              ],
            ),
          ),
        );
  }
}