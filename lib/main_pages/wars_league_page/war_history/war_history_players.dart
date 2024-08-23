import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/classes/clan/clan_info.dart';
import 'package:clashkingapp/classes/clan/description/member.dart';
import 'package:clashkingapp/classes/clan/war_league/member_war_stats.dart';
import 'package:clashkingapp/components/filter_dropdown.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war/war_functions.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war_history/component/war_history_players_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PlayersWarHistoryScreen extends StatefulWidget {
  final Clan clan;
  final List<String> discordUser;

  PlayersWarHistoryScreen(
      {super.key, required this.clan, required this.discordUser});

  @override
  PlayersWarHistoryScreenState createState() => PlayersWarHistoryScreenState();
}

class PlayersWarHistoryScreenState extends State<PlayersWarHistoryScreen>
    with TickerProviderStateMixin {
  String _sortBy = "Three Stars Attacks";
  List<Member> sortedMembers = [];
  bool isCWLChecked = true;
  bool isRandomChecked = true;
  bool isFriendlyChecked = true;
  MembersWarStats? warStats;
  MembersWarStats? defaultWarStats;

  // Track selected Town Hall levels for members and enemies
  Map<int, bool> memberThSelection = {for (int i = 6; i <= 16; i++) i: false};
  Map<int, bool> enemyThSelection = {for (int i = 6; i <= 16; i++) i: false};
  bool equalThSelected = false;

  @override
  void initState() {
    super.initState();
    warStats = widget.clan.membersWarStats!;
    defaultWarStats = warStats;
    _sortMembers();
  }

  void _updateSortBy(String newValue) {
    setState(() {
      _sortBy = newValue;
      _sortMembers();
    });
  }

  void _sortMembers() {
    if (warStats != null) {
      sortedMembers = List.from(widget.clan.memberList!);
      switch (_sortBy) {
        case "Average Destruction":
          sortedMembers.sort((a, b) =>
              warStats!
                  .getMemberByTag(b.tag)
                  ?.averageDestructionPercentage
                  .compareTo(warStats!
                          .getMemberByTag(a.tag)
                          ?.averageDestructionPercentage ??
                      0) ??
              0);
          break;
        case "Average Stars":
          sortedMembers.sort((a, b) =>
              warStats!.getMemberByTag(b.tag)?.averageStars.compareTo(
                  warStats!.getMemberByTag(a.tag)?.averageStars ?? 0) ??
              0);
          break;
        case "No Star Attacks":
          sortedMembers.sort((a, b) =>
              warStats!
                  .getMemberByTag(b.tag)
                  ?.percentageNoStarsAttacks
                  .compareTo(warStats!
                          .getMemberByTag(a.tag)
                          ?.percentageNoStarsAttacks ??
                      0) ??
              0);
          break;
        case "One Star Attacks":
          sortedMembers.sort((a, b) =>
              warStats!
                  .getMemberByTag(b.tag)
                  ?.percentageOneStarsAttacks
                  .compareTo(warStats!
                          .getMemberByTag(a.tag)
                          ?.percentageOneStarsAttacks ??
                      0) ??
              0);
          break;
        case "Two Stars Attacks":
          sortedMembers.sort((a, b) =>
              warStats!
                  .getMemberByTag(b.tag)
                  ?.percentageTwoStarsAttacks
                  .compareTo(warStats!
                          .getMemberByTag(a.tag)
                          ?.percentageTwoStarsAttacks ??
                      0) ??
              0);
          break;
        case "Three Stars Attacks":
          sortedMembers.sort((a, b) =>
              warStats!
                  .getMemberByTag(b.tag)
                  ?.percentageThreeStarsAttacks
                  .compareTo(warStats!
                          .getMemberByTag(a.tag)
                          ?.percentageThreeStarsAttacks ??
                      0) ??
              0);
          break;
        case "War Participation":
          sortedMembers.sort((a, b) {
            MemberWarStats? memberA = warStats!.getMemberByTag(a.tag);
            MemberWarStats? memberB = warStats!.getMemberByTag(b.tag);
            return memberB?.totalAttacks
                    .compareTo(memberA?.totalAttacks ?? 0) ??
                0;
          });
          break;
        default:
          break;
      }
    }
  }

  void showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: AlertDialog(
                title: Text(AppLocalizations.of(context)!.filters,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(AppLocalizations.of(context)!.selectMembersThLevel,
                        style: Theme.of(context).textTheme.bodyMedium),
                    Wrap(
                      spacing: 5.0,
                      children: memberThSelection.keys.map((thLevel) {
                        return FilterChip(
                          label: Text('TH $thLevel'),
                          selected: memberThSelection[thLevel]!,
                          onSelected: (bool selected) {
                            setState(() {
                              memberThSelection[thLevel] = selected;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 10),
                    Text(AppLocalizations.of(context)!.selectOpponentsThLevel,
                        style: Theme.of(context).textTheme.bodyMedium),
                    Wrap(
                      spacing: 5.0,
                      children: enemyThSelection.keys.map((thLevel) {
                        return FilterChip(
                          label: Text('TH $thLevel'),
                          selected: enemyThSelection[thLevel]!,
                          onSelected: (bool selected) {
                            setState(() {
                              enemyThSelection[thLevel] = selected;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 10),
                    CheckboxListTile(
                      title: Text(AppLocalizations.of(context)!.equalThLevel,
                          style: Theme.of(context).textTheme.bodyMedium),
                      value: equalThSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          equalThSelected = value ?? false;
                        });
                      },
                    ),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text(AppLocalizations.of(context)!.cancel),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text(AppLocalizations.of(context)!.apply),
                    onPressed: () {
                      // Apply filters when the user presses "Apply"
                      applyFilters();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void applyFilters() {
    setState(() {
      // Retrieve selected Town Hall levels for members and enemies
      List<int> selectedMemberThLevels = memberThSelection.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      List<int> selectedEnemyThLevels = enemyThSelection.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      // Apply TH filters first
      var filteredMembers = defaultWarStats!.allMembers.where((member) {
        bool matchesMemberTh = selectedMemberThLevels.isEmpty ||
            selectedMemberThLevels.contains(member.townhallLevel);

        if (!matchesMemberTh) {
          return false;
        }

        var filteredWarAttacks = member.warAttacks.map((warAttacks) {
          var filteredAttacks = warAttacks.attacks.where((attack) {
            bool matchesEnemyTh = selectedEnemyThLevels.isEmpty ||
                selectedEnemyThLevels
                    .contains(attack.defender.townhallLevel);

            bool matchesEqualTh = !equalThSelected ||
                member.townhallLevel == attack.defender.townhallLevel;

            return matchesEnemyTh && matchesEqualTh;
          }).toList();

          return Attacks(
            warType: warAttacks.warType,
            attacksExpected: warAttacks.attacksExpected,
            attacks: filteredAttacks,
            missedAttacks: warAttacks.missedAttacks,
          );
        }).where((war) => war.attacks.isNotEmpty).toList();

        return filteredWarAttacks.isNotEmpty;
      }).toList();

      // Apply war type filters on the TH filtered members
      List<String> activeFilters = [];
      if (isCWLChecked) activeFilters.add("cwl");
      if (isRandomChecked) activeFilters.add("random");
      if (isFriendlyChecked) activeFilters.add("friendly");

      if (activeFilters.isNotEmpty) {
        warStats = MembersWarStats(
          items: filteredMembers
              .map((member) {
                var filteredWarAttacks = member.warAttacks
                    .where((war) => activeFilters.contains(war.warType))
                    .toList();

                var filteredMember = MemberWarStats(
                  tag: member.tag,
                  name: member.name,
                  townhallLevel: member.townhallLevel,
                  mapPosition: member.mapPosition,
                  opponentAttacks: member.opponentAttacks,
                )
                  ..warAttacks = filteredWarAttacks
                  ..defenses = member.defenses;

                filteredMember.calculatePercentages();
                filteredMember.warsParticipated = member.warsParticipated;
                filteredMember.expectedAttacks = filteredWarAttacks.fold(
                    0, (sum, war) => sum + war.attacksExpected);
                filteredMember.missedAttacks = member.missedAttacks;

                return filteredMember;
              })
              .where((member) => member.warAttacks.isNotEmpty)
              .toList(),
        );
      } else {
        // If no war type filters are selected, just use the TH-filtered members
        warStats = MembersWarStats(items: filteredMembers);
      }

      // Sort members after filtering
      _sortMembers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            WarHistoryPlayersStatsHeader(
                clan: widget.clan,
                isCWLChecked: isCWLChecked,
                isRandomChecked: isRandomChecked,
                isFriendlyChecked: isFriendlyChecked,
                onCWLChanged: () {
                  setState(() {
                    isCWLChecked = !isCWLChecked;
                    applyFilters();
                  });
                },
                onRandomChanged: () {
                  setState(() {
                    isRandomChecked = !isRandomChecked;
                    applyFilters();
                  });
                },
                onFriendlyChanged: () {
                  setState(() {
                    isFriendlyChecked = !isFriendlyChecked;
                    applyFilters();
                  });
                },
                onBack: () => Navigator.of(context).pop(),
                onFilter: showFilterDialog),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: FilterDropdown(
                sortBy: _sortBy,
                updateSortBy: _updateSortBy,
                sortByOptions: {
                  "Average Stars": "Average Stars",
                  "Average Destruction": "Average Destruction",
                  "No Star Attacks": "No Star Attacks",
                  "One Star Attacks": "One Star Attacks",
                  "Two Stars Attacks": "Two Stars Attacks",
                  "Three Stars Attacks": "Three Stars Attacks",
                  "War Participation": "War Participation",
                },
              ),
            ),
            ...sortedMembers.map((member) {
              MemberWarStats? memberWarStats =
                  warStats?.getMemberByTag(member.tag);

              if (memberWarStats?.warsParticipated == null) {
                return Container();
              }

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CachedNetworkImage(
                                  imageUrl: member.getTownHallPicture(),
                                  height: 50,
                                ),
                                SizedBox(width: 16),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(member.name),
                                    Text(member.tag),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Text(memberWarStats?.warsParticipated
                                            .toString() ??
                                        ""),
                                    SizedBox(width: 8),
                                    CachedNetworkImage(
                                        imageUrl:
                                            "https://assets.clashk.ing/icons/Icon_HV_Clan_War.png",
                                        height: 16,
                                        width: 16),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(memberWarStats?.missedAttacks
                                            .toString() ??
                                        ""),
                                    SizedBox(width: 8),
                                    CachedNetworkImage(
                                        imageUrl:
                                            "https://assets.clashk.ing/bot/icons/broken_sword.png",
                                        height: 16,
                                        width: 16),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.percent, size: 16),
                                    Icon(Icons.star, size: 16),
                                  ],
                                ),
                                Text(memberWarStats
                                        ?.averageDestructionPercentage
                                        .toStringAsFixed(2) ??
                                    ""),
                                Text(memberWarStats?.averageStars
                                        .toStringAsFixed(2) ??
                                    ""),
                              ],
                            ),
                            Column(
                              children: [
                                Row(
                                  children: [...generateStars(0, 16)],
                                ),
                                Text(
                                    "${memberWarStats?.percentageNoStarsAttacks.toStringAsFixed(2)}%"),
                                Text(
                                    "${memberWarStats?.numberOfStarsAttacks(0)}/${memberWarStats?.totalAttacks}"),
                              ],
                            ),
                            Column(
                              children: [
                                Row(
                                  children: [...generateStars(1, 16)],
                                ),
                                Text(
                                    "${memberWarStats?.percentageOneStarsAttacks.toStringAsFixed(2)}%"),
                                Text(
                                    "${memberWarStats?.numberOfStarsAttacks(1)}/${memberWarStats?.totalAttacks}"),
                              ],
                            ),
                            Column(
                              children: [
                                Row(
                                  children: [...generateStars(2, 16)],
                                ),
                                Text(
                                    "${memberWarStats?.percentageTwoStarsAttacks.toStringAsFixed(2)}%"),
                                Text(
                                    "${memberWarStats?.numberOfStarsAttacks(2)}/${memberWarStats?.totalAttacks}"),
                              ],
                            ),
                            Column(
                              children: [
                                Row(
                                  children: [...generateStars(3, 16)],
                                ),
                                Text(
                                    "${memberWarStats?.percentageThreeStarsAttacks.toStringAsFixed(2)}%"),
                                Text(
                                    "${memberWarStats?.numberOfStarsAttacks(3)}/${memberWarStats?.totalAttacks}"),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
