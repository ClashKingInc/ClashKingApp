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
  late DateTime currentSeasonDate;
  String filterType = "dateRange";
  bool isCWLChecked = true;
  bool isRandomChecked = true;
  bool isFriendlyChecked = true;
  List<String> filters = ["cwl", "random", "friendly"];
  late int warDataStartDate;
  late int warDataEndDate;
  late int warDataLimit;
  MembersWarStats? warStats;
  MembersWarStats? defaultWarStats;

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
    final TextEditingController _textController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.filters,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: Text(AppLocalizations.of(context)!.byNumberOfWars,
                    style: Theme.of(context).textTheme.bodyMedium),
                onTap: () async {
                  Navigator.of(context).pop();
                  await showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(
                            AppLocalizations.of(context)!.byNumberOfWars,
                            style: Theme.of(context).textTheme.bodyMedium),
                        content: TextField(
                          controller: _textController,
                          decoration: InputDecoration(hintText: "e.g., 5"),
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: false),
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: Text(AppLocalizations.of(context)!.ok),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.bySeason,
                    style: Theme.of(context).textTheme.bodyMedium),
                onTap: () async {
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.byDateRange,
                    style: Theme.of(context).textTheme.bodyMedium),
                onTap: () async {
                  Navigator.of(context).pop();
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
          ],
        );
      },
    );
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

              //print("${memberWarStats?.name} : ${memberWarStats?.expectedAttacks}, ${memberWarStats?.missedAttacks}, ${memberWarStats?.warsParticipated} ");

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

  void applyFilters() {
    setState(() {
      List<String> activeFilters = [];
      if (isCWLChecked) activeFilters.add("cwl");
      if (isRandomChecked) activeFilters.add("random");
      if (isFriendlyChecked) activeFilters.add("friendly");

      if (activeFilters.isNotEmpty) {
        warStats = MembersWarStats(
          items: defaultWarStats!.allMembers
              .map((member) {
                // Filter the warAttacks within each member
                var filteredWarAttacks = member.warAttacks
                    .where((war) => activeFilters.contains(war.warType))
                    .toList();

                // Create a new MemberWarStats object with the filtered warAttacks
                var filteredMember = MemberWarStats(
                  tag: member.tag,
                  name: member.name,
                  townhallLevel: member.townhallLevel,
                  mapPosition: member.mapPosition,
                  opponentAttacks: member.opponentAttacks,
                )
                  ..warAttacks = filteredWarAttacks
                  ..defenses = member.defenses;

                // Recalculate stats based on filtered warAttacks
                filteredMember.calculatePercentages();

                // Recalculate warsParticipated, expectedAttacks, and missedAttacks
                filteredMember.warsParticipated = filteredWarAttacks.length;
                filteredMember.expectedAttacks = filteredWarAttacks.fold(
                    0, (sum, war) => sum + war.attacksExpected);
                filteredMember.missedAttacks = filteredWarAttacks.fold(
                    0,
                    (sum, war) =>
                        sum + (war.attacksExpected - war.attacks.length));

                return filteredMember;
              })
              .where((member) => member.warAttacks.isNotEmpty)
              .toList(),
        );
        print("Filtered Members: ${warStats!.allMembers.length}");
      } else {
        warStats = defaultWarStats;
        print("No filters selected, using default stats.");
      }

      _sortMembers();
    });
  }
}
