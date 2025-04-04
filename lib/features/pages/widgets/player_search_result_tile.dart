import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/presentation/player/player_page.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
              await PlayerService().getPlayerData(widget.player['tag']);

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
                      child: CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                          imageUrl: ImageAssets.townHall(
                              widget.player['townHallLevel'] ?? 1)),
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
                            Chip(
                              avatar: CircleAvatar(
                                backgroundColor: Colors.transparent,
                                child: CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                                  imageUrl: ImageAssets.leagues[widget
                                              .player['league']?['iconUrls'] ??
                                          "Unranked"] ??
                                      ImageAssets.defaultImage,
                                ),
                              ),
                              label: Text(
                                widget.player['trophies'].toString(),
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ),
                            Chip(
                              labelPadding:
                                  EdgeInsets.only(left: 2.0, right: 2.0),
                              label: Text(
                                widget.player['clan_name'] ??
                                    widget.player['clan']?['name'] ??
                                    AppLocalizations.of(context)?.noClan,
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
