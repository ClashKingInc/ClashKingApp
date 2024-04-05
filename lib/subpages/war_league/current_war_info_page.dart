import 'package:flutter/material.dart';
import 'package:clashkingapp/api/current_war_info.dart';
import 'dart:ui';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PlayerTab {
  String tag;
  String name;
  int townhallLevel;
  int mapPosition;

  PlayerTab(this.tag, this.name, this.townhallLevel, this.mapPosition);
}

class CurrentWarInfoScreen extends StatefulWidget {
  final CurrentWarInfo currentWarInfo;

  CurrentWarInfoScreen({super.key, required this.currentWarInfo});

  @override
  CurrentWarInfoScreenState createState() => CurrentWarInfoScreenState();
}

class CurrentWarInfoScreenState extends State<CurrentWarInfoScreen>
    with TickerProviderStateMixin {
  late TabController tabController;
  late TabController subTabController;
  List<PlayerTab> playerTab = [];

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    subTabController = TabController(length: 2, vsync: this);

    for (var member in widget.currentWarInfo.clan.members) {
      playerTab.add(PlayerTab(
          member.tag, member.name, member.townhallLevel, member.mapPosition));
    }

    for (var member in widget.currentWarInfo.opponent.members) {
      playerTab.add(PlayerTab(
          member.tag, member.name, member.townhallLevel, member.mapPosition));
    }
  }

  @override
  void dispose() {
    tabController.dispose();
    subTabController.dispose();
    super.dispose();
  }

  String getPlayerNameByTag(String defenderTag) {
    PlayerTab? player = playerTab.firstWhere((p) => p.tag == defenderTag,
        orElse: () => PlayerTab('', 'Inconnu', 0, 0));
    return player.name;
  }

  String getPlayerTownhallByTag(String defenderTag) {
    PlayerTab? player = playerTab.firstWhere((p) => p.tag == defenderTag,
        orElse: () => PlayerTab('', 'Inconnu', 0, 0));
    return player.townhallLevel.toString();
  }

  String getPlayerMapPositionByTag(String defenderTag) {
    PlayerTab? player = playerTab.firstWhere((p) => p.tag == defenderTag,
        orElse: () => PlayerTab('', 'Inconnu', 0, 0));
    return player.mapPosition.toString();
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
          labelColor: Theme.of(context).colorScheme.onBackground,
          unselectedLabelColor: Theme.of(context).colorScheme.onBackground,
          onTap: (value) {
            print('Tab $value selected');
          },
          tabs: [
            Tab(text: AppLocalizations.of(context)?.statistics ?? 'Statistics'),
            Tab(text: AppLocalizations.of(context)?.events ?? 'Events'),
            Tab(text: AppLocalizations.of(context)?.team ?? 'Teams')
          ],
          children: [
            ListTile(title: buildStatisticsTab(context)),
            ListTile(title: buildEventsTab(context)),
            ListTile(title: buildTeamsTab(context)),
          ])
    ])));
  }

  Widget timeLeft() {
    DateTime now = DateTime.now();
    Duration difference = Duration.zero;
    String state = '';

    if (widget.currentWarInfo.state == 'preparation') {
      difference = widget.currentWarInfo.startTime.difference(now);
      state = AppLocalizations.of(context)?.startsIn ?? 'Starting in';
    } else if (widget.currentWarInfo.state == 'inWar') {
      difference = widget.currentWarInfo.endTime.difference(now);
      state = AppLocalizations.of(context)?.endsIn ?? 'Ends in';
    }

    String hours = difference.inHours.toString().padLeft(2, '0');
    String minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: Text(
          widget.currentWarInfo.state == 'warEnded'
              ? AppLocalizations.of(context)?.warEnded ?? 'War ended'
              : '$state $hours:$minutes',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
        ),
      ),
    );
  }

  Widget buildStatisticsTab(BuildContext context) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Center(
            child: Text(
                '${widget.currentWarInfo.clan.destructionPercentage.toStringAsFixed(2)}% - ${widget.currentWarInfo.opponent.destructionPercentage.toStringAsFixed(2)}%')),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Text(AppLocalizations.of(context)?.attacks ?? 'Attacks'),
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
              Text(AppLocalizations.of(context)?.stars ?? 'Stars'),
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
    );
  }

  Widget buildEventsTab(BuildContext context) {
    // Rassemblez toutes les attaques en une seule liste.
    List<Map<String, dynamic>> allAttacks = [];
    for (var member in widget.currentWarInfo.clan.members) {
      member.attacks?.forEach((attack) {
        allAttacks.add({
          "attackerName": member.name,
          "attackerTag": member.tag,
          "defenderTag": attack.defenderTag,
          "stars": attack.stars,
          "destructionPercentage": attack.destructionPercentage,
          "order": attack.order,
          "clan": 0
        });
      });
    }
    for (var member in widget.currentWarInfo.opponent.members) {
      member.attacks?.forEach((attack) {
        allAttacks.add({
          "attackerName": member.name,
          "attackerTag": member.tag,
          "defenderTag": attack.defenderTag,
          "stars": attack.stars,
          "destructionPercentage": attack.destructionPercentage,
          "order": attack.order,
          "clan": 1
        });
      });
    }

    // Étape 2: Trier les attaques par ordre décroissant basé sur "order".
    allAttacks.sort((a, b) => b["order"].compareTo(a["order"]));

    // Étape 3: Utiliser ListView.builder pour afficher les attaques.
    return ListView.builder(
      shrinkWrap: true, // Important pour des widgets déroulables imbriqués.
      physics:
          ClampingScrollPhysics(), // Fournit un meilleur comportement de défilement.
      itemCount: allAttacks.length,
      itemBuilder: (context, index) {
        var attack = allAttacks[index];
        return ListTile(
          title: Text(
              "${getPlayerMapPositionByTag(attack["attackerTag"])}- ${attack["attackerName"]} - ${attack["destructionPercentage"]}%",
              style: TextStyle(fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          subtitle: Text(
              "On ${getPlayerMapPositionByTag(attack["defenderTag"])}- ${getPlayerNameByTag(attack["defenderTag"])}, #${attack["order"]}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: generateStars(attack["stars"]),
          ),
        );
      },
    );
  }

  Widget buildTeamsTab(BuildContext context) {
    return ScrollableTab(
        padding: EdgeInsets.zero,
        labelColor: Colors.black,
        onTap: (value) {
          print('Tab $value selected');
        },
        tabs: [
          Tab(text: AppLocalizations.of(context)?.myTeam ?? 'My team'),
          Tab(text: AppLocalizations.of(context)?.enemiesTeam ?? 'Enemies'),
        ],
        children: [
          Padding(
            padding: EdgeInsets.zero,
            child: buildMemberListView(
                widget.currentWarInfo.clan.members, context),
          ),
          Padding(
            padding: EdgeInsets.zero,
            child: buildMemberListView(
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
          String imageUrlDef =
              'https://clashkingfiles.b-cdn.net/home-base/town-hall-pics/town-hall-${getPlayerTownhallByTag(attack.defenderTag)}.png';
          details.add(
            Row(
              children: <Widget>[
                SizedBox(
                  height: 20,
                  width: 20,
                  child: Image.network(imageUrlDef),
                ),
                Expanded(
                    child: Text(
                        ' ${getPlayerMapPositionByTag(attack.defenderTag)}. ${getPlayerNameByTag(attack.defenderTag)}',
                        style: TextStyle(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
                Text('${attack.destructionPercentage}% - '),
                ...generateStars(attack.stars),
              ],
            ),
          );
        }
        for (int i = details.length;
            i < widget.currentWarInfo.attacksPerMember;
            i++) {
          details.add(Text(
              '${AppLocalizations.of(context)?.attack ?? 'Attack'} ${i + 1} ${AppLocalizations.of(context)?.notUsed ?? 'not used'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis));
        }
      } else {
        // No attacks done
        for (int i = 0; i < widget.currentWarInfo.attacksPerMember; i++) {
          details.add(Text(
              '${AppLocalizations.of(context)?.attack ?? 'Attack'} ${i + 1} ${AppLocalizations.of(context)?.notUsed ?? 'not used'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis));
        }
      }

      details.add(Text(
          '${AppLocalizations.of(context)?.defense ?? 'Defense'}(s) : ${member.opponentAttacks}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis));

      if (member.bestOpponentAttack != null) {
        var bestAttack = member.bestOpponentAttack!;
        details.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              SizedBox(
                width: 20,
                height: 20,
                child: Image.network(
                    'https://clashkingfiles.b-cdn.net/home-base/town-hall-pics/town-hall-${getPlayerTownhallByTag(bestAttack.defenderTag)}.png'),
              ),
              Expanded(
                child: Text(
                    ' ${getPlayerMapPositionByTag(bestAttack.attackerTag)}. ${getPlayerNameByTag(bestAttack.attackerTag)}',
                    style: TextStyle(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
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

      return Column(
        children: [
          SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFFFF8E1),
              border: Border.all(
                color: Colors.black,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              title: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${member.mapPosition}. ${member.name} ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: Image.network(
                        'https://clashkingfiles.b-cdn.net/home-base/town-hall-pics/town-hall-${getPlayerTownhallByTag(member.tag)}.png'),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...details,
                ],
              ),
              trailing: Padding(
                padding: EdgeInsets.only(left: 0),
                child: Icon(
                  (member.attacks?.length ?? 0) ==
                          widget.currentWarInfo.attacksPerMember
                      ? Icons.check
                      : Icons.close,
                  color: (member.attacks?.length ?? 0) ==
                          widget.currentWarInfo.attacksPerMember
                      ? Colors.green
                      : Colors.red,
                ),
              ),
              onTap: () {
                // Press the tap
              },
            ),
          ),
        ],
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
