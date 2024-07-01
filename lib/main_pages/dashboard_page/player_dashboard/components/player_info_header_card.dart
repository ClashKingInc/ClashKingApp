import 'package:clashkingapp/classes/profile/profile_info.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/main_pages/dashboard_page/player_dashboard/components/achievement_page.dart';
import 'package:clipboard/clipboard.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clashkingapp/core/functions.dart';

class PlayerInfoHeaderCard extends StatefulWidget {
  final ProfileInfo playerStats;
  final String townHallImageUrl;
  final List<Widget> stars;
  final Widget hallChips;
  final String backgroundImageUrl;

  PlayerInfoHeaderCard({
    super.key,
    required this.playerStats,
    required this.backgroundImageUrl,
    required this.townHallImageUrl,
    required this.stars,
    required this.hallChips,
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
        child: Column(children: [
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
                  icon: Icon(
                    Icons.arrow_back,
                    color: Theme.of(context).colorScheme.onPrimary, size: 32),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Positioned(
                bottom: -72,
                child: Column(
                  children: [
                    CachedNetworkImage(imageUrl: widget.townHallImageUrl, width: 170),
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
                        FlutterClipboard.copy(widget.playerStats.tag).then((value) {
                          final snackBar = SnackBar(
                            content: Center(
                              child: Text(
                                AppLocalizations.of(context)!.copiedToClipboard,
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                              ),
                            ),
                            duration: Duration(milliseconds: 1500),
                            backgroundColor: Theme.of(context).colorScheme.surface,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.only(top: 2.0, bottom: 10.0),
                        child: Text(widget.playerStats.tag,
                          style: TextStyle(color: Theme.of(context).colorScheme.tertiary)),
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
                        builder: (context) => AchievementScreen(playerStats: widget.playerStats),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 0, 
                right: 34,
                child: IconButton(
                  icon: Icon(
                    Icons.question_mark_rounded,
                    color: Theme.of(context).colorScheme.onSurface, size: 32),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Center(
                          child: Text(
                            AppLocalizations.of(context)?.comingSoon ?? 'Coming soon !',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ),
                        duration: Duration(milliseconds: 1500),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 56, left: 34,
                child: IconButton(
                  icon: Icon(
                    Icons.equalizer_rounded,
                    color: Theme.of(context).colorScheme.onSurface, size: 32),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Center(
                          child: Text(
                            AppLocalizations.of(context)?.comingSoon ?? 'Coming soon !',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ),
                        duration: Duration(milliseconds: 1500),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 56, right: 34,
                child: IconButton(
                  icon: Icon(
                    Icons.sports_esports_rounded,
                    color: Theme.of(context).colorScheme.onSurface, size: 32),
                  onPressed: () async {
                    final languagecode = getPrefs('languageCode');
                    launchUrl(Uri.parse('https://link.clashofclans.com/$languagecode?action=OpenPlayerProfile&tag=${widget.playerStats.tag}'));
                  },
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: widget.hallChips,
          ),
        ],
      ),
    );
  }
}