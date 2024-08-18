import 'package:flutter/material.dart';
//import 'package:lucide_icons/lucide_icons.dart';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/classes/clan/clan_info.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_capital/components/clan_capital_header.dart';

class CapitalScreen extends StatefulWidget {
  final Clan? clanInfo;
  final List<String> discordUser;

  CapitalScreen(
      {super.key, required this.clanInfo, required this.discordUser});

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
  Future<void>? _initializeProfileFuture;
 
  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    _initializeProfileFuture = _checkInitialization();
  }

  Future<void> _checkInitialization() async {
    //while (!widget.playerStats.initialized) {
    //  await Future.delayed(Duration(milliseconds: 100));
    //}
  }

  Future<void> _checkLegendsInitialization() async {
    //while (!widget.playerStats.legendsInitialized) {
    //  await Future.delayed(Duration(milliseconds: 100));
    //}
  }

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
      _initializeProfileFuture = _checkInitialization();
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
                    ClanCapitalHeader(
                      user: widget.discordUser,
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
                            
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
      /*if (widget.playerStats.clan != null)
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
          "${AppLocalizations.of(context)?.thLevel(widget.playerStats.townHallLevel)}",
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      Chip(
        avatar: CircleAvatar(
          backgroundColor: Colors.transparent,
          child: CachedNetworkImage(
              imageUrl: "https://assets.clashk.ing/icons/Icon_HV_XP.png"),
        ),
        labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
        label: Text(
          NumberFormat('#,###', Localizations.localeOf(context).toString())
              .format(widget.playerStats.expLevel),
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      Chip(
        avatar: Icon(LucideIcons.chevronUp,
            color: Color.fromARGB(255, 27, 114, 33)),
        labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
        label: Text(
          NumberFormat('#,###', Localizations.localeOf(context).toString())
              .format(widget.playerStats.donations),
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      Chip(
        avatar: Icon(LucideIcons.chevronDown,
            color: Color.fromARGB(255, 155, 4, 4)),
        labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
        label: Text(
          NumberFormat('#,###', Localizations.localeOf(context).toString())
              .format(widget.playerStats.donationsReceived),
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
          NumberFormat('#,###', Localizations.localeOf(context).toString())
              .format(widget.playerStats.warStars),
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
          NumberFormat('#,###', Localizations.localeOf(context).toString())
              .format(widget.playerStats.clanCapitalContributions),
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
                imageUrl: "https://assets.clashk.ing/icons/Icon_HV_Sword.png"),
          ),
          labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
          label: Text(
            NumberFormat('#,###', Localizations.localeOf(context).toString())
                .format(widget.playerStats.attackWins),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Chip(
          avatar: CircleAvatar(
            backgroundColor: Colors.transparent,
            child: CachedNetworkImage(
                imageUrl: "https://assets.clashk.ing/icons/Icon_HV_Shield.png"),
          ),
          labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
          label: Text(
            NumberFormat('#,###', Localizations.localeOf(context).toString())
                .format(widget.playerStats.defenseWins),
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
                      baseColor: Theme.of(context).colorScheme.onSurface,
                      highlightColor: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.3),
                      child: Text(
                        NumberFormat('#,###',
                                Localizations.localeOf(context).toString())
                            .format(widget.playerStats.trophies),
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
                    NumberFormat(
                            '#,###', Localizations.localeOf(context).toString())
                        .format(widget.playerStats.trophies),
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
            NumberFormat('#,###', Localizations.localeOf(context).toString())
                .format(widget.playerStats.bestTrophies),
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
            AppLocalizations.of(context)!.bhLevel(widget.playerStats.builderHallLevel),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Chip(
          avatar: CircleAvatar(
            backgroundColor: Colors.transparent,
            child: CachedNetworkImage(
                imageUrl: "https://assets.clashk.ing/icons/Icon_HV_Trophy.png"),
          ),
          labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
          label: Text(
            NumberFormat('#,###', Localizations.localeOf(context).toString())
                .format(widget.playerStats.builderBaseTrophies),
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
            NumberFormat('#,###', Localizations.localeOf(context).toString())
                .format(widget.playerStats.bestBuilderBaseTrophies),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),*/
    ];
  }
}
