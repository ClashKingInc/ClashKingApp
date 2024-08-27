import 'package:clashkingapp/classes/clan/capital/raids_history.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/classes/clan/clan_info.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_capital/components/clan_capital_header.dart';
import 'package:clashkingapp/classes/clan/description/member.dart';

class CapitalScreen extends StatefulWidget {
  final Clan? clanInfo;
  final List<String> user;

  CapitalScreen({super.key, required this.clanInfo, required this.user});

  @override
  CapitalScreenState createState() => CapitalScreenState();
}

class CapitalScreenState extends State<CapitalScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  late DateTime selectedWeek;
  bool filterAccountActive = false;
  String filterBy = "all";
 
  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    selectedWeek = _getStartOfWeek(DateTime.now());
  }

  DateTime _getStartOfWeek(DateTime date) {
    int dayOfWeek = date.weekday;
    DateTime startOfWeek = date.subtract(Duration(days: (dayOfWeek + 1) % 7)); // Adjust the day to Friday
    return startOfWeek;
  }

  void incrementWeek() {
    setState(() {
      selectedWeek = selectedWeek.add(Duration(days: 7));
    });
  }

  void decrementWeek() {
    setState(() {
      selectedWeek = selectedWeek.subtract(Duration(days: 7));
    });
  }

  Future<void> _refreshData() async {
    // Fetch the updated profile information
    //final profileInfo =
    //    await ProfileInfoService().fetchProfileInfo(widget.playerStats.tag);

    setState(() {
      // Update the player stats with the newly fetched data
      //widget.playerStats.updateFrom(profileInfo!);
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();

    if (widget.clanInfo?.clanCapitalRaid != null && widget.clanInfo!.clanCapitalRaid.items.isNotEmpty) {
      var firstRaid = widget.clanInfo!.clanCapitalRaid.items.first;
      List<Member> nonParticipants = getNonParticipatingMembers(firstRaid);

      bool isOngoing = firstRaid.state == 'ongoing';

      return Scaffold(
        body: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            child: Column(
              children: [
                ClanCapitalHeader(
                  user: widget.user,
                  clanInfo: widget.clanInfo,
                ),
                ScrollableTab(
                  labelColor: Theme.of(context).colorScheme.onSurface,
                  labelPadding: EdgeInsets.zero,
                  labelStyle: Theme.of(context).textTheme.bodyLarge,
                  tabBarDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  unselectedLabelColor:
                      Theme.of(context).colorScheme.onSurface,
                  tabs: [
                    Tab(text: AppLocalizations.of(context)!.lastRaids),
                    Tab(text: AppLocalizations.of(context)!.history),
                  ],
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 8, right: 8, top: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(
                                  filterBy == "all"
                                    ? LucideIcons.list
                                    : filterBy == "done"
                                      ? LucideIcons.check
                                      : LucideIcons.x,
                                  color: Theme.of(context).colorScheme.tertiary),
                                onPressed: () {
                                  setState(() {
                                    switch (filterBy) {
                                      case "all":
                                        filterBy = "done";
                                        break;
                                      case "done":
                                        filterBy = "notDone";
                                        break;
                                      default:
                                        filterBy = "all";
                                    }
                                  });
                                },
                                tooltip: 'Filter Remaining Attacks',
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.link,
                                  color: filterAccountActive ? Colors.green : Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    filterAccountActive = !filterAccountActive;
                                  });
                                },
                                tooltip: 'Filter Active Users',
                              ),
                            ],
                          ),
                        ),
                        buildLastRaids(firstRaid, locale, isOngoing),
                        if (filterBy == "all" || filterBy == "done") buildLastRaidsMembers(firstRaid),
                        if ((filterBy == "all" || filterBy == "notDone") && isOngoing) ...buildNonParticipantWidgets(nonParticipants) else SizedBox.shrink(),
                        SizedBox(height: 10),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10),
                        buildHistory(locale),
                        SizedBox(height: 10),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return Column(
        children: [
          SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                AppLocalizations.of(context)?.noDataAvailable ?? 'No data available',
              ),
            ),
          ),
          SizedBox(height: 32),
          CachedNetworkImage(
            imageUrl: 'https://assets.clashk.ing/stickers/Villager_HV_Villager_7.png',
            height: 250,
            width: 200,
          ),
        ],
      );
    }
  }

  List<Member> getNonParticipatingMembers(firstRaid) {
    List<Member> nonParticipants = [];
    Set<String> raidParticipantTags = widget.clanInfo!.clanCapitalRaid.items
        .expand((item) => item.members!.map((member) => member.tag))
        .toSet();

    if (widget.clanInfo!.memberList != null) {
      for (var member in widget.clanInfo!.memberList!) {
        if (!raidParticipantTags.contains(member.tag)) {
          nonParticipants.add(member);
        }
      }
    }
    return nonParticipants;
  }

  List<Widget> buildNonParticipantWidgets(List<Member> nonParticipants) {
    return nonParticipants.where((member) => !filterAccountActive || widget.user.contains(member.tag)).map((member) {
      return Card(
        margin: EdgeInsets.only(left: 12, right: 12, bottom: 4, top: 4),
        elevation: 4,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.red, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                height: 40,
                width: 40,
                child: CachedNetworkImage(
                  imageUrl: 'https://assets.clashk.ing/capital-base/clan-houses/Building_CC_Vacant_House.png',
                  placeholder: (context, url) => CircularProgressIndicator(),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: Theme.of(context).textTheme.bodyLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      member.tag,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Icon(Icons.close, color: Colors.red),
            ],
          ),
        ),
      );
    }).toList();
  }

  //List<Widget> _buildStars(int count) {
  //  return List<Widget>.generate(
  //    count,
  //    (index) => CachedNetworkImage(
  //      imageUrl: 'https://assets.clashk.ing/icons/Icon_BB_Star.png',
  //      width: 22.0,
  //      height: 22.0,
  //    ),
  //  );
  //}

  Widget buildLastRaids(firstRaid, locale, isOngoing) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Card(
            margin: EdgeInsets.only(left: 12, right: 12, bottom: 4, top: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isOngoing
                          ? AppLocalizations.of(context)!.ongoingRaids
                          : AppLocalizations.of(context)!.lastRaids,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(width: 4),
                      isOngoing
                        ? CachedNetworkImage(
                            height: 24,
                            width: 24,
                            imageUrl: 'https://assets.clashk.ing/bot/icons/animated_clash_swords.gif',
                          )
                      : SizedBox.shrink(),
                    ],
                  ),
                  Text(
                    "(${DateFormat.yMMMd(locale).format(firstRaid.startTime)} - ${DateFormat.yMMMd(locale).format(firstRaid.endTime)})",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Column(
                          children: [
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 32,
                                    width: 32,
                                    child: CachedNetworkImage(
                                      imageUrl: 'https://assets.clashk.ing/bot/icons/raid_medal.png',
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text(isOngoing
                                    ? AppLocalizations.of(context)!.comingSoon
                                    : '${6 * firstRaid.offensiveReward + firstRaid.defensiveReward}',
                                    style: Theme.of(context).textTheme.titleMedium,  
                                  ),
                                ],
                            )
                          ],
                        ),
                      ],
                    )
                  ),       
                  SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: Align(
                      alignment: Alignment.center,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CachedNetworkImage(
                                      imageUrl: 'https://assets.clashk.ing/icons/Icon_HV_Raid_Attack.png',
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    "${NumberFormat('#,###', Localizations.localeOf(context).toString()).format(firstRaid.raidsCompleted)} ${AppLocalizations.of(context)!.raidsCompleted}",
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(NumberFormat('#,###', Localizations.localeOf(context).toString()).format(firstRaid.capitalTotalLoot)),
                                  SizedBox(width: 2),
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CachedNetworkImage(
                                      imageUrl: 'https://assets.clashk.ing/icons/Icon_CC_Resource_Capital_Gold_small.png',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  ClipRect(
                                    child: Transform.scale(
                                      scale: 1.3,
                                      child: CachedNetworkImage(
                                        height: 24,
                                        width: 24,
                                        fit: BoxFit.cover,
                                        imageUrl: 'https://assets.clashk.ing/capital-base/capital-hall-pics/Building_CC_District_Hall_level_5.png',
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  Text("${firstRaid.enemyDistrictsDestroyed} ${AppLocalizations.of(context)!.districtsDestroyed}"),
                                ],
                              ),
                              Row(
                                children: [
                                  Text("${firstRaid.totalAttacks}"),
                                  SizedBox(width: 2),
                                  ClipRect(
                                    child: Transform.scale(
                                      scale: 0.8,
                                      child: CachedNetworkImage(
                                        height: 24,
                                        width: 24,
                                        fit: BoxFit.cover,
                                        imageUrl: 'https://assets.clashk.ing/bot/icons/thick_capital_sword.png',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget buildLastRaidsMembers(firstRaid) {
    return Column(
      children: [
        SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              Text(
                "${AppLocalizations.of(context)!.members} (${firstRaid.members.length}/50)",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 10),
              ...buildMemberWidgets(firstRaid.members),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> buildMemberWidgets(List<RaidMember> raidMembers) {
    raidMembers.sort((a, b) => b.capitalResourcesLooted.compareTo(a.capitalResourcesLooted));

    return raidMembers.where((member) => !filterAccountActive || widget.user.contains(member.tag)).map((member) {
      bool isInDiscord = widget.user.contains(member.tag);

      return Card(
        margin: EdgeInsets.only(left: 12, right: 12, bottom: 4, top: 4),
        elevation: 4,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: isInDiscord
              ? Colors.green
              : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                height: 40,
                width: 40,
                child: CachedNetworkImage(
                  imageUrl: 'https://assets.clashk.ing/capital-base/clan-houses/Building_CC_Clan_House.png',
                  placeholder: (context, url) => CircularProgressIndicator(),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: Theme.of(context).textTheme.bodyLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      member.tag,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${member.attacks}/${member.attackLimit + member.bonusAttackLimit}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    NumberFormat('#,###', Localizations.localeOf(context).toString()).format(member.capitalResourcesLooted),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: CachedNetworkImage(
                      imageUrl: 'https://assets.clashk.ing/icons/Icon_HV_Raid_Attack.png',
                    ),
                  ),
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: CachedNetworkImage(
                      imageUrl: 'https://assets.clashk.ing/icons/Icon_CC_Resource_Capital_Gold_small.png',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget buildHistory(locale) {
    return Center(
    child: Text(
      AppLocalizations.of(context)!.comingSoon,
      style: TextStyle(
        fontSize: 16,
      ),
    ),
  );
    
    //Card(
    //  margin: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
    //  elevation: 4,
    //  child: Padding(
    //    padding: EdgeInsets.only(bottom: 16, top: 8, left: 8, right: 8),
    //    child: Column(
    //      children: [
    //        Align(
    //          alignment: Alignment.center,
    //          child: RichText(
    //            text: TextSpan(
    //              children: [
    //                TextSpan(
    //                  text: AppLocalizations.of(context)!.activeSuperTroops,
    //                  style: Theme.of(context).textTheme.titleMedium,
    //                ),
    //              ],
    //            ),
    //          ),
    //        ),
    //        SizedBox(height: 10),
    //        Row(
    //          mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //          children: [
    //            Row(
    //              mainAxisAlignment: MainAxisAlignment.start,
    //              children: [
    //                SizedBox(width: 16),
    //                IconButton(
    //                  icon: Icon(
    //                    Icons.filter_list,
    //                    color: Theme.of(context)
    //                        .colorScheme
    //                        .onSurface,
    //                    size: 24,
    //                  ),
    //                  onPressed: () {},
    //                ),
    //              ],
    //            ),
    //            Row(
    //              mainAxisAlignment: MainAxisAlignment.end,
    //              children: [
    //                SizedBox(
    //                  width: 30,
    //                  height: 30,
    //                  child: IconButton(
    //                    icon: Icon(Icons.arrow_back,
    //                        color: Theme.of(context)
    //                            .colorScheme
    //                            .onSurface,
    //                        size: 16),
    //                    onPressed: decrementWeek,
    //                  ),
    //                ),
    //                Text(
    //                    DateFormat(
    //                            'dd MMMM yyyy',
    //                            Localizations.localeOf(context)
    //                                .languageCode)
    //                        .format(selectedWeek),
    //                    style: Theme.of(context)
    //                        .textTheme
    //                        .labelLarge),
    //                SizedBox(
    //                  width: 30,
    //                  height: 30,
    //                  child: IconButton(
    //                    icon: Icon(Icons.arrow_forward,
    //                        color: Theme.of(context)
    //                            .colorScheme
    //                            .onSurface,
    //                        size: 16),
    //                    onPressed: incrementWeek,
    //                  ),
    //                ),
    //                SizedBox(width: 16)
    //              ],
    //            ),
    //          ],
    //        ),
    //      ],
    //    ),
    //  ),
    //);
  }

}
