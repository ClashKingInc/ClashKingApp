import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PlayerStatsHeader extends StatefulWidget {
  final String playerTag;
  final String playerName;
  final int townhallLevel;
  final int mapPosition;
  final int opponentAttacks;
  final String townHallImageUrl;

  PlayerStatsHeader({
    required this.playerTag,
    required this.playerName,
    required this.townhallLevel,
    required this.mapPosition,
    required this.opponentAttacks,
    required this.townHallImageUrl,
  });

  @override
  PlayerStatsHeaderState createState() => PlayerStatsHeaderState();
}

class PlayerStatsHeaderState extends State<PlayerStatsHeader> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        SizedBox(
          height: 220,
          width: double.infinity,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
            child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.7),
                  BlendMode.darken,
                ),
                child: CachedNetworkImage(
                  imageUrl:
                      "https://clashkingfiles.b-cdn.net/landscape/war-stats.png",
                  width: double.infinity,
                  fit: BoxFit.cover,
                )),
          ),
        ),
        Positioned(
          top: 26,
          bottom: 0,
          left: 10,
          right: 10,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Center(
                child: Column(
                  children: [
                    Text(AppLocalizations.of(context)!.warStats,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    SizedBox(height: 8),
                    CachedNetworkImage(
                      imageUrl: widget.townHallImageUrl,
                      width: 50,
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.playerName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    Text(
                      widget.playerTag,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 30,
          left: 10,
          child: IconButton(
            icon: Icon(Icons.arrow_back,
                color: Theme.of(context).colorScheme.onPrimary, size: 32),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}
