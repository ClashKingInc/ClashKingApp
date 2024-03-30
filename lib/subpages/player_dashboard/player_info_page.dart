import 'package:flutter/material.dart';
import 'package:clashkingapp/api/player_account_info.dart';
import 'dart:ui';
import 'package:clipboard/clipboard.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class StatsScreen extends StatefulWidget {
  final PlayerAccountInfo playerStats;

  StatsScreen({Key? key, required this.playerStats}) : super(key: key);

  @override
  StatsScreenState createState() => StatsScreenState();
}

class StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
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
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Colors.black
                            .withOpacity(0.3), // Adjust opacity as needed
                        BlendMode.darken,
                      ),
                      child: Image.network(
                        "https://clashkingfiles.b-cdn.net/landscape/home-landscape.png",
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -70,
                  child: Column(children: [
                    Row(children: [
                    ..._buildStars(widget.playerStats.townHallWeaponLevel),],),
                    Image.network(widget.playerStats.townHallPic, width: 170),
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
            SizedBox(height: 64),
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
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8.0,
                runSpacing: 0,
                children: [
                  Chip(
                    avatar: Icon(LucideIcons.heartHandshake),
                    labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
                    label: Text(
                      widget.playerStats.clan.name,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  Chip(
                    avatar: Icon(LucideIcons.user),
                    labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
                    label: Text(
                      widget.playerStats.role,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  Chip(
                    avatar: Icon(LucideIcons.gem),
                    labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
                    label: Text(
                      widget.playerStats.clanCapitalContributions.toString(),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  Chip(
                    avatar: Icon(LucideIcons.arrowBigUp),
                    labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
                    label: Text(
                      '${widget.playerStats.expLevel}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  Chip(
                    avatar: Icon(LucideIcons.chevronUp),
                    labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
                    label: Text(
                      '${widget.playerStats.donations}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  Chip(
                    avatar: Icon(LucideIcons.chevronDown),
                    labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
                    label: Text(
                      '${widget.playerStats.donationsReceived}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  Chip(
                    avatar: Icon(LucideIcons.chevronsUpDown),
                    labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
                    label: Text(
                      '${(widget.playerStats.donations / (widget.playerStats.donationsReceived == 0 ? 1 : widget.playerStats.donationsReceived))}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
            ScrollableTab(
              labelColor: Colors.black,
              onTap: (value) {
                print('Tab $value selected');
              },
              tabs: [
                Tab(text: AppLocalizations.of(context)!.homeBase),
                Tab(text: AppLocalizations.of(context)!.builderBase),
              ],
              children: [
                ListTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                        child: Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8.0,
                            runSpacing: 0,
                            children: [
                              Chip(
                                avatar: Icon(LucideIcons.home),
                                labelPadding:
                                    EdgeInsets.only(left: 2.0, right: 2.0),
                                label: Text(
                                  "TH ${widget.playerStats.townHallLevel}",
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ),
                              Chip(
                                avatar: Icon(LucideIcons.trophy),
                                labelPadding:
                                    EdgeInsets.only(left: 2.0, right: 2.0),
                                label: Text(
                                  widget.playerStats.trophies.toString(),
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ),
                              Chip(
                                avatar: Icon(LucideIcons.crown),
                                labelPadding:
                                    EdgeInsets.only(left: 2.0, right: 2.0),
                                label: Text(
                                  widget.playerStats.bestTrophies.toString(),
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ),
                              Chip(
                                avatar: Icon(LucideIcons.sword),
                                labelPadding:
                                    EdgeInsets.only(left: 2.0, right: 2.0),
                                label: Text(
                                  widget.playerStats.attackWins.toString(),
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ),
                              Chip(
                                avatar: Icon(LucideIcons.shield),
                                labelPadding:
                                    EdgeInsets.only(left: 2.0, right: 2.0),
                                label: Text(
                                  widget.playerStats.defenseWins.toString(),
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ),
                              Chip(
                                avatar: Icon(LucideIcons.sword),
                                labelPadding:
                                    EdgeInsets.only(left: 2.0, right: 2.0),
                                label: Text(
                                  widget.playerStats.warPreference.toString(),
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ),
                              Chip(
                                avatar: Icon(LucideIcons.star),
                                labelPadding:
                                    EdgeInsets.only(left: 2.0, right: 2.0),
                                label: Text(
                                  '${widget.playerStats.warStars}',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ExpansionTile(
                        title: Text('Heroes'),
                        children: widget.playerStats.heroes
                            .where((hero) => hero.village == 'home')
                            .map((hero) => ListTile(
                                  title: Text(hero.name),
                                  subtitle: Text(
                                      'Level: ${hero.level} / ${hero.maxLevel}'),
                                ))
                            .toList(),
                      ),
                      ExpansionTile(
                        title: Text('Troops'),
                        children: widget.playerStats.troops
                            .where((troop) =>
                                troop.village == 'home' &&
                                !troop.name.startsWith('Super'))
                            .map((troop) => ListTile(
                                  title: Text(troop.name),
                                  subtitle: Text(
                                      'Level: ${troop.level} / ${troop.maxLevel} - ${troop.village}'),
                                ))
                            .toList(),
                      ),
                      ExpansionTile(
                        title: Text('Spells'),
                        children: widget.playerStats.spells
                            .map((spell) => ListTile(
                                  title: Text(spell.name),
                                  subtitle: Text(
                                      'Level: ${spell.level} / ${spell.maxLevel} - ${spell.village}'),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),

                // Builder Base
                ListTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                          'Builder Hall Level: ${widget.playerStats.builderHallLevel}'),
                      Text(
                          'Builder Base Trophies: ${widget.playerStats.builderBaseTrophies}'),
                      ExpansionTile(
                        title: Text('Heroes'),
                        children: widget.playerStats.heroes
                            .where((hero) => hero.village == 'builderBase')
                            .map((hero) => ListTile(
                                  title: Text(hero.name),
                                  subtitle: Text(
                                      'Level: ${hero.level} / ${hero.maxLevel}'),
                                ))
                            .toList(),
                      ),
                      ExpansionTile(
                        title: Text('Troops'),
                        children: widget.playerStats.troops
                            .where((troop) => troop.village == 'builderBase')
                            .map((troop) => ListTile(
                                  title: Text(troop.name),
                                  subtitle: Text(
                                      'Level: ${troop.level} / ${troop.maxLevel} - ${troop.village}'),
                                ))
                            .toList(),
                      ),
                    ],
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
    (index) => Icon(Icons.star, color: Colors.yellow),
  );
}
}
