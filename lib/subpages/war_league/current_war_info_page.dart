import 'package:flutter/material.dart';
import 'package:clashkingapp/api/current_war_info.dart';
import 'dart:ui';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';

class CurrentWarInfoScreen extends StatefulWidget {
  final CurrentWarInfo currentWarInfo;

  CurrentWarInfoScreen({Key? key, required this.currentWarInfo})
      : super(key: key);

  @override
  CurrentWarInfoScreenState createState() => CurrentWarInfoScreenState();
}

class CurrentWarInfoScreenState extends State<CurrentWarInfoScreen>
    with TickerProviderStateMixin {
  late TabController tabController;
  late TabController subTabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    subTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
            child: Column(children: [
      Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          SizedBox(
            height: 230,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.5),
                  BlendMode.darken,
                ),
                child: Image.network(
                  "https://clashkingfiles.b-cdn.net/landscape/war-landscape.jpg",
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                timeLeft(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                              widget.currentWarInfo.clan.badgeUrls.large,
                              width: 100),
                          Text(
                            widget.currentWarInfo.clan.name,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "VS",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                              widget.currentWarInfo.opponent.badgeUrls.large,
                              width: 100),
                          Text(
                            widget.currentWarInfo.opponent.name,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: Theme.of(context).colorScheme.onPrimary, size: 32),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
      ScrollableTab(
          labelColor: Colors.black,
          onTap: (value) {
            print('Tab $value selected');
          },
          tabs: [
            Tab(text: 'Statistics'),
            Tab(text: 'Events'),
            Tab(text: 'Rosters')
          ],
          children: [
            ListTile(
              title: buildStatisticsTab(context),
            ),
            ListTile(title: buildEventsTab(context)),
            ListTile(title: buildRosterTab(context)),
          ])
    ])));
  }

  Widget timeLeft() {
    DateTime now = DateTime.now();
    Duration difference = widget.currentWarInfo.endTime.difference(now);

    String hours = difference.inHours.toString().padLeft(2, '0');
    String minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: Text(
          'Ending in $hours:$minutes',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
        ),
      ),
    );
  }

  Widget buildStatisticsTab(BuildContext context) {
    // Calculs pour les pourcentages des barres de progression
    final double clanStarsPercentage =
        widget.currentWarInfo.clan.stars / (widget.currentWarInfo.teamSize * 3);
    final double opponentStarsPercentage =
        widget.currentWarInfo.opponent.stars /
            (widget.currentWarInfo.teamSize * 3);
    final double clanAttacksPercentage = widget.currentWarInfo.clan.attacks /
        (widget.currentWarInfo.teamSize * 2);
    final double opponentAttacksPercentage =
        widget.currentWarInfo.opponent.attacks /
            (widget.currentWarInfo.teamSize * 2);

    /*Map<String, int> countStars(List<WarMember> members) {
      int threeStars = 0, twoStars = 0, oneStar = 0, noStars = 0;

      for (final member in members) {
        for (final attack in member.attacks ?? []) {
          switch (attack.stars) {
            case 3:
              threeStars++;
              break;
            case 2:
              twoStars++;
              break;
            case 1:
              oneStar++;
              break;
            case 0:
              noStars++;
              break;
          }
        }
      }

      return {
        'threeStars': threeStars,
        'twoStars': twoStars,
        'oneStar': oneStar,
        'noStars': noStars,
      };
    }*/

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Pourcentage de destruction pour chaque clan
        Center(
            child: Text(
                '${widget.currentWarInfo.clan.destructionPercentage.toStringAsFixed(2)}% - ${widget.currentWarInfo.opponent.destructionPercentage.toStringAsFixed(2)}%')),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Text('Attacks'),
              Row(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        LinearProgressIndicator(
                          value: clanAttacksPercentage,
                          backgroundColor: Colors.grey[300],
                          color: Colors.blue,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Center(
                            child: Text(
                              '${widget.currentWarInfo.clan.attacks}/${widget.currentWarInfo.teamSize * 2}',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Stack(
                      children: [
                        LinearProgressIndicator(
                          value: opponentAttacksPercentage,
                          backgroundColor: Colors.grey[300],
                          color: Colors.red,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              top:
                                  5), // Ajoute de l'espace vertical au-dessus du texte
                          child: Center(
                            child: Text(
                              '${widget.currentWarInfo.opponent.attacks}/${widget.currentWarInfo.teamSize * 2}',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text('Stars'),
              Row(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        LinearProgressIndicator(
                          value: clanStarsPercentage,
                          backgroundColor: Colors.grey[300],
                          color: Colors.blue,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              top:
                                  5), // Ajoute de l'espace vertical au-dessus du texte
                          child: Center(
                            child: Text(
                              '${widget.currentWarInfo.clan.stars}/${widget.currentWarInfo.teamSize * 3}',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Stack(
                      children: [
                        LinearProgressIndicator(
                          value: opponentStarsPercentage,
                          backgroundColor: Colors.grey[300],
                          color: Colors.red,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Center(
                            child: Text(
                              '${widget.currentWarInfo.opponent.stars}/${widget.currentWarInfo.teamSize * 3}',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],

      // Statistiques d'étoiles pour chaque clan
      /*Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            children: [
              Text('Clan 3 Stars: ${clanStarCounts['threeStars']}'),
              Text('Clan 2 Stars: ${clanStarCounts['twoStars']}'),
              Text('Clan 1 Star: ${clanStarCounts['oneStar']}'),
              Text('Clan 0 Stars: ${clanStarCounts['noStars']}'),
              Text('Opponent 3 Stars: ${opponentStarCounts['threeStars']}'),
              Text('Opponent 2 Stars: ${opponentStarCounts['twoStars']}'),
              Text('Opponent 1 Star: ${opponentStarCounts['oneStar']}'),
              Text('Opponent 0 Stars: ${opponentStarCounts['noStars']}'),
            ],
          ),
        ),*/
      // Ajout d'autres statistiques si nécessaire
    );
  }

  Widget buildEventsTab(BuildContext context) {
    // Placeholder pour les événements, ajoute ta propre logique ici
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Pourcentage de destruction pour chaque clan
        Center(
          child: Text('First line of content for Events'),
        )
      ],
    );
  }

  Widget buildRosterTab(BuildContext context) {
    // Placeholder pour les rosters, ajoute ta propre logique ici
    return ScrollableTab(
        labelColor: Colors.black,
        onTap: (value) {
          print('Tab $value selected');
        },
        tabs: [
          Tab(text: 'Membres'),
          Tab(text: 'Ennemis'),
        ],
        children: [
          ListTile(
            title: buildMemberListView(
                widget.currentWarInfo.clan.members, context),
          ),
          ListTile(
            title: buildMemberListView(
                widget.currentWarInfo.opponent.members, context),
          )
        ]);
  }

  Widget buildMemberListView(List<WarMember> members, BuildContext context) {
    members.sort((a, b) => a.mapPosition.compareTo(b.mapPosition));

    List<Widget> memberWidgets = members.map((member) {
      List<Widget> details = [];

      // Générer les détails des attaques
      if (member.attacks != null) {
        for (var attack in member.attacks!) {
          details.add(
            Row(
              children: <Widget>[
                Expanded(child: Text(attack.defenderTag)),
                Text('${attack.destructionPercentage}% - '),
                ...generateStars(attack.stars), 
              ],
            ),
          );
        }
        // Assurez-vous d'avoir deux messages d'attaque si nécessaire
        for (int i = details.length;
            i < widget.currentWarInfo.attacksPerMember;
            i++) {
          details.add(Text('Attack ${i + 1} not done yet'));
        }
      } else {
        // Aucune attaque n'a été réalisée
        for (int i = 0; i < widget.currentWarInfo.attacksPerMember; i++) {
          details.add(Text('Attack ${i + 1} not done yet'));
        }
      }

      details.add(Text('Defense(s) : ${member.opponentAttacks}'));

      // Ajouter les détails de la meilleure attaque de l'opposant, si disponible
      if (member.bestOpponentAttack != null) {
        var bestAttack = member.bestOpponentAttack!;
        details.add(
          Row(
            mainAxisAlignment: MainAxisAlignment
                .spaceBetween, // Étend les éléments sur l'axe horizontal
            children: <Widget>[
              // Informations de la meilleure attaque à gauche
              Expanded(
                child: Text(
                  'Best : ${bestAttack.order}- ${bestAttack.defenderTag}',
                  style: TextStyle(fontSize: 14),
                  overflow:
                      TextOverflow.ellipsis, // Gère le débordement de texte
                ),
              ),
              // Étoiles alignées à droite
              Row(
                children: <Widget>[
                  Text(
                    '${bestAttack.destructionPercentage}% - ',
                    style: TextStyle(fontSize: 14),
                  ),
                  ...generateStars(bestAttack.stars),
                ],
              ),
            ],
          ),
        );
      }

      return ListTile(
        title: Text(
          '${member.mapPosition}- ${member.name}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...details,
          ],
        ),
        trailing: Icon(
          (member.attacks?.length ?? 0) ==
                  widget.currentWarInfo.attacksPerMember
              ? Icons.check
              : Icons.close,
          color: (member.attacks?.length ?? 0) ==
                  widget.currentWarInfo.attacksPerMember
              ? Colors.green
              : Colors.red,
        ),
        onTap: () {
          // Action sur le tap
        },
      );
    }).toList();

    return Column(
      children: memberWidgets,
    );
  }

  List<Widget> generateStars(int numberOfStars) {
    return List<Widget>.generate(3, (index) {
      return Icon(
        index < numberOfStars ? Icons.star : Icons.star_border,
        color: index < numberOfStars ? Colors.yellow : Colors.grey,
        size: 16,
      );
    });
  }
}
