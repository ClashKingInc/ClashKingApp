import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_in_war_and_league/current_war_info_page.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_in_war_and_league/war_functions.dart';
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
                Colors.black.withOpacity(0.5),
                BlendMode.darken,
              ),
              child: Image.network(
                "https://clashkingfiles.b-cdn.net/landscape/war-landscape.jpg",
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
              timeLeft(widget.currentWarInfo, context),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                            widget.currentWarInfo.clan.badgeUrls.large,
                            width: 90),
                        Text(
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
                        Text(
                            "${widget.currentWarInfo.clan.destructionPercentage.toStringAsFixed(2)}%",
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.white)),
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
                        Image.network(
                            widget.currentWarInfo.opponent.badgeUrls.large,
                            width: 90),
                        Text(
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
                        Text(
                          "${widget.currentWarInfo.opponent.destructionPercentage.toStringAsFixed(2)}%",
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.white),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: 10,
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
