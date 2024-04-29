import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:clashkingapp/api/clan_info.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
                    alignment: Alignment.bottomCenter,
                    children: <Widget>[
                      SizedBox(
                        height: 190,
                        width: double.infinity,
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                          child: ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                Colors.black.withOpacity(0.3),
                                BlendMode.darken,
                              ),
                              child: CachedNetworkImage(imageUrl: 
                                backgroundImageUrl,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )),
                        ),
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
                        widget.clanInfo.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
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
                setState(() {
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
                      Text(
                        AppLocalizations.of(context)?.clan ?? 'Clan',
                        style: Theme.of(context).textTheme.titleSmall,
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
}

/* ListView(
        children: [
          ListTile(
            title: Text('Name: ${widget.clanInfo.name}'),
            subtitle: Text('Tag: ${widget.clanInfo.tag}'),
          ),
          ListTile(
            title: Text('Type: ${widget.clanInfo.type}'),
          ),
          ListTile(
            title: Text('Description: ${widget.clanInfo.description}'),
          ),
          ListTile(
            title: Text('Level of the clan: ${widget.clanInfo.clanLevel}'),
          ),
          ExpansionTile(
            title: Text('War stats'),
              children: <Widget>[
                ListTile(
                  title: Text('War wins: ${widget.clanInfo.warWins}'),
                ),
                ListTile(
                  title: Text('War ties: ${widget.clanInfo.warTies}'),
                ),
                ListTile(
                  title: Text('War losses: ${widget.clanInfo.warLosses}'),
                ),
              ],
          ),
        ],
      ),*/