import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/classes/clan/description/member.dart';
import 'package:clashkingapp/components/filter_dropdown.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/classes/clan/clan_info.dart';
import 'package:clashkingapp/main_pages/dashboard_page/player_dashboard/player_info_page.dart';
import 'package:clashkingapp/classes/profile/profile_info.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class ClanMembers extends StatefulWidget {
  final Clan clanInfo;
  final List<String> discordUser;

  ClanMembers({required this.clanInfo, required this.discordUser});

  @override
  ClanMembersState createState() => ClanMembersState();
}

class ClanMembersState extends State<ClanMembers> {
  String currentFilter = 'trophies';
  bool linkFilterActive = false;

  void updateFilter(String newFilter) {
    setState(() {
      currentFilter = newFilter;
    });
  }

  void toggleLinkFilter() {
    setState(() {
      linkFilterActive = !linkFilterActive;
    });
  }

  @override
  Widget build(BuildContext context) {
    Map<String, String> filterOptions = {
      AppLocalizations.of(context)?.role ?? 'Role': 'role',
      AppLocalizations.of(context)?.townHallLevel ?? 'Town Hall Level':
          'townHallLevel',
      AppLocalizations.of(context)?.trophies ?? 'Trophies': 'trophies',
      AppLocalizations.of(context)?.expLevel ?? 'Experience Level': 'expLevel',
      AppLocalizations.of(context)?.builderBaseTrophies ??
          'Builder Base Trophies': 'builderBaseTrophies',
      AppLocalizations.of(context)?.donations ?? 'Donations': 'donations',
      AppLocalizations.of(context)?.donationsReceived ?? 'Donations received':
          'donationsReceived',
      AppLocalizations.of(context)?.donationsRatio ?? 'Donation Ratio':
          'donationsRatio',
    };

// Define a map that assigns a weight to each role
    Map<String, int> roleWeights = {
      'leader': 4,
      'coLeader': 3,
      'admin': 2,
      'member': 1,
    };

    // Convert the memberList to a List so we can sort it
    List<Member> members = widget.clanInfo.memberList!.toList();

    List<Member> filteredMembers = linkFilterActive
        ? members.where((m) => widget.discordUser.contains(m.tag)).toList()
        : members;

    // Sort the members list based on the current filter
    filteredMembers.sort((a, b) {
      // Use a switch statement to handle different filters
      switch (currentFilter) {
        case 'role':
          int roleComparison =
              (roleWeights[b.role] ?? 0).compareTo(roleWeights[a.role] ?? 0);
          return roleComparison != 0
              ? roleComparison
              : b.townHallLevel.compareTo(a.townHallLevel) != 0
                  ? b.townHallLevel.compareTo(a.townHallLevel)
                  : b.trophies.compareTo(a.trophies);
        case 'townHallLevel':
          int townHallComparison = b.townHallLevel.compareTo(a.townHallLevel);
          return townHallComparison != 0
              ? townHallComparison
              : b.trophies.compareTo(a.trophies);
        case 'trophies':
          int trophiesComparison = b.trophies.compareTo(a.trophies);
          return trophiesComparison != 0
              ? trophiesComparison
              : b.townHallLevel.compareTo(a.townHallLevel);
        case 'expLevel':
          int expLevelComparison = b.expLevel.compareTo(a.expLevel);
          return expLevelComparison != 0
              ? expLevelComparison
              : b.townHallLevel.compareTo(a.townHallLevel);
        case 'builderBaseTrophies':
          int builderBaseTrophiesComparison =
              b.builderBaseTrophies.compareTo(a.builderBaseTrophies);
          return builderBaseTrophiesComparison != 0
              ? builderBaseTrophiesComparison
              : b.townHallLevel.compareTo(a.townHallLevel);
        case 'donations':
          int donationsComparison = b.donations.compareTo(a.donations);
          return donationsComparison != 0
              ? donationsComparison
              : b.townHallLevel.compareTo(a.townHallLevel);
        case 'donationsReceived':
          int donationsReceivedComparison =
              b.donationsReceived.compareTo(a.donationsReceived);
          return donationsReceivedComparison != 0
              ? donationsReceivedComparison
              : b.townHallLevel.compareTo(a.townHallLevel);
        case 'donationsRatio':
          int ratioComparison = ((b.donations /
                      (b.donationsReceived == 0 ? 1 : b.donationsReceived)) *
                  1000)
              .toInt()
              .compareTo(((a.donations /
                          (a.donationsReceived == 0
                              ? 1
                              : a.donationsReceived)) *
                      1000)
                  .toInt());
          return ratioComparison != 0
              ? ratioComparison
              : b.townHallLevel.compareTo(a.townHallLevel);
        default:
          return 0;
      }
    });

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilterDropdown(
                      sortBy: currentFilter,
                      updateSortBy: updateFilter,
                      sortByOptions: filterOptions),
                  SizedBox(height: 6),
                ],
              ),
            ),
            Positioned(
              top: -4,
              right: 20,
              child: IconButton(
                icon: Icon(Icons.link,
                    color: linkFilterActive ? Colors.green : Colors.grey),
                onPressed: toggleLinkFilter,
                tooltip: 'Filter by Discord Users',
              ),
            ),
          ],
        ),
        if (filteredMembers.isEmpty)
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                AppLocalizations.of(context)
                        ?.noAccountLinkedToYourProfileFound ??
                    'No account linked to your profile found',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...filteredMembers.asMap().entries.map((entry) {
            int index = entry.key + 1;
            Member member = entry.value;
            return GestureDetector(
              onTap: () async {
                final navigator = Navigator.of(context);
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                );
                ProfileInfo profileInfo =
                    await ProfileInfoService().fetchProfileInfo(member.tag);
                navigator.pop(); // Dismiss the dialog
                navigator.push(
                  MaterialPageRoute(
                    builder: (context) => StatsScreen(
                        playerStats: profileInfo,
                        discordUser: widget.discordUser),
                  ),
                );
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: widget.discordUser.contains(member.tag)
                        ? Colors.green
                        : Colors.transparent,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(index.toString(),
                                style: Theme.of(context).textTheme.bodyMedium),
                          ),
                          Expanded(
                            flex: 6,
                            child: Row(
                              children: [
                                Column(
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl:
                                          'https://clashkingfiles.b-cdn.net/home-base/town-hall-pics/town-hall-${member.townHallLevel}.png',
                                      width: 40,
                                    ),
                                  ],
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  // Wrap the Text widget with Expanded
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("${member.name} ",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                          overflow: TextOverflow
                                              .ellipsis), // This should now work as expected
                                      Text(
                                          member.role == 'admin'
                                              ? AppLocalizations.of(context)!
                                                  .elder
                                              : member.role == 'coLeader'
                                                  ? AppLocalizations.of(
                                                          context)!
                                                      .coLeader
                                                  : member.role == 'leader'
                                                      ? AppLocalizations.of(
                                                              context)!
                                                          .leader
                                                      : AppLocalizations.of(
                                                              context)!
                                                          .member,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .tertiary)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: () {
                              switch (currentFilter) {
                                case 'expLevel':
                                  return Row(children: [
                                    SizedBox(width: 20),
                                    CachedNetworkImage(
                                      imageUrl:
                                          "https://clashkingfiles.b-cdn.net/icons/Icon_HV_XP.png",
                                      width: 24,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      member.expLevel.toString(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                      textAlign: TextAlign.right,
                                    )
                                  ]);
                                case 'builderBaseTrophies':
                                  try {
                                    return Row(children: [
                                      SizedBox(width: 20),
                                      CachedNetworkImage(
                                        imageUrl:
                                            "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Trophy.png",
                                        width: 24,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        member.builderBaseTrophies.toString(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                        textAlign: TextAlign.right,
                                      )
                                    ]);
                                  } catch (exception, stackTrace) {
                                    Sentry.captureException(exception,
                                        stackTrace: stackTrace);
                                    return SizedBox.shrink();
                                  }
                                case 'donations':
                                  return Row(children: [
                                    SizedBox(width: 20),
                                    Icon(LucideIcons.chevronUp,
                                        color:
                                            Color.fromARGB(255, 27, 114, 33)),
                                    SizedBox(width: 8),
                                    Text(
                                      member.donations.toString(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                      textAlign: TextAlign.right,
                                    )
                                  ]);
                                case 'donationsReceived':
                                  return Row(children: [
                                    SizedBox(width: 20),
                                    Icon(LucideIcons.chevronDown,
                                        color: Color.fromARGB(255, 155, 4, 4)),
                                    SizedBox(width: 8),
                                    Text(
                                      member.donationsReceived.toString(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                      textAlign: TextAlign.right,
                                    )
                                  ]);
                                case 'donationsRatio':
                                  double ratio = (member.donations /
                                      (member.donationsReceived == 0
                                          ? 1
                                          : member.donationsReceived));
                                  return Row(
                                    children: [
                                      SizedBox(width: 20),
                                      Icon(LucideIcons.chevronsUpDown,
                                          color:
                                              Color.fromARGB(255, 0, 136, 255)),
                                      SizedBox(width: 8),
                                      Text(
                                        (ratio) > 100
                                            ? ratio.toInt().toString()
                                            : ratio > 10
                                                ? ratio.toStringAsFixed(1)
                                                : ratio.toStringAsFixed(2),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                        textAlign: TextAlign.right,
                                      ),
                                    ],
                                  );
                                case 'trophies' || 'role' || 'townHallLevel':
                                  return Row(
                                    children: [
                                      SizedBox(width: 20),
                                      CachedNetworkImage(
                                        imageUrl: member.league.imageUrl.tiny,
                                        width: 24,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        member.trophies.toString(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                        textAlign: TextAlign.right,
                                      ),
                                    ],
                                  );
                                default:
                                  return SizedBox.shrink();
                              }
                            }(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
