import 'package:flutter/material.dart';
import 'package:clashkingapp/api/current_war_info.dart';
import 'package:flutter/widgets.dart'; // Assure-toi que ce chemin d'importation est correct

class CurrentWarInfoScreen extends StatelessWidget {
  final CurrentWarInfo currentWarInfo;

  CurrentWarInfoScreen({Key? key, required this.currentWarInfo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Current War Info'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Statistics'),
              Tab(text: 'Events'),
              Tab(text: 'Roster'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            buildStatisticsTab(context),
            buildEventsTab(context),
            buildRosterTab(context),
          ],
        ),
      ),
    );
  }

  Widget buildStatisticsTab(BuildContext context) {
    DateTime now = DateTime.now();
    Duration difference = currentWarInfo.endTime.difference(now);

    String hours = difference.inHours.toString().padLeft(2, '0');
    String minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');

    // Calculs pour les pourcentages des barres de progression
    final double clanStarsPercentage = currentWarInfo.clan.stars / (currentWarInfo.teamSize * 3);
    final double opponentStarsPercentage = currentWarInfo.opponent.stars / (currentWarInfo.teamSize * 3);
    final double clanAttacksPercentage = currentWarInfo.clan.attacks / (currentWarInfo.teamSize * 2);
    final double opponentAttacksPercentage = currentWarInfo.opponent.attacks / (currentWarInfo.teamSize * 2);

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

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: Column(
                children: [
                  Image.network(currentWarInfo.clan.badgeUrls.large, fit: BoxFit.cover, width: 90, height: 90),
                  Text(currentWarInfo.clan.name, textAlign: TextAlign.center),
                ],
              ),
            ),
            Text("VS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
            Expanded(
              child: Column(
                children: [
                  Image.network(currentWarInfo.opponent.badgeUrls.large, fit: BoxFit.cover, width: 90, height: 90),
                  Text(currentWarInfo.opponent.name, textAlign: TextAlign.center),
                ],
              ),
            ),
          ],
        ),
        // Temps restant avant la fin de la guerre
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Center(
            child: Text(
              'Ending in $hours:$minutes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        // Pourcentage de destruction pour chaque clan
        Center(child: Text('${currentWarInfo.clan.destructionPercentage.toStringAsFixed(2)}% - ${currentWarInfo.opponent.destructionPercentage.toStringAsFixed(2)}%')),
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
                              '${currentWarInfo.clan.attacks}/${currentWarInfo.teamSize * 2}',
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
                          padding: const EdgeInsets.only(top: 5), // Ajoute de l'espace vertical au-dessus du texte
                          child: Center(
                            child: Text(
                              '${currentWarInfo.opponent.attacks}/${currentWarInfo.teamSize * 2}',
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
                          padding: const EdgeInsets.only(top: 5), // Ajoute de l'espace vertical au-dessus du texte
                          child: Center(
                            child: Text(
                              '${currentWarInfo.clan.stars}/${currentWarInfo.teamSize * 3}',
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
                              '${currentWarInfo.opponent.stars}/${currentWarInfo.teamSize * 3}',
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
      ],
    );
  }


  Widget buildEventsTab(BuildContext context) {
    // Placeholder pour les événements, ajoute ta propre logique ici
    return ListView(
      children: [
        Text('First line of content for Events'),
      ],
    );
  }

  Widget buildRosterTab(BuildContext context) {
    return DefaultTabController(
      length: 2, // Nombre d'onglets pour Clan et Opponent
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 30, // Maximum width
                        height: 30, // Maximum height
                        child: Image.network(currentWarInfo.clan.badgeUrls.large, fit: BoxFit.cover),
                      ),
                      Text('  ${currentWarInfo.clan.name}', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
              Tab(
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 30, // Maximum width
                        height: 30, // Maximum height
                        child: Image.network(currentWarInfo.opponent.badgeUrls.large, fit: BoxFit.cover),
                      ),
                      Text('  ${currentWarInfo.opponent.name}', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                buildMemberListView(currentWarInfo.clan.members, context),
                buildMemberListView(currentWarInfo.opponent.members, context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMemberListView(List<WarMember> members, BuildContext context) {
    members.sort((a, b) => a.mapPosition.compareTo(b.mapPosition));

    return ListView.builder(
      itemCount: members.length,
      itemBuilder: (context, index) {
        var member = members[index];
        List<Widget> details = []; // Utilisé pour stocker les détails des attaques et de la meilleure attaque

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
          for (int i = details.length; i < currentWarInfo.attacksPerMember; i++) {
            details.add(Text('Attack ${i + 1} not done yet'));
          }
        } else {
          // Aucune attaque n'a été réalisée
          for (int i = 0; i < currentWarInfo.attacksPerMember; i++) {
            details.add(Text('Attack ${i + 1} not done yet'));
          }
        }

        details.add(Text('Defense(s) : ${member.opponentAttacks}'));

        // Ajouter les détails de la meilleure attaque de l'opposant, si disponible
        if (member.bestOpponentAttack != null) {
          var bestAttack = member.bestOpponentAttack!;
          details.add(
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Étend les éléments sur l'axe horizontal
              children: <Widget>[
                // Informations de la meilleure attaque à gauche
                Expanded(
                  child: Text(
                    'Best : ${bestAttack.order}- ${bestAttack.defenderTag}',
                    style: TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis, // Gère le débordement de texte
                  ),
                ),
                // Étoiles alignées à droite
                Row(
                  children: <Widget>[
                    Text(
                      '${bestAttack.destructionPercentage}% - ',
                      style: TextStyle(fontSize: 14),
                    ),
                    ...generateStars(bestAttack.stars), // Générer les étoiles pour la meilleure défense
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
            (member.attacks?.length ?? 0) == currentWarInfo.attacksPerMember ? Icons.check : Icons.close,
            color: (member.attacks?.length ?? 0) == currentWarInfo.attacksPerMember ? Colors.green : Colors.red,
          ),
          onTap: () {
            // Action sur le tap
          },
        );
      },
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