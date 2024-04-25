import 'package:flutter/material.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_in_war_and_league/war_functions.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_in_war_and_league/current_war_info_page.dart';
import 'package:clashkingapp/api/current_war_info.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WarTeamCard extends StatelessWidget {
  WarTeamCard({
    super.key,
    required this.playerTab,
    required this.widget,
    required this.members,
    required this.discordUser,
  });

  final List<PlayerTab> playerTab;
  final CurrentWarInfoScreen widget;
  final List<WarMember> members;
  final List<String> discordUser;

  @override
  Widget build(BuildContext context) {
    late int numberOfAttacks = 2;
    if (widget.currentWarInfo.type == "cwl") {
      numberOfAttacks = 1;
    }

    members.sort((a, b) => a.mapPosition.compareTo(b.mapPosition));

    List<Widget> memberWidgets = members.map((member) {
      var bestAttack = member.bestOpponentAttack;
      return Card(
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: widget.discordUser.contains(member.tag) ? Colors.green : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(children: [
                  Expanded(
                    flex: 4,
                    child: Container(), 
                  ),
                  Expanded(
                    flex: 6,
                    child: Center(
                      child: Text(
                        "${AppLocalizations.of(context)!.defense} (${member.opponentAttacks})",
                        style: Theme.of(context).textTheme.bodySmall ?.copyWith(
                            color: Theme.of(context).colorScheme.tertiary),
                      ),
                    ),
                  ),
                ]),
                if (bestAttack != null)
                  Column(
                    children: List<Widget>.generate(
                      1,
                      (index) {
                        String imageUrlDef =
                            'https://clashkingfiles.b-cdn.net/home-base/town-hall-pics/town-hall-${getPlayerTownhallByTag(bestAttack.defenderTag, playerTab)}.png';
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                                flex: 3,
                                child: Column(
                                  children: [
                                    Text(
                                      '${bestAttack.destructionPercentage}%',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        ...generateStars(bestAttack.stars, 16),
                                      ],
                                    )
                                  ],
                                )),
                            Expanded(
                                flex: 1,
                                child: SizedBox(
                                    height: 26,
                                    width: 26,
                                    child: Image.network(
                                        'https://clashkingfiles.b-cdn.net/icons/Icon_DC_ArrowLeft.png'))),
                            Expanded(
                                flex: 6,
                                child: Row(children: [
                                  SizedBox(width: 8),
                                  SizedBox(
                                    width: 30,
                                    child: Image.network(imageUrlDef),
                                  ),
                                  Expanded(
                                    child: Text(
                                      ' ${getPlayerMapPositionByTag(bestAttack.attackerTag, playerTab)}. ${getPlayerNameByTag(bestAttack.attackerTag, playerTab)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ])),
                          ],
                        );
                      },
                    ),
                  )
                else
                  SizedBox.shrink(),
                Row(children: [
                  Expanded(
                    flex: 4,
                    child: Container(), // Add this line
                  ),
                  Expanded(
                    flex: 6,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          "${AppLocalizations.of(context)!.attacks} (${member.attacks?.length ?? 0}/$numberOfAttacks) ",
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.tertiary),
                        ),
                        Positioned(
                          right: 10,
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: Image.network(
                              (member.attacks?.length ?? 0) ==
                                      widget.currentWarInfo.attacksPerMember
                                  ? "https://clashkingfiles.b-cdn.net/icons/Icon_DC_Tick.png"
                                  : "https://clashkingfiles.b-cdn.net/icons/Icon_DC_Cross.png",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          SizedBox(
                            width: 70,
                            height: 70,
                            child: Image.network(
                                'https://clashkingfiles.b-cdn.net/home-base/town-hall-pics/town-hall-${getPlayerTownhallByTag(member.tag, playerTab)}.png'),
                          ),
                          Text(
                            '${member.mapPosition}. ${member.name} ',
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: Image.network(
                            'https://clashkingfiles.b-cdn.net/icons/Icon_DC_ArrowRight.png'),
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: Column(
                        children: List<Widget>.generate(
                          numberOfAttacks, // Always display two attacks
                          (index) {
                            if (member.attacks == null ||
                                member.attacks!.length <= index) {
                              return Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 8),
                                child: Row(children: [
                                  SizedBox(width: 30),
                                  Text(
                                    ' ...',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  )
                                ]),
                              );
                            } else {
                              final attack = member.attacks![index];
                              String imageUrlDef =
                                  'https://clashkingfiles.b-cdn.net/home-base/town-hall-pics/town-hall-${getPlayerTownhallByTag(attack.defenderTag, playerTab)}.png';
                              return Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 8),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 30,
                                      child: Image.network(imageUrlDef),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ' ${getPlayerMapPositionByTag(attack.defenderTag, playerTab)}. ${getPlayerNameByTag(attack.defenderTag, playerTab)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Row(
                                            children: [
                                              ...generateStars(attack.stars, 16),
                                              Text(
                                                ' - ${attack.destructionPercentage}%',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelLarge,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )),
      );
    }).toList();

    return Column(
      children: memberWidgets,
    );
  }
}
