import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:clashkingapp/api/player_account_info.dart';
import 'package:clipboard/clipboard.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/data/troop_data.dart';
import 'achievement_page.dart';

class StatsScreen extends StatefulWidget {
  final PlayerAccountInfo playerStats;

  StatsScreen({super.key, required this.playerStats});

  @override
  StatsScreenState createState() => StatsScreenState();
}

class StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  String backgroundImageUrl =
      "https://clashkingfiles.b-cdn.net/landscape/home-landscape.png";
  String townHallImageUrl = "";
  List<Widget> stars = [];
  Widget hallChips = SizedBox.shrink();
  List<String> activeEquipmentNames = [];

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    townHallImageUrl = widget.playerStats.townHallPic;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    stars = _buildStars(widget.playerStats.townHallWeaponLevel);
    hallChips = buildTownHallChips();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
                color: Theme.of(context).colorScheme.surface,
                child: Column(children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: <Widget>[
                      SizedBox(
                        height: 190,
                        width: double.infinity,
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                          child: ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                Colors.black.withOpacity(
                                    0.3), // Adjust opacity as needed
                                BlendMode.darken,
                              ),
                              child: Image.network(
                                backgroundImageUrl,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )),
                        ),
                      ),
                      Positioned(
                        bottom: -90,
                        child: Column(children: [
                          GestureDetector(
                            onDoubleTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => AchievementScreen(playerStats: widget.playerStats)),
                              );
                            },
                            child: Image.network(townHallImageUrl, width: 170),
                          ),
                          Row(
                            children: [
                              stars.isNotEmpty
                                  ? Row(
                                      children: stars,
                                    )
                                  : SizedBox(height: 22)
                            ],
                          ),
                        ]),
                      ),
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
                  SizedBox(height: 90),
                  ListTile(
                    title: Center(
                      child: Text(
                        widget.playerStats.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    subtitle: Center(
                      child: InkWell(
                        onTap: () {
                          FlutterClipboard.copy(widget.playerStats.tag)
                              .then((value) {
                            final snackBar = SnackBar(
                              content: Text(AppLocalizations.of(context)!
                                  .copiedToClipboard),
                            );
                            ScaffoldMessenger.of(context)
                                .showSnackBar(snackBar);
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(8.0), // Add padding if needed
                          child: Text(widget.playerStats.tag, style: TextStyle(color : Theme.of(context).colorScheme.tertiary)),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                    child: hallChips,
                  ),
                ])),
            ScrollableTab(
              labelColor: Theme.of(context).colorScheme.onBackground,
              tabBarDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
              unselectedLabelColor: Theme.of(context).colorScheme.onBackground,
              onTap: (value) {
                setState(() {
                  backgroundImageUrl = value == 0
                      ? "https://clashkingfiles.b-cdn.net/landscape/home-landscape.png"
                      : "https://clashkingfiles.b-cdn.net/landscape/builder-landscape.png";
                  townHallImageUrl = value == 0
                      ? widget.playerStats.townHallPic
                      : widget.playerStats.builderHallPic;
                  stars = value == 0
                      ? _buildStars(widget.playerStats.townHallWeaponLevel)
                      : _buildStars(0);
                  hallChips = value == 0
                      ? buildTownHallChips()
                      : buildBuilderHallChips();
                });
              },
              tabs: [
                Tab(text: AppLocalizations.of(context)!.homeBase),
                Tab(text: AppLocalizations.of(context)!.builderBase),
              ],
              children: [
                ListTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10),
                      buildItemSection(
                          widget.playerStats.heroes,
                          'hero',
                          AppLocalizations.of(context)?.heroes ?? 'Heroes'),
                      buildItemSection(
                          widget.playerStats.equipments,
                          'gear',
                          AppLocalizations.of(context)?.equipment ?? 'Gears'),
                      buildItemSection(
                          widget.playerStats.troops,
                          'troop',
                          AppLocalizations.of(context)?.troops ?? 'Troops'),
                      buildItemSection(
                          widget.playerStats.troops,
                          'super-troop',
                          AppLocalizations.of(context)?.superTroops ??'Super Troops'),
                      buildItemSection(
                          widget.playerStats.troops,
                          'pet',
                          AppLocalizations.of(context)?.pets ?? 'Pets'),
                      buildItemSection(
                          widget.playerStats.troops,
                          'siege-machine',
                          AppLocalizations.of(context)?.siegeMachines ?? 'Siege Machine'),
                      buildItemSection(
                          widget.playerStats.spells,
                          'spell',
                          AppLocalizations.of(context)?.spells ?? 'Spells'),
                    ],
                  ),
                ),

                // Builder Base
                ListTile(
                  title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10),
                        buildItemSection(
                            widget.playerStats.heroes,
                            'bb-hero',
                            AppLocalizations.of(context)?.heroes ?? 'Heroes'),
                        buildItemSection(
                            widget.playerStats.troops,
                            'bb-troop',
                            AppLocalizations.of(context)?.troops ?? 'Troops'),
                      ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStars(int count) {
    return List<Widget>.generate(
      count,
      (index) => Image.network(
        'https://clashkingfiles.b-cdn.net/icons/Icon_BB_Star.png',
        width: 22.0,
        height: 22.0,
      ),
    );
  }

  double calculateCompletionPercentage(List<dynamic> items, String itemType) {
    var filteredItems = items.where((item) => item.type == itemType).toList();

    int totalMaxLevel =
        filteredItems.fold(0, (prev, item) => (prev) + (item.maxLevel as int));
    int totalCurrentLevel =
        filteredItems.fold(0, (prev, item) => (prev) + (item.level as int));

    if (totalMaxLevel == 0) return 0.0;

    return (totalCurrentLevel / totalMaxLevel) * 100;
  }

  String getEquipmentImageUrl(String equipmentName) {
  return troopUrlsAndTypes[equipmentName]?['url'] ??
      'https://clashkingfiles.b-cdn.net/clashkinglogo.png';
  }

  // Build the section for troops, super troops, pets, and siege machines
  Widget buildItemSection(List<dynamic> items, String itemType, String title) {
    List<String> itemNames = items.map((item) => item.name as String).toList();

    double completionPercentage = calculateCompletionPercentage(items, itemType);

    List<Widget> missingItems = [];
    troopUrlsAndTypes.forEach((name, data) {
      if (!itemNames.contains(name) && data['type'] == itemType) {
        missingItems.add(
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey,
                width: 2,
              ),
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            clipBehavior: Clip.antiAlias,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(Colors.grey, BlendMode.saturation),
              child: Image.network(
                  data['url'] ??
                      "https://clashkingfiles.b-cdn.net/clashkinglogo.png",
                  height: 40,
                  width: 40,
                  fit: BoxFit.cover),
            ),
          ),
        );
      }
    });

    return Card(
        margin: EdgeInsets.only(bottom: 30),
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
                          text: title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (itemType != 'super-troop') ...[
                          TextSpan(
                            text: ' | ',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          TextSpan(
                            text:
                                '${completionPercentage.toStringAsFixed(2)}%',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Center(
                  child: Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: [
                      ...items.where((item) => item.type == itemType).map(
                            (item) => Container(
                              decoration: BoxDecoration(
                                color: item.type == 'gear'
                                    ? (item.name == 'Frozen Arrow' ||
                                            item.name == 'Giant Gauntlet' ||
                                            item.name == 'Fireball'
                                        ? Colors.purple
                                        : Colors.blue)
                                    : null,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                    (item.level == item.maxLevel ||
                                            (item.type == 'super-troop' &&
                                                item.superTroopIsActive))
                                        ? Color(0xFFD4AF37) // Or
                                        : Theme.of(context)
                                            .colorScheme
                                            .onBackground, // Noir
                                  width: 2,
                                ),
                              ),
                              child: Stack(
                                children: <Widget>[
                                  GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return Dialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            elevation: 6,
                                            backgroundColor: Colors.transparent,
                                            child: SingleChildScrollView(
                                              child:Container(
                                                height: 200,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.rectangle,
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Column(
                                                  children: <Widget>[
                                                    Text('${item.name}', style: TextStyle(color: Colors.black)),
                                                    Image.network(item.imageUrl,
                                                      width: 40,
                                                      height: 40,
                                                      fit: BoxFit.cover),
                                                    Text(
                                                      itemType == 'super-troop'
                                                        ? (item.superTroopIsActive ? 'Actif' : 'Inactif')
                                                        : 'Level : ${item.level}/${item.maxLevel}',
                                                      style: TextStyle(color: Colors.black),
                                                    ),
                                                    itemType == 'hero'
                                                      ? Container(
                                                          child: Column(
                                                            children: [
                                                              ...item.equipment.map((equipment) => Padding(
                                                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                                    child: Row(
                                                                      mainAxisSize: MainAxisSize.min,
                                                                      children: [
                                                                        Image.network(
                                                                          getEquipmentImageUrl(equipment.name),
                                                                          width: 40,
                                                                          height: 40,
                                                                          fit: BoxFit.cover,
                                                                        ),
                                                                        SizedBox(width: 8),
                                                                        Expanded(
                                                                          child: Text(
                                                                            equipment.name,
                                                                            style: TextStyle(color: Colors.black),
                                                                            overflow: TextOverflow.ellipsis,
                                                                          ),
                                                                        ),
                                                                        Text(
                                                                          'Level : ${equipment.level}/${equipment.maxLevel}',
                                                                          style: TextStyle(color: Colors.black),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                              ),
                                                            ],
                                                          ),
                                                        )
                                                      : SizedBox.shrink(),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(item.imageUrl,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover), // Display the item image
                                    ),
                                  ),
                                  (item.type != 'super-troop')
                                      ? Positioned(
                                          right: 1,
                                          bottom: 1,
                                          child: Container(
                                            height: 16,
                                            width: 16,
                                            padding: EdgeInsets.all(1),
                                            decoration: BoxDecoration(
                                              color: item.level == item.maxLevel
                                                  ? Color(0xFFD4AF37) // Or
                                                  : Colors.black, // Noir
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment
                                                  .center,
                                              children: [
                                                Text(
                                                  item.level.toString(),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      : SizedBox.shrink()
                                ],
                              ),
                            ),
                          ),
                      ...missingItems,
                    ],
                  ),
                ),
              ],
            )));
  }

  List<Widget> buildAllHallChips() {
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
    }

    return [
      Chip(
        avatar: CircleAvatar(
          backgroundColor:
              Colors.transparent, // Set to a suitable color for your design.
          child: Image.network(widget.playerStats.clan.badgeUrls.small),
        ),
        labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
        label: Text(
          widget.playerStats.clan.name,
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      Chip(
        avatar: CircleAvatar(
          backgroundColor:
              Colors.transparent, // Set to a suitable color for your design.
          child: Image.network(
              "https://clashkingfiles.b-cdn.net/home-base/hero-pics/Icon_HV_Hero_Archer_Queen.png"),
        ),
        labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
        label: Text(
          getRoleText(widget.playerStats.role),
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      Chip(
        avatar: CircleAvatar(
          backgroundColor:
              Colors.transparent, // Set to a suitable color for your design.
          child: Image.network(widget.playerStats.townHallPic),
        ),
        labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
        label: Text(
          "${AppLocalizations.of(context)?.th ?? 'TH'}${widget.playerStats.townHallLevel}",
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      Chip(
        avatar: CircleAvatar(
          backgroundColor:
              Colors.transparent, // Set to a suitable color for your design.
          child: Image.network(
              "https://clashkingfiles.b-cdn.net/icons/Icon_HV_XP.png"),
        ),
        labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
        label: Text(
          '${widget.playerStats.expLevel}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      Chip(
        avatar: Icon(LucideIcons.chevronUp,
            color: Color.fromARGB(255, 27, 114, 33)),
        labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
        label: Text(
          '${widget.playerStats.donations}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      Chip(
        avatar: Icon(LucideIcons.chevronDown,
            color: Color.fromARGB(255, 155, 4, 4)),
        labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
        label: Text(
          '${widget.playerStats.donationsReceived}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      Chip(
        avatar: Icon(LucideIcons.chevronsUpDown,
            color: Color.fromARGB(255, 0, 136, 255)),
        labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
        label: Text(
          (widget.playerStats.donations /
                  (widget.playerStats.donationsReceived == 0
                      ? 1
                      : widget.playerStats.donationsReceived))
              .toStringAsFixed(2),
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      Chip(
        avatar: CircleAvatar(
          backgroundColor:
              Colors.transparent, // Set to a suitable color for your design.
          child: Image.network(
              "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Attack_Star.png"),
        ),
        labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
        label: Text(
          '${widget.playerStats.warStars}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      Chip(
        avatar: CircleAvatar(
          backgroundColor:
              Colors.transparent, // Set to a suitable color for your design.
          child: Image.network(
              "https://clashkingfiles.b-cdn.net/icons/Icon_CC_Resource_Capital_Gold_small.png"),
        ),
        labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
        label: Text(
          NumberFormat('#,###', 'fr_FR')
              .format(widget.playerStats.clanCapitalContributions)
              .replaceAll(',', ' '),
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
    ];
  }

  Widget buildTownHallChips() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8.0,
      runSpacing: 0,
      children: [
        ...buildAllHallChips(),
        Chip(
          avatar: CircleAvatar(
              backgroundColor: Colors.transparent,
              child: widget.playerStats.warPreference == 'in'
                  ? Image.network(
                      "https://clashkingfiles.b-cdn.net/icons/Icon_HV_In.png")
                  : Image.network(
                      'https://clashkingfiles.b-cdn.net/icons/Icon_HV_Out.png')),
          label: Text(
            widget.playerStats.warPreference,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Chip(
          avatar: CircleAvatar(
            backgroundColor: Colors.transparent,
            child: Image.network(
                "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Sword.png"),
          ),
          labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
          label: Text(
            widget.playerStats.attackWins.toString(),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Chip(
          avatar: CircleAvatar(
            backgroundColor: Colors.transparent,
            child: Image.network(
                "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Shield.png"),
          ),
          labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
          label: Text(
            widget.playerStats.defenseWins.toString(),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Chip(
          avatar: CircleAvatar(
            backgroundColor: Colors.transparent,
            child: Image.network(
                "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Trophy.png"),
          ),
          labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
          label: Text(
            widget.playerStats.trophies.toString(),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Chip(
          avatar: CircleAvatar(
            backgroundColor: Colors.transparent,
            child: Image.network(
                "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Trophy_Best.png"),
          ),
          labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
          label: Text(
            widget.playerStats.bestTrophies.toString(),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ],
    );
  }

  Widget buildBuilderHallChips() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8.0,
      runSpacing: 0,
      children: [
        ...buildAllHallChips(),
        Chip(
          avatar: CircleAvatar(
            backgroundColor:
                Colors.transparent, // Set to a suitable color for your design.
            child: Image.network(widget.playerStats.builderHallPic),
          ),
          labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
          label: Text(
            "${AppLocalizations.of(context)?.bh ?? 'BH'}${widget.playerStats.builderHallLevel}",
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Chip(
          avatar: CircleAvatar(
            backgroundColor:
                Colors.transparent, // Set to a suitable color for your design.
            child: Image.network(
                "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Trophy.png"),
          ),
          labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
          label: Text(
            widget.playerStats.builderBaseTrophies.toString(),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Chip(
          avatar: CircleAvatar(
            backgroundColor:
                Colors.transparent, // Set to a suitable color for your design.
            child: Image.network(
                "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Trophy_Best.png"),
          ),
          labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
          label: Text(
            widget.playerStats.bestBuilderBaseTrophies.toString(),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ],
    );
    // Other chips...
  }
}
