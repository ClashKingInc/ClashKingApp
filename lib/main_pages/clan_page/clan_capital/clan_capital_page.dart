import 'package:clashkingapp/classes/clan/capital/raids_history.dart';
import 'package:flutter/material.dart';
//import 'package:lucide_icons/lucide_icons.dart';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/classes/clan/clan_info.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_capital/components/clan_capital_header.dart';

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

  String townHallImageUrl = "";
  List<Widget> stars = [];
  Widget hallChips = SizedBox.shrink();
  List<String> activeEquipmentNames = [];
 
  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
  }

  Future<void> checkInitialization() async {
    //while (!widget.playerStats.initialized) {
    //  await Future.delayed(Duration(milliseconds: 100));
    //}
  }

  //Future<void> _checkLegendsInitialization() async {
  //  //while (!widget.playerStats.legendsInitialized) {
  //  //  await Future.delayed(Duration(milliseconds: 100));
  //  //}
  //}

  //@override
  //void didChangeDependencies() {
  //  //super.didChangeDependencies();
  //  //stars = _buildStars(widget.playerStats.townHallWeaponLevel);
  //  //hallChips = buildTownHallChips();
  //}

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
    if (widget.clanInfo?.clanCapitalRaid != null && widget.clanInfo!.clanCapitalRaid.items.isNotEmpty) {
      var firstRaid = widget.clanInfo!.clanCapitalRaid.items.first;
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
                        SizedBox(height: 10),
                        buildLastRaids(firstRaid),
                        buildLastRaidsMembers(firstRaid),
                        SizedBox(height: 10),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10),
                        buildHistory(),
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

  Widget buildLastRaids(firstRaid) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Card(
            margin: EdgeInsets.only(left: 12, right: 12, bottom: 4, top: 4),
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: firstRaid.state == 'ongoing' 
                              ? 'Raids en cours' 
                              : 'Dernier raids',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text("Start Time: ${firstRaid.startTime}"),
                  Text("End Time: ${firstRaid.endTime}"),
                  Text("Total Loot: ${firstRaid.capitalTotalLoot}"),
                  Text("Raids Completed: ${firstRaid.raidsCompleted}"),
                  Text("Total Attacks: ${firstRaid.totalAttacks}"),
                  Text("Enemy Districts Destroyed: ${firstRaid.enemyDistrictsDestroyed}"),
                  Text("Offensive Reward: ${firstRaid.offensiveReward}"),
                  Text("Defensive Reward: ${firstRaid.defensiveReward}"),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildLastRaidsMembers(firstRaid) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Card(
            margin: EdgeInsets.only(left: 12, right: 12, bottom: 4, top: 4),
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    "First Raid Info ${firstRaid.members.length}/50",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 10),
                  ...buildMemberWidgets(firstRaid.members),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> buildMemberWidgets(List<RaidMember> raidMembers) {
    raidMembers.sort((a, b) => b.capitalResourcesLooted.compareTo(a.capitalResourcesLooted));
    int townHallLevel = 16;

    return raidMembers.map((member) {
      bool isInDiscord = widget.user.contains(member.tag);

      return Padding(
        padding: EdgeInsets.only(top: 8),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isInDiscord ? Colors.green : Colors.transparent,
                width: 2.0,
              ),
              top: BorderSide.none,
              right: BorderSide.none,
              bottom: BorderSide.none,
            ),
            borderRadius: BorderRadius.circular(10),
            color: Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                height: 40,
                width: 40,
                child: CachedNetworkImage(
                  imageUrl: 'https://assets.clashk.ing/home-base/town-hall-pics/town-hall-$townHallLevel.png',
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
                      style: Theme.of(context).textTheme.bodyMedium,
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
                    '${member.capitalResourcesLooted}',
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

  Widget buildHistory() {
    return Card(
      margin: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.only(bottom: 16, top: 8, left: 8, right: 8),
        child: Column(
          children: [
            Align(
              alignment: Alignment.center,
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: AppLocalizations.of(context)!.activeSuperTroops,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
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

  /*List<Widget> buildAllHallChips() {
    String getRoleText(String role) {
      switch (role) {
        case 'leader':
          return AppLocalizations.of(context)?.leader ?? 'Leader';
        case 'coLeader':
          return AppLocalizations.of(context)?.coLeader ?? 'Co-Leader';
        case 'admin':
          return AppLocalizations.of(context)?.elder ?? 'Elder';
        case 'member':
          return AppLocalizations.of(context)?.member ?? 'Member';
        default:
          return 'No clan';
      }
    }*/

}
