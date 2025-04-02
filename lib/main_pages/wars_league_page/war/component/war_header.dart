import 'dart:ui';
import 'package:clashkingapp/main_pages/clan_page/clan_info_clan/clan_info_page.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war/current_war_info_page.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war/war_functions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/classes/clan/clan_info.dart';

class WarHeader extends StatelessWidget {
  const WarHeader({
    super.key,
    required this.widget,
  });

  final CurrentWarInfoScreen widget;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: <Widget>[
        SizedBox(
          height: 240,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha : 0.5),
                BlendMode.darken,
              ),
              child: CachedNetworkImage(
                imageUrl:
                    "https://assets.clashk.ing/landscape/war-landscape.jpg",
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              timeLeft(
                  widget.currentWarInfo,
                  context,
                  Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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
                            Clan clanInfo = await ClanService()
                                .fetchClanAndWarInfo(widget.currentWarInfo.clan.tag);
                            if (context.mounted) {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ClanInfoScreen(
                                      clanInfo: clanInfo,
                                      discordUser: widget.discordUser),
                                ),
                              );
                            }
                          },
                          child: CachedNetworkImage(
                            imageUrl:
                                widget.currentWarInfo.clan.badgeUrls.large,
                            width: 90,
                          ),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(
                            widget.currentWarInfo.clan.name,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary),
                          ),
                        ),
                        Text(
                          "${widget.currentWarInfo.clan.destructionPercentage.toStringAsFixed(2)}%",
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "${widget.currentWarInfo.clan.stars} - ${widget.currentWarInfo.opponent.stars}",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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
                            Clan clanInfo = await ClanService()
                                .fetchClanAndWarInfo(
                                    widget.currentWarInfo.opponent.tag);
                            if (context.mounted) {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ClanInfoScreen(
                                      clanInfo: clanInfo,
                                      discordUser: widget.discordUser),
                                ),
                              );
                            }
                          },
                          child: CachedNetworkImage(
                            imageUrl:
                                widget.currentWarInfo.opponent.badgeUrls.large,
                            width: 90,
                          ),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(
                            widget.currentWarInfo.opponent.name,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary),
                          ),
                        ),
                        Text(
                          "${widget.currentWarInfo.opponent.destructionPercentage.toStringAsFixed(2)}%",
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: 40,
          left: 10,
          child: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 32,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}
