import 'package:clashkingapp/main_pages/dashboard_page/player_dashboard/player_info_page.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/classes/data/league_data_manager.dart';
import 'package:clashkingapp/classes/functions.dart';
import 'package:clashkingapp/classes/profile/profile_info.dart';

class PlayerSearchResultTile extends StatefulWidget {
  final dynamic player;
  final List<String> user;

  PlayerSearchResultTile({required this.player, required this.user});

  @override
  PlayerSearchResultTileState createState() => PlayerSearchResultTileState();
}

class PlayerSearchResultTileState extends State<PlayerSearchResultTile> {
  String? townHallUrl;
  String? leagueUrl;

  @override
  void initState() {
    super.initState();
    fetchTownHallUrl();
    fetchLeagueUrl();
  }

  Future<void> fetchLeagueUrl() async {
    if (widget.player.containsKey('league')) {
      if(widget.player['league'] is Map && widget.player['league'].containsKey('name')) {
        leagueUrl = LeagueDataManager().getLeagueUrl(widget.player['league']['name']);
      } else {
        leagueUrl = LeagueDataManager().getLeagueUrl(widget.player['league']);
      }
    }
    setState(() {});
  }

  Future<void> fetchTownHallUrl() async {
    if (widget.player.containsKey('townHallLevel')) {
      townHallUrl = await fetchPlayerTownHallByTownHallLevel(widget.player['townHallLevel']);
    } else {
      townHallUrl = await fetchPlayerTownHallByTownHallLevel(widget.player['th']);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.transparent,
      elevation: 0.0,
      child: InkWell(
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
          ProfileInfo playerStats = await ProfileInfoService().fetchProfileInfo(widget.player['tag']);
          navigator.pop();
          navigator.push(
            MaterialPageRoute(
              builder: (context) => StatsScreen(playerStats: playerStats, discordUser: widget.user),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    SizedBox(
                      width: 50,
                      child: CachedNetworkImage(
                        imageUrl: townHallUrl ?? "https://clashkingfiles.b-cdn.net/home-base/town-hall-pics/town-hall-16.png"),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8), 
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${widget.player['name']} "),
                    Text(
                      "${widget.player['tag']}",
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Theme.of(context).colorScheme.tertiary),
                    ),
                    SizedBox(width: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.start,
                          spacing: 7.0,
                          runSpacing: -7.0,
                          children: <Widget>[
                            Chip(
                              avatar: CircleAvatar(
                                backgroundColor: Colors.transparent,
                                child: CachedNetworkImage(
                                  imageUrl: leagueUrl ??
                                    (widget.player.containsKey('league') && widget.player['league']
                                      is Map && widget.player['league'].containsKey('iconUrls')
                                        ? widget.player['league']['iconUrls']['tiny']
                                        : 'https://clashkingfiles.b-cdn.net/home-base/league-icons/Icon_HV_CWL_Unranked.png'),
                                ),
                              ),
                              label: Text(
                                widget.player['trophies'].toString(),
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ),
                            Chip(
                              labelPadding: EdgeInsets.only(left: 2.0, right: 2.0),
                              label: Text(
                                widget.player['clan_name'] ?? widget.player['clan']?['name'] ?? AppLocalizations.of(context)?.noClan,
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
