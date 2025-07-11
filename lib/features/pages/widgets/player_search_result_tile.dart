import 'package:clashkingapp/common/widgets/buttons/chip.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/presentation/player/player_page.dart';
import 'package:flutter/material.dart';

class PlayerSearchResultTile extends StatefulWidget {
  final dynamic player;

  PlayerSearchResultTile({required this.player});

  @override
  PlayerSearchResultTileState createState() => PlayerSearchResultTileState();
}

class PlayerSearchResultTileState extends State<PlayerSearchResultTile> {
  String? townHallUrl;
  String? leagueUrl;

  @override
  void initState() {
    super.initState();
  }

  String? getLeagueName(dynamic player) {
    if (player['league'] is Map) return player['league']?['name'];
    return player['league'] ?? 'Unranked';
  }

  String? getLeagueIcon(dynamic player) {
    if (player['league'] is Map) return player['league']?['iconUrls']?['small'];
    return null;
  }

  String getClanName(dynamic player) {
    if (player['clan'] is Map) return player['clan']?['name'];
    return player['clan_name'];
  }

  String? getClanBadge(dynamic player) {
    if (player['clan'] is Map) return player['clan']?['badgeUrls']?['small'];
    return null;
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

          final Player player =
              await PlayerService().getPlayerAndClanData(widget.player['tag']);

          navigator.pop();
          navigator.push(
            MaterialPageRoute(
              builder: (context) => PlayerScreen(
                selectedPlayer: player,
              ),
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
                      child: MobileWebImage(
                          imageUrl: ImageAssets.townHall(
                              widget.player['townHallLevel'] ??
                                  widget.player['townhall'] ??
                                  1)),
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
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: Theme.of(context).colorScheme.tertiary),
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
                            ImageChip(
                              context: context,
                              imageUrl: getLeagueIcon(widget.player) ??
                                  ImageAssets.leagues[
                                      getLeagueName(widget.player) ??
                                          "Unranked"] ??
                                  ImageAssets.defaultImage,
                              label: widget.player['trophies'].toString(),
                            ),
                            ImageChip(
                              context: context,
                              imageUrl: getClanBadge(widget.player) ??
                                  ImageAssets.defaultImage,
                              label: getClanName(widget.player),
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
