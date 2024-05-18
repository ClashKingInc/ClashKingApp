import 'package:clashkingapp/api/player_account_info.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/main_pages/dashboard_page/player_dashboard/components/achievement_page.dart';
import 'package:clipboard/clipboard.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class PlayerInfoHeaderCard extends StatefulWidget {
  final PlayerAccountInfo playerStats;
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
                      )),
                ),
              ),
              Positioned(
                bottom: -90,
                child: Column(children: [
                  GestureDetector(
                    onDoubleTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AchievementScreen(playerStats: widget.playerStats)),
                      );
                    },
                    child: CachedNetworkImage(imageUrl: widget.townHallImageUrl, width: 170),
                  ),
                  Row(
                    children: [
                      widget.stars.isNotEmpty
                        ? Row(
                            children: widget.stars,
                          )
                        : SizedBox(height: 22)
                    ],
                  ),
                ]),
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
            ],
          ),
          SizedBox(height: 96),
          Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.playerStats.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    InkWell(
                      onTap: () {
                        FlutterClipboard.copy(widget.playerStats.tag).then((value) {
                          final snackBar = SnackBar(
                            content: Text(AppLocalizations.of(context)!.copiedToClipboard),
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
                top: -8, right: 24,
                child: IconButton(
                  icon: Icon(
                    Icons.sports_esports_rounded,
                    color: Theme.of(context).colorScheme.onSurface, size: 32),
                  onPressed: () {
                    launchUrl(Uri.parse('https://link.clashofclans.com/fr?action=OpenPlayerProfile&tag=${widget.playerStats.tag}'));
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
