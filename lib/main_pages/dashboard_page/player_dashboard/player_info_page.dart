import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/classes/profile/profile_info.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/classes/data/troops_data_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/main_pages/dashboard_page/player_dashboard/components/player_info_header_card.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_info_clan/clan_info_page.dart';
import 'package:clashkingapp/classes/clan/clan_info.dart';
import 'package:clashkingapp/main_pages/dashboard_page/legend_dashboard/player_legend_page.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class StatsScreen extends StatefulWidget {
  final ProfileInfo playerStats;
  final List<String> discordUser;

  StatsScreen(
      {super.key, required this.playerStats, required this.discordUser});

  @override
  StatsScreenState createState() => StatsScreenState();
}

class StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  String backgroundImageUrl =
      "https://assets.clashk.ing/landscape/home-landscape.png";
  String townHallImageUrl = "";
  List<Widget> stars = [];
  Widget hallChips = SizedBox.shrink();
  List<String> activeEquipmentNames = [];
  Future<void>? _initializeProfileFuture;
  Future<void>? _initializeLegendsFuture;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    townHallImageUrl = widget.playerStats.townHallPic;
    _initializeProfileFuture = _checkInitialization();
    _initializeLegendsFuture = _checkLegendsInitialization();
  }

  Future<void> _checkInitialization() async {
    while (!widget.playerStats.initialized) {
      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  Future<void> _checkLegendsInitialization() async {
    while (!widget.playerStats.legendsInitialized) {
      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    stars = _buildStars(widget.playerStats.townHallWeaponLevel);
    hallChips = buildTownHallChips();
  }

  Future<void> _refreshData() async {
    // Fetch the updated profile information
    final profileInfo =
        await ProfileInfoService().fetchProfileInfo(widget.playerStats.tag);

    setState(() {
      // Update the player stats with the newly fetched data
      widget.playerStats.updateFrom(profileInfo!);
      _initializeProfileFuture = _checkInitialization();
      _initializeLegendsFuture = _checkLegendsInitialization();
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeProfileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox.shrink();
        } else if (snapshot.hasError) {
          Sentry.captureException(snapshot.error);
          return Center(
            child: Text(
              'Error loading user data. Check your internet connection.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        } else {
          return Scaffold(
            body: RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    PlayerInfoHeaderCard(
                      playerStats: widget.playerStats,
                      backgroundImageUrl: backgroundImageUrl,
                      townHallImageUrl: townHallImageUrl,
                      stars: stars,
                      hallChips: hallChips,
                      user: widget.discordUser,
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
                      onTap: (value) {
                        setState(() {
                          backgroundImageUrl = value == 0
                              ? "https://assets.clashk.ing/landscape/home-landscape.png"
                              : "https://assets.clashk.ing/landscape/builder-landscape.png";
                          townHallImageUrl = value == 0
                              ? widget.playerStats.townHallPic
                              : widget.playerStats.builderHallPic;
                          stars = value == 0
                              ? _buildStars(
                                  widget.playerStats.townHallWeaponLevel)
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 10),
                            if (widget.playerStats.getActiveTroops().isNotEmpty)
                              buildSuperTroopsSection(
                                  widget.playerStats.getActiveTroops(),
                                  'super-troop'),
                            buildItemSection(
                                widget.playerStats.heroes,
                                'hero',
                                AppLocalizations.of(context)?.heroes ??
                                    'Heroes'),
                            buildItemSection(
                                widget.playerStats.equipments,
                                'gear',
                                AppLocalizations.of(context)?.equipment ??
                                    'Gears'),
                            buildItemSection(
                                widget.playerStats.troops,
                                'troop',
                                AppLocalizations.of(context)?.troops ??
                                    'Troops'),
                            buildItemSection(
                                widget.playerStats.troops,
                                'super-troop',
                                AppLocalizations.of(context)?.superTroops ??
                                    "Super Troops"),
                            buildItemSection(widget.playerStats.troops, 'pet',
                                AppLocalizations.of(context)?.pets ?? 'Pets'),
                            buildItemSection(
                                widget.playerStats.troops,
                                'siege-machine',
                                AppLocalizations.of(context)?.siegeMachines ??
                                    'Siege Machine'),
                            buildItemSection(
                                widget.playerStats.spells,
                                'spell',
                                AppLocalizations.of(context)?.spells ??
                                    'Spells'),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 10),
                            buildItemSection(
                                widget.playerStats.heroes,
                                'bb-hero',
                                AppLocalizations.of(context)?.heroes ??
                                    'Heroes'),
                            buildItemSection(
                                widget.playerStats.troops,
                                'bb-troop',
                                AppLocalizations.of(context)?.troops ??
                                    'Troops'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }

  List<Widget> _buildStars(int count) {
    return List<Widget>.generate(
      count,
      (index) => CachedNetworkImage(
        imageUrl: 'https://assets.clashk.ing/icons/Icon_BB_Star.png',
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
    return TroopDataManager().getTroopInfo(equipmentName)['url'] ??
        'https://assets.clashk.ing/clashkinglogo.png';
  }

  // Build the section for troops, super troops, pets, and siege machines
  Widget buildItemSection(List<dynamic> items, String itemType, String title) {
    List<String> itemNames = items.map((item) => item.name as String).toList();

    double completionPercentage =
        calculateCompletionPercentage(items, itemType);

    List<Widget> missingItems = [];
    TroopDataManager().troopUrlsAndTypes.forEach((name, data) {
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
              child: CachedNetworkImage(
                  imageUrl: data['url'] ??
                      "https://assets.clashk.ing/clashkinglogo.png",
                  height: 40,
                  width: 40,
                  fit: BoxFit.cover),
            ),
          ),
        );
      }
    });

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
                      text: title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (itemType != 'super-troop') ...[
                      TextSpan(
                        text: ' | ',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextSpan(
                        text: completionPercentage % 1 == 0
                            ? '${completionPercentage.toInt()}%'
                            : '${completionPercentage.toStringAsFixed(2)}%',
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
                                ? (item.rarity == '2'
                                    ? Colors.purple
                                    : Colors.blue)
                                : null,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: (item.level == item.maxLevel ||
                                      (item.type == 'super-troop' &&
                                          item.superTroopIsActive))
                                  ? Color(0xFFD4AF37)
                                  : Theme.of(context).colorScheme.onSurface,
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
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        elevation: 6,
                                        backgroundColor: Colors.transparent,
                                        child: SingleChildScrollView(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .scaffoldBackgroundColor,
                                              shape: BoxShape.rectangle,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Column(
                                                children: <Widget>[
                                                  CachedNetworkImage(
                                                      imageUrl: item.imageUrl,
                                                      width: 80,
                                                      height: 80,
                                                      fit: BoxFit.cover),
                                                  Text(
                                                    '${item.name}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleSmall
                                                        ?.copyWith(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .onSurface),
                                                  ),
                                                  Text(
                                                    itemType == 'super-troop'
                                                        ? (item.superTroopIsActive
                                                            ? 'Actif'
                                                            : 'Inactif')
                                                        : 'Level : ${item.level}/${item.maxLevel}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .onSurface),
                                                  ),
                                                  itemType == 'hero'
                                                      ? Column(
                                                          children: [
                                                            ...item.equipment
                                                                .map(
                                                              (equipment) =>
                                                                  Padding(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    vertical:
                                                                        4.0),
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    CachedNetworkImage(
                                                                      imageUrl:
                                                                          getEquipmentImageUrl(
                                                                              equipment.name),
                                                                      width: 40,
                                                                      height:
                                                                          40,
                                                                      fit: BoxFit
                                                                          .cover,
                                                                    ),
                                                                    SizedBox(
                                                                        width:
                                                                            8),
                                                                    Expanded(
                                                                      child:
                                                                          Text(
                                                                        equipment
                                                                            .name,
                                                                        style: TextStyle(
                                                                            color:
                                                                                Theme.of(context).colorScheme.onSurface),
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      'Level : ${equipment.level}/${equipment.maxLevel}',
                                                                      style: TextStyle(
                                                                          color: Theme.of(context)
                                                                              .colorScheme
                                                                              .onSurface),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        )
                                                      : SizedBox.shrink(),
                                                  SizedBox(height: 8),
                                                  Text(
                                                      "More data coming soon!"),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: CachedNetworkImage(
                                      imageUrl: item.imageUrl,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover),
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
                                              ? Colors.transparent
                                              : Colors.black,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Stack(
                                          children: [
                                            item.level == item.maxLevel
                                                ? Shimmer.fromColors(
                                                    baseColor:
                                                        Color(0xFFD4AF37),
                                                    highlightColor:
                                                        Color(0xFFD4AF37)
                                                            .withOpacity(0.7),
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Color(0xFFD4AF37),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4),
                                                      ),
                                                    ),
                                                  )
                                                : SizedBox(), // Empty widget for non-max level
                                            Align(
                                              alignment: Alignment.center,
                                              child: Text(
                                                item.level.toString(),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
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
        ),
      ),
    );
  }

  Widget buildSuperTroopsSection(List<dynamic> items, String itemType) {
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
            Center(
              child: Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  ...items.where((item) => item.type == itemType).map(
                        (item) => Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.onSurface,
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
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        elevation: 6,
                                        backgroundColor: Colors.transparent,
                                        child: SingleChildScrollView(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .scaffoldBackgroundColor,
                                              shape: BoxShape.rectangle,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Column(
                                                children: <Widget>[
                                                  CachedNetworkImage(
                                                      imageUrl: item.imageUrl,
                                                      width: 80,
                                                      height: 80,
                                                      fit: BoxFit.cover),
                                                  Text(
                                                    '${item.name}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleSmall
                                                        ?.copyWith(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .onSurface),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                      "More data coming soon!"),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: CachedNetworkImage(
                                      imageUrl: item.imageUrl,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
      if (widget.playerStats.clan != null)
        GestureDetector(
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
            Clan? clanInfo = await ClanService()
                .fetchClanAndWarInfo(widget.playerStats.clan!.tag);
            if (mounted) {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClanInfoScreen(
                      clanInfo: clanInfo, discordUser: widget.discordUser),
                ),
              );
            }
          },
          child: Chip(
            avatar: CircleAvatar(
              backgroundColor: Colors.transparent,
              child: CachedNetworkImage(
                imageUrl: widget.playerStats.clan!.badgeUrls.small,
              ),
            ),
            labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
            label: Shimmer.fromColors(
              period: Duration(seconds: 3),
              baseColor: Theme.of(context)
                  .colorScheme
                  .onSurface, // Replace with your base color
              highlightColor: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.3), // Replace with your highlight color
              child: Text(
                widget.playerStats.clan!.name,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
        ),
      Chip(
        avatar: CircleAvatar(
          backgroundColor: Colors.transparent,
          child: CachedNetworkImage(
              imageUrl:
                  "https://assets.clashk.ing/home-base/hero-pics/Icon_HV_Hero_Archer_Queen.png"),
        ),
        labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
        label: Text(
          getRoleText(widget.playerStats.role),
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      Chip(
        avatar: CircleAvatar(
          backgroundColor: Colors.transparent,
          child: CachedNetworkImage(imageUrl: widget.playerStats.townHallPic),
        ),
        labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
        label: Text(
          "${AppLocalizations.of(context)?.th ?? 'TH'}${widget.playerStats.townHallLevel}",
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      Chip(
        avatar: CircleAvatar(
          backgroundColor: Colors.transparent,
          child: CachedNetworkImage(
              imageUrl:
                  "https://assets.clashk.ing/icons/Icon_HV_XP.png"),
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
          backgroundColor: Colors.transparent,
          child: CachedNetworkImage(
              imageUrl:
                  "https://assets.clashk.ing/icons/Icon_HV_Attack_Star.png"),
        ),
        labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
        label: Text(
          '${widget.playerStats.warStars}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      Chip(
        avatar: CircleAvatar(
          backgroundColor: Colors.transparent,
          child: CachedNetworkImage(
              imageUrl:
                  "https://assets.clashk.ing/icons/Icon_CC_Resource_Capital_Gold_small.png"),
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
                  ? CachedNetworkImage(
                      imageUrl:
                          "https://assets.clashk.ing/icons/Icon_HV_In.png")
                  : CachedNetworkImage(
                      imageUrl:
                          'https://assets.clashk.ing/icons/Icon_HV_Out.png')),
          label: Text(
            widget.playerStats.warPreference == 'in'
                ? AppLocalizations.of(context)?.ready ?? 'Ready'
                : AppLocalizations.of(context)?.unready ?? 'Unready',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Chip(
          avatar: CircleAvatar(
            backgroundColor: Colors.transparent,
            child: CachedNetworkImage(
                imageUrl:
                    "https://assets.clashk.ing/icons/Icon_HV_Sword.png"),
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
            child: CachedNetworkImage(
                imageUrl:
                    "https://assets.clashk.ing/icons/Icon_HV_Shield.png"),
          ),
          labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
          label: Text(
            widget.playerStats.defenseWins.toString(),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        FutureBuilder<void>(
          future: _initializeLegendsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox.shrink();
            } else if (snapshot.hasError) {
              Sentry.captureException(snapshot.error);
              return Center(
                child: Text(
                  'Error loading user data. Check your internet connection.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              );
            } else {
              if (widget.playerStats.playerLegendData != null &&
                  widget.playerStats.playerLegendData!.legendData.isNotEmpty) {
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
                    navigator.pop();
                    if (widget.playerStats.playerLegendData != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LegendScreen(
                            playerStats: widget.playerStats,
                            playerLegendData:
                                widget.playerStats.playerLegendData!,
                          ),
                        ),
                      );
                    }
                  },
                  child: Chip(
                    avatar: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      child: CachedNetworkImage(
                          imageUrl: widget.playerStats.leagueUrl),
                    ),
                    labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
                    label: Shimmer.fromColors(
                      period: Duration(seconds: 3),
                      baseColor: Theme.of(context)
                          .colorScheme
                          .onSurface, // Replace with your base color
                      highlightColor: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(
                              0.3), // Replace with your highlight color
                      child: Text(
                        widget.playerStats.trophies.toString(),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ),
                );
              } else {
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    child: CachedNetworkImage(
                        imageUrl: widget.playerStats.leagueUrl),
                  ),
                  label: Text(
                    widget.playerStats.trophies.toString(),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                );
              }
            }
          },
        ),
        Chip(
          avatar: CircleAvatar(
            backgroundColor: Colors.transparent,
            child: CachedNetworkImage(
                imageUrl:
                    "https://assets.clashk.ing/icons/Icon_HV_Trophy_Best.png"),
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
            backgroundColor: Colors.transparent,
            child:
                CachedNetworkImage(imageUrl: widget.playerStats.builderHallPic),
          ),
          labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
          label: Text(
            "${AppLocalizations.of(context)?.bh ?? 'BH'}${widget.playerStats.builderHallLevel}",
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Chip(
          avatar: CircleAvatar(
            backgroundColor: Colors.transparent,
            child: CachedNetworkImage(
                imageUrl:
                    "https://assets.clashk.ing/icons/Icon_HV_Trophy.png"),
          ),
          labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
          label: Text(
            widget.playerStats.builderBaseTrophies.toString(),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Chip(
          avatar: CircleAvatar(
            backgroundColor: Colors.transparent,
            child: CachedNetworkImage(
                imageUrl:
                    "https://assets.clashk.ing/icons/Icon_HV_Trophy_Best.png"),
          ),
          labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
          label: Text(
            widget.playerStats.bestBuilderBaseTrophies.toString(),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ],
    );
  }
}
