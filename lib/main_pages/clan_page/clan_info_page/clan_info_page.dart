import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:clashkingapp/api/clan_info.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/main_pages/dashboard_page/player_dashboard/player_info_page.dart';
import 'package:clashkingapp/api/player_account_info.dart';
import 'package:clashkingapp/components/filter_dropdown.dart';

class ClanInfoScreen extends StatefulWidget {
  final ClanInfo clanInfo;

  ClanInfoScreen({super.key, required this.clanInfo});

  @override
  ClanInfoScreenState createState() => ClanInfoScreenState();
}

class ClanInfoScreenState extends State<ClanInfoScreen>
    with SingleTickerProviderStateMixin {
  String backgroundImageUrl =
      "https://clashkingfiles.b-cdn.net/landscape/clan-landscape.png";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: <Widget>[
                      SizedBox(
                        height: 240,
                        width: double.infinity,
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                          child: ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                Colors.black.withOpacity(0.6),
                                BlendMode.darken,
                              ),
                              child: CachedNetworkImage(
                                imageUrl: backgroundImageUrl,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )),
                        ),
                      ),
                      Column(children: [
                        CachedNetworkImage(
                          imageUrl: widget.clanInfo.badgeUrls.large,
                          width: 110,
                        ),
                        Text(
                          widget.clanInfo.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ]),
                      Positioned(
                        top: 30,
                        left: 10,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 32),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ScrollableTab(
              labelColor: Theme.of(context).colorScheme.onBackground,
              tabBarDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
              unselectedLabelColor: Theme.of(context).colorScheme.onBackground,
              onTap: (value) {
                setState(() {});
              },
              tabs: [
                Tab(text: AppLocalizations.of(context)!.members),
                Tab(text: "Idk"),
              ],
              children: [
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Column(
                    children: [
                      ClanMembers(clanInfo: widget.clanInfo),
                    ],
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.members,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ClanMembers extends StatefulWidget {
  final ClanInfo clanInfo;

  ClanMembers({required this.clanInfo});

  @override
  _ClanMembersState createState() => _ClanMembersState();
}

class _ClanMembersState extends State<ClanMembers> {
  String currentFilter = 'trophies';

  void updateFilter(String newFilter) {
    setState(() {
      currentFilter = newFilter;
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
    };

// Define a map that assigns a weight to each role
    Map<String, int> roleWeights = {
      'leader': 4,
      'coLeader': 3,
      'admin': 2,
      'member': 1,
    };

    // Convert the memberList to a List so we can sort it
    List<Member> members = widget.clanInfo.memberList.toList();

// Sort the members list based on the current filter
    members.sort((a, b) {
      // Use a switch statement to handle different filters
      switch (currentFilter) {
        case 'role':
          return (roleWeights[b.role] ?? 0).compareTo(roleWeights[a.role] ?? 0);
        case 'townHallLevel':
          return b.townHallLevel.compareTo(a.townHallLevel);
        case 'trophies':
          return b.trophies.compareTo(a.trophies);
        case 'expLevel':
          return b.expLevel.compareTo(a.expLevel);
        case 'builderBaseTrophies':
          return b.builderBaseTrophies.compareTo(a.builderBaseTrophies);
        case 'donations':
          return b.donations.compareTo(a.donations);
        case 'donationsReceived':
          return b.donationsReceived.compareTo(a.donationsReceived);
        default:
          return 0;
      }
    });

    return Column(mainAxisSize: MainAxisSize.max, children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FilterDropdown(
              sortBy: currentFilter,
              updateSortBy: updateFilter,
              sortByOptions: filterOptions)
        ],
      ),
      SizedBox(height: 4),
      ...members.asMap().entries.map((entry) {
        int index = entry.key + 1;
        Member member = entry.value;
        return GestureDetector(
            onTap: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                },
              );
              PlayerAccountInfo playerStats =
                  await PlayerService().fetchPlayerStats(member.tag);
              Navigator.pop(context); // Dismiss the dialog
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StatsScreen(playerStats: playerStats),
                ),
              );
            },
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text(index.toString(),
                                style: Theme.of(context).textTheme.bodyMedium)),
                        Expanded(
                            flex: 6,
                            child: Row(children: [
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("${member.name} ",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium),
                                  Text(
                                      member.role == 'admin'
                                          ? AppLocalizations.of(context)!.elder
                                          : member.role == 'coLeader'
                                              ? AppLocalizations.of(context)!
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
                            ])),
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
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                    textAlign: TextAlign.right,
                                  )
                                ]);
                              case 'builderBaseTrophies':
                                return Row(children: [
                                  CachedNetworkImage(
                                    imageUrl:
                                        "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Trophy.png",
                                    width: 24,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    member.builderBaseTrophies.toString(),
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                    textAlign: TextAlign.right,
                                  )
                                ]);
                              case 'donations':
                                return Row(children: [
                                  CachedNetworkImage(
                                    imageUrl:
                                        "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Trophy.png",
                                    width: 24,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    member.donations.toString(),
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                    textAlign: TextAlign.right,
                                  )
                                ]);
                              case 'donationsReceived':
                                return Row(children: [
                                  CachedNetworkImage(
                                    imageUrl:
                                        "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Trophy.png",
                                    width: 24,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    member.donationsReceived.toString(),
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                    textAlign: TextAlign.right,
                                  )
                                ]);
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
                              // Add more cases for other filters...
                              default:
                                return SizedBox
                                    .shrink(); // Return an empty widget by default
                            }
                          }(),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ));
      }).toList(),
    ]);
  }
}
