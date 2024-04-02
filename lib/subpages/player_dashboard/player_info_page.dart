import 'package:flutter/material.dart';
import 'package:clashkingapp/api/player_account_info.dart';
import 'dart:ui';
import 'package:clipboard/clipboard.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/data/troop_data.dart';

class StatsScreen extends StatefulWidget {
  final PlayerAccountInfo playerStats;

  StatsScreen({Key? key, required this.playerStats}) : super(key: key);

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
                          Colors.black
                              .withOpacity(0.3), // Adjust opacity as needed
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
                    Image.network(townHallImageUrl, width: 170),
                    Row(
                      children: [
                        stars.length > 0
                            ? Row(
                                children: stars,
                              )
                            : SizedBox(height: 22)
                      ],
                    ),
                  ]),
                ),
                Positioned(
                  top: 20,
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
                    FlutterClipboard.copy(widget.playerStats.tag).then((value) {
                      final snackBar = SnackBar(
                        content: Text(
                            '${AppLocalizations.of(context)!.copiedToClipboard}'),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(8.0), // Add padding if needed
                    child: Text(widget.playerStats.tag),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0),
              child: hallChips,
            ),
            ScrollableTab(
              labelColor: Colors.black,
              onTap: (value) {
                print('Tab $value selected');
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
                Container(
                  color: Theme.of(context).colorScheme.tertiary,
                  child: ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10),
                        buildItemSection(
                            widget.playerStats.heroes, 'hero', 'Heroes'),
                        buildItemSection(
                            widget.playerStats.troops, 'troop', 'Troops'),
                        buildItemSection(widget.playerStats.troops,
                            'super-troop', 'Super Troops'),
                        buildItemSection(
                            widget.playerStats.troops, 'pet', 'Pets'),
                        buildItemSection(widget.playerStats.troops,
                            'siege-machine', 'Machine Siege'),
                        buildItemSection(
                            widget.playerStats.spells, 'spell', 'Spells')
                      ],
                    ),
                  ),
                ),

                // Builder Base
                Container(
                  color: Theme.of(context).colorScheme.tertiary,
                  child: ListTile(
                    title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10),
                          buildItemSection(
                              widget.playerStats.heroes, 'bb-hero', 'Heroes'),
                          buildItemSection(
                              widget.playerStats.troops, 'bb-troop', 'Troops'),
                        ]),
                  ),
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

// Build the section for troops, super troops, pets, and siege machines
  Widget buildItemSection(List<dynamic> items, String itemType, String title) {
    List<String> itemNames = items.map((item) => item.name as String).toList();

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
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                SizedBox(height: 10),
                Center(
                  child: Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: [
                      ...items
                          .where((item) => item.type == itemType)
                          .map(
                            (item) => Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: item.level == item.maxLevel
                                      ? Color(0xFFD4AF37) // Or
                                      : Colors.black, // Noir
                                  width: 2,
                                ),
                              ),
                              child: Stack(
                                children: <Widget>[
                                  Image.network(item.imageUrl,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit
                                          .cover), // Display the item image
                                  (item.level != 1)
                                      ? Positioned(
                                          right: 1,
                                          bottom: 1,
                                          child: Container(
                                            padding: EdgeInsets.all(1),
                                            decoration: BoxDecoration(
                                              color: item.level == item.maxLevel
                                                  ? Color(0xFFD4AF37) // Or
                                                  : Colors.black, // Noir
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              item.level.toString(),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        )
                                      : SizedBox.shrink()
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      ...missingItems,
                    ],
                  ),
                ),
              ],
            )));
  }

  List<Widget> buildAllHallChips() {
    return [
      Chip(
        avatar: CircleAvatar(
          backgroundColor:
              Colors.transparent, // Set to a suitable color for your design.
          child: Image.network(
              "https://clashkingfiles.b-cdn.net/icons/Clan_Badge_Border_2.png"),
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
          widget.playerStats.role,
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
          "TH${widget.playerStats.townHallLevel}",
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
          '${(widget.playerStats.donations / (widget.playerStats.donationsReceived == 0 ? 1 : widget.playerStats.donationsReceived)).toStringAsFixed(2)}',
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
          widget.playerStats.clanCapitalContributions.toString(),
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
            backgroundColor:
                Colors.transparent, // Set to a suitable color for your design.
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
            backgroundColor:
                Colors.transparent, // Set to a suitable color for your design.
            child: Image.network(
                "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Trophy_Best.png"),
          ),
          labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
          label: Text(
            widget.playerStats.bestTrophies.toString(),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Chip(
          avatar: CircleAvatar(
            backgroundColor:
                Colors.transparent, // Set to a suitable color for your design.
            child: Image.network(
                "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Attacks_No_Shield.png"),
          ),
          labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
          label: Text(
            widget.playerStats.attackWins.toString(),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Chip(
          avatar: CircleAvatar(
            backgroundColor:
                Colors.transparent, // Set to a suitable color for your design.
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
            backgroundColor:
                Colors.transparent, // Set to a suitable color for your design.
            child: widget.playerStats.warPreference == 'in'
                ? Image.network(
                    "https://clashkingfiles.b-cdn.net/icons/Icon_HV_In.png")
                : Image.network(
                    'https://clashkingfiles.b-cdn.net/icons/Icon_HV_Out.png'),
          ),
          labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
          label: Text(
            widget.playerStats.warPreference.toString(),
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
            "BH ${widget.playerStats.builderHallLevel}",
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
