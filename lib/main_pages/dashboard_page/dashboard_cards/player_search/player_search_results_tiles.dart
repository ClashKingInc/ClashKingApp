import 'package:clashkingapp/main_pages/dashboard_page/player_dashboard/player_info_page.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/api/player_account_info.dart';

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
      leagueUrl =
          await PlayerService().fetchLeagueImageUrl(widget.player["league"]);
    }
    setState(() {});
  }

  Future<void> fetchTownHallUrl() async {
    if (widget.player.containsKey('townHallLevel')) {
      townHallUrl = await PlayerService()
          .fetchPlayerTownHallByTownHallLevel(widget.player['townHallLevel']);
    } else {
      townHallUrl = await PlayerService()
          .fetchPlayerTownHallByTownHallLevel(widget.player['th']);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
        PlayerAccountInfo playerStats =
            await PlayerService().fetchPlayerStats(widget.player['tag']);
        navigator.pop();
        navigator.push(
          MaterialPageRoute(
            builder: (context) =>
                StatsScreen(playerStats: playerStats, discordUser: widget.user),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: CachedNetworkImage(
                          imageUrl: townHallUrl ??
                              "https://clashkingfiles.b-cdn.net/home-base/town-hall-pics/town-hall-16.png"),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 7,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${widget.player['name']} "),
                      Text("${widget.player['tag']}",
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge!
                              .copyWith(
                                  color:
                                      Theme.of(context).colorScheme.tertiary)),
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
                                          (widget.player.containsKey('league') && widget.player['league'] is Map && widget.player['league'].containsKey('iconUrls')
                                              ? widget.player['league']
                                                  ['iconUrls']['tiny']
                                              : 'https://clashkingfiles.b-cdn.net/home-base/league-icons/Icon_HV_CWL_Unranked.png')),
                                ),
                                label: Text(
                                  widget.player['trophies'].toString(),
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                            ],
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
    );
  }
}
