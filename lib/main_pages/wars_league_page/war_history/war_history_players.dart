import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/classes/clan/clan_info.dart';
import 'package:clashkingapp/classes/clan/description/member.dart';
import 'package:clashkingapp/classes/clan/war_league/member_war_stats.dart';
import 'package:clashkingapp/components/filter_dropdown.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war/war_functions.dart';
import 'package:flutter/material.dart';

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
  String _sortBy = "Average Stars"; // Default sort by average stars
  List<Member> sortedMembers = [];

  @override
  void initState() {
    super.initState();
    _sortMembers();
  }

  void _updateSortBy(String newValue) {
    setState(() {
      _sortBy = newValue;
      _sortMembers();
    });
  }

  void _sortMembers() {
    if (widget.clan.membersWarStats != null) {
      sortedMembers = List.from(widget.clan.memberList!);
      switch (_sortBy) {
        case "Average Destruction":
          sortedMembers.sort((a, b) =>
              widget.clan.membersWarStats!
                  .getMemberByTag(b.tag)
                  ?.averageDestructionPercentage
                  .compareTo(widget.clan.membersWarStats!
                          .getMemberByTag(a.tag)
                          ?.averageDestructionPercentage ??
                      0) ??
              0);
          break;
        case "Average Stars":
          sortedMembers.sort((a, b) =>
              widget.clan.membersWarStats!
                  .getMemberByTag(b.tag)
                  ?.averageStars
                  .compareTo(widget.clan.membersWarStats!
                          .getMemberByTag(a.tag)
                          ?.averageStars ??
                      0) ??
              0);
          break;
        case "No Star Attacks":
          sortedMembers.sort((a, b) =>
              widget.clan.membersWarStats!
                  .getMemberByTag(b.tag)
                  ?.percentageNoStarsAttacks
                  .compareTo(widget.clan.membersWarStats!
                          .getMemberByTag(a.tag)
                          ?.percentageNoStarsAttacks ??
                      0) ??
              0);
          break;
        case "One Star Attacks":
          sortedMembers.sort((a, b) =>
              widget.clan.membersWarStats!
                  .getMemberByTag(b.tag)
                  ?.percentageOneStarsAttacks
                  .compareTo(widget.clan.membersWarStats!
                          .getMemberByTag(a.tag)
                          ?.percentageOneStarsAttacks ??
                      0) ??
              0);
          break;
        case "Two Stars Attacks":
          sortedMembers.sort((a, b) =>
              widget.clan.membersWarStats!
                  .getMemberByTag(b.tag)
                  ?.percentageTwoStarsAttacks
                  .compareTo(widget.clan.membersWarStats!
                          .getMemberByTag(a.tag)
                          ?.percentageTwoStarsAttacks ??
                      0) ??
              0);
          break;
        case "Three Stars Attacks":
          sortedMembers.sort((a, b) =>
              widget.clan.membersWarStats!
                  .getMemberByTag(b.tag)
                  ?.percentageThreeStarsAttacks
                  .compareTo(widget.clan.membersWarStats!
                          .getMemberByTag(a.tag)
                          ?.percentageThreeStarsAttacks ??
                      0) ??
              0);
          break;
        case "War Participation":
          sortedMembers.sort((a, b) {
            MemberWarStats? memberA =
                widget.clan.membersWarStats!.getMemberByTag(a.tag);
            MemberWarStats? memberB =
                widget.clan.membersWarStats!.getMemberByTag(b.tag);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 120),
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
                  widget.clan.membersWarStats?.getMemberByTag(member.tag);

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
}
