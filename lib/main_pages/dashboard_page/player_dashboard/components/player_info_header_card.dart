import 'package:clashkingapp/classes/profile/profile_info.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/main_pages/dashboard_page/player_dashboard/components/achievement_page.dart';
import 'package:clipboard/clipboard.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clashkingapp/core/functions.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war/current_war_info_page.dart';
import 'package:shimmer/shimmer.dart';
import 'package:clashkingapp/main_pages/dashboard_page/to_do_dashboard/components/to_do_body_card.dart';
import 'package:clashkingapp/main_pages/dashboard_page/player_dashboard/player_stats/player_stats_page.dart';

class PlayerInfoHeaderCard extends StatefulWidget {
  final ProfileInfo playerStats;
  final String townHallImageUrl;
  final List<Widget> stars;
  final Widget hallChips;
  final String backgroundImageUrl;
  final List<String> user;

  PlayerInfoHeaderCard({
    super.key,
    required this.playerStats,
    required this.backgroundImageUrl,
    required this.townHallImageUrl,
    required this.stars,
    required this.hallChips,
    required this.user,
  });

  @override
  PlayerInfoHeaderCardState createState() => PlayerInfoHeaderCardState();
}

class PlayerInfoHeaderCardState extends State<PlayerInfoHeaderCard>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Container(
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
                    child: CachedNetworkImage(
                      imageUrl: widget.backgroundImageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
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
              Positioned(
                bottom: -72,
                child: Column(
                  children: [
                    CachedNetworkImage(
                        imageUrl: widget.townHallImageUrl, width: 170),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 46),
          Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 22),
                    widget.stars.isNotEmpty
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: widget.stars,
                          )
                        : SizedBox(height: 22),
                    SizedBox(height: 8),
                    Text(
                      widget.playerStats.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    InkWell(
                      onTap: () {
                        FlutterClipboard.copy(widget.playerStats.tag)
                            .then((value) {
                          final snackBar = SnackBar(
                            content: Center(
                              child: Text(
                                AppLocalizations.of(context)!.copiedToClipboard,
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface),
                              ),
                            ),
                            duration: Duration(milliseconds: 1500),
                            backgroundColor:
                                Theme.of(context).colorScheme.surface,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.only(top: 2.0, bottom: 10.0),
                        child: Text(widget.playerStats.tag,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.tertiary)),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                left: 34,
                child: IconButton(
                  icon: Icon(
                    Icons.verified_rounded,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 32,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AchievementScreen(playerStats: widget.playerStats),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 0,
                right: 34,
                child: IconButton(
                  icon: Icon(Icons.check_box_outlined,
                      color: Theme.of(context).colorScheme.onSurface, size: 32),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        insetPadding: EdgeInsets.all(8),
                        child: Container(
                          width: MediaQuery.of(context).size.width -
                              16, // Full screen width with 8 padding on each side
                          child: SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                  maxHeight:
                                      MediaQuery.of(context).size.height * 0.9),
                              child: IntrinsicHeight(
                                child: ToDoBodyCard(
                                  profileInfo: widget.playerStats,
                                  toDo: widget.playerStats.toDo!,
                                  tag: widget.playerStats.tag,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 56,
                left: 34,
                child: IconButton(
                  icon: Icon(Icons.equalizer_rounded,
                      color: Theme.of(context).colorScheme.onSurface, size: 32),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerStatsScreen(
                          profileInfo: widget.playerStats,
                          user: widget.user,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 56,
                right: 34,
                child: IconButton(
                  icon: Icon(Icons.sports_esports_rounded,
                      color: Theme.of(context).colorScheme.onSurface, size: 32),
                  onPressed: () async {
                    final languagecode = getPrefs('languageCode');
                    launchUrl(Uri.parse(
                        'https://link.clashofclans.com/$languagecode?action=OpenPlayerProfile&tag=${widget.playerStats.tag}'));
                  },
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: widget.hallChips,
          ),
          if (widget.playerStats.toDo != null &&
              widget.playerStats.toDo!.war != null &&
              widget.playerStats.toDo!.war!.warStateInfo.currentWarInfo != null)
            Column(children: [
              SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  shadowColor: Theme.of(context).colorScheme.secondary,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CurrentWarInfoScreen(
                        currentWarInfo: widget.playerStats.toDo!.war!
                            .warStateInfo.currentWarInfo!,
                        discordUser: widget.user,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CachedNetworkImage(
                        width: 20,
                        imageUrl:
                            "https://clashkingfiles.b-cdn.net/icons/Icon_DC_War.png",
                      ),
                      SizedBox(width: 8),
                      Shimmer.fromColors(
                        period: Duration(seconds: 3),
                        baseColor: Colors.white,
                        highlightColor: Colors.white.withOpacity(0.4),
                        child: Text(
                            AppLocalizations.of(context)?.ongoingWar ??
                                "Ongoing War",
                            style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8),
            ])
        ],
      ),
    );
  }
}
