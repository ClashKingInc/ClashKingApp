import 'dart:ui';
import 'package:clashkingapp/api/clan_info.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_info_clan/components/clan_wars_stats_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ClanInfoHeaderCard extends StatefulWidget {
  final ClanInfo clanInfo;

  ClanInfoHeaderCard({required this.clanInfo});

  @override
  ClanInfoHeaderCardState createState() => ClanInfoHeaderCardState();
}

class ClanInfoHeaderCardState extends State<ClanInfoHeaderCard> {
  @override
  Widget build(BuildContext context) {
    String backgroundImageUrl = "https://clashkingfiles.b-cdn.net/landscape/clan-landscape.png";
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            SizedBox(
              height: 180,
              width: double.infinity,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.6),
                      BlendMode.darken,
                    ),
                    child: CachedNetworkImage(
                      imageUrl: backgroundImageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )),
              ),
            ),
            Positioned(
              bottom: 0,
              child: CachedNetworkImage(
                imageUrl: widget.clanInfo.badgeUrls.large,
                width: 130,
              ),
            ),
            Positioned(
              top: 30,
              left: 10,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onPrimary, size: 32),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
        Column(children: [
          SizedBox(height: 20),
          Stack(
            children: [
              Positioned(
                top: -8, right: 24,
                child: IconButton(
                  icon: Icon(Icons.sports_esports_rounded,color: Theme.of(context).colorScheme.onSurface, size: 32),
                  onPressed: () async {
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    final languagecode = prefs.getString('languageCode');
                    launchUrl(Uri.parse('https://link.clashofclans.com/$languagecode?action=OpenClanProfile&tag=${widget.clanInfo.tag}'));
                  },
                ),
              ),
              Center(
                child: Text(
                  widget.clanInfo.name,
                  style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Chip(
            avatar: CircleAvatar(
              backgroundColor: Colors.transparent,
              child: CachedNetworkImage(imageUrl: widget.clanInfo.warLeague.imageUrl),
            ),
            label: Text(
              widget.clanInfo.warLeague.name,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 0,
            alignment: WrapAlignment.center,
            children: <Widget>[
              if(widget.clanInfo.location.name != 'Unknown country')
              Chip(
                avatar: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: CachedNetworkImage(
                    imageUrl: "https://clashkingfiles.b-cdn.net/country-flags/${widget.clanInfo.location.countryCode}.png",
                    ),
                  ),
                label: Text(
                  widget.clanInfo.location.name,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Chip(
                avatar: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: Icon(LucideIcons.users, color: Theme.of(context).colorScheme.onBackground, size: 16),
                ),
                label: Text(
                  "${widget.clanInfo.members.toString()}/50",
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Chip(
                avatar: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: CachedNetworkImage(imageUrl: "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Trophy.png"),
                ),
                label: Text(
                  widget.clanInfo.clanPoints.toString(),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Chip(
                avatar: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: CachedNetworkImage(imageUrl: "https://clashkingfiles.b-cdn.net/home-base/town-hall-pics/town-hall-${widget.clanInfo.requiredTownhallLevel}.png"),
                ),
                label: Text(
                  widget.clanInfo.requiredTownhallLevel.toString(),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Chip(
                avatar: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: CachedNetworkImage(imageUrl: "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Attack.png"),
                ),
                label: Text(
                  widget.clanInfo.clanCapitalPoints.toString(),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Chip(
                avatar: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: Icon(LucideIcons.mail, color: Theme.of(context).colorScheme.onBackground, size: 16),
                ),
                label: Text(
                  () {
                    switch (widget.clanInfo.type.toString()) {
                      case 'inviteOnly':
                        return AppLocalizations.of(context)!.inviteOnly;
                      case 'open':
                        return AppLocalizations.of(context)!.open;
                      case 'closed':
                        return AppLocalizations.of(context)!.closed;
                      default:
                        return '';
                    }
                  }(),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Chip(
                avatar: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: CachedNetworkImage(imageUrl: "https://clashkingfiles.b-cdn.net/icons/Icon_DC_War.png"),
                ),
                label: Text(
                  () {
                    switch (widget.clanInfo.warFrequency.toString()) {
                      case 'unknown':
                        return AppLocalizations.of(context)!.unknown;
                      case 'always':
                        return AppLocalizations.of(context)!.always;
                      case 'never':
                        return AppLocalizations.of(context)!.never;
                      case 'oncePerWeek':
                        return AppLocalizations.of(context)!.oncePerWeek;
                      case 'moreThanOncePerWeek':
                        return AppLocalizations.of(context)!.twicePerWeek;
                      case 'lessThanOncePerWeek':
                        return AppLocalizations.of(context)!.rarely;
                      default:
                        return widget.clanInfo.warFrequency.toString();
                    }
                  }(),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            widget.clanInfo.description,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 20),
          ButtonBar(
            alignment: MainAxisAlignment.spaceAround,
            buttonPadding: EdgeInsets.only(top: 0),
            children: <Widget>[
              TextButton(
                child: Text(
                  AppLocalizations.of(context)?.statistics ?? 'Statistics',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return ClanWarsStatsCard(clanInfo: widget.clanInfo);
                    },
                  );
                }
              ),
              TextButton(
                child: Text(
                  AppLocalizations.of(context)?.warLog ?? 'War Log',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                onPressed: () {
                  if (widget.clanInfo.isWarLogPublic == false) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Center(
                          child: Text(
                            AppLocalizations.of(context)?.warLogClosed ?? 'War Log closed.',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ),
                        duration: Duration(milliseconds: 1500),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Center(
                          child: Text(
                            AppLocalizations.of(context)?.comingSoon ?? 'Comming soon !',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ),
                        duration: Duration(milliseconds: 1500),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ]),
      ],
    );
  }
}
