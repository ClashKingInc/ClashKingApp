import 'dart:ui';
import 'package:clashkingapp/classes/clan/clan_info.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_info_clan/components/clan_wars_stats_card.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/classes/clan/war_league/current_league_info.dart';
import 'package:clashkingapp/classes/clan/war_league/current_war_info.dart';
import 'package:clashkingapp/classes/clan/war_league/war_log.dart';
import 'package:clashkingapp/classes/clan/war_league/wars_league_info.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war/war_functions.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war/current_war_info_page.dart';
import 'package:clashkingapp/main_pages/wars_league_page/league/current_league_info_page.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war_history/war_history_page.dart';
import 'package:shimmer/shimmer.dart';
import 'package:clashkingapp/core/functions.dart';

class ClanInfoHeaderCard extends StatefulWidget {
  final Clan clanInfo;
  final List<String> user;

  ClanInfoHeaderCard({required this.clanInfo, required this.user});

  @override
  ClanInfoHeaderCardState createState() => ClanInfoHeaderCardState();
}

class ClanInfoHeaderCardState extends State<ClanInfoHeaderCard> {
  LeagueInfoContainer leagueInfoContainer = LeagueInfoContainer();
  WarInfoContainer warInfoContainer = WarInfoContainer();

  List<Map<int, List<WarLeagueInfo>>> warLeagueInfoByRound = [];
  late Future<WarLog> warLogData = Future.value(WarLog(items: []));
  late Map<String, String> warLogStats = {};
  late Future<String> currentWarFuture;

  @override
  void initState() {
    super.initState();
    setupData();
  }

  void setupData() {
    currentWarFuture = checkCurrentWar(
        widget.clanInfo.tag, leagueInfoContainer, warInfoContainer);
    warLogData = WarLogService.fetchWarLogData(widget.clanInfo.tag);
    warLogData.then((data) {
      if (data.items.isNotEmpty) {
        setState(() {
          warLogStats = analyzeWarLogs(data.items);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String backgroundImageUrl = "https://clashkingfiles.b-cdn.net/landscape/clan-landscape.png";

    String? extractDiscordCode(String description) {
      final RegExp discordPattern = RegExp(r"https:\/\/(discord\.com\/invite\/|discord\.gg\/)([^ ]+)");
      final match = discordPattern.firstMatch(description);
      return match?.group(2);
    }
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
                  ),
                ),
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
                icon: Icon(Icons.arrow_back,
                    color: Theme.of(context).colorScheme.onPrimary, size: 32),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
        Column(
          children: [
            SizedBox(height: 20),
            Stack(
              children: [
                Positioned(
                  top: -8,
                  right: 24,
                  child: IconButton(
                    icon: Icon(Icons.sports_esports_rounded,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 32),
                    onPressed: () async {
                      final languagecode = getPrefs('languageCode');
                      launchUrl(Uri.parse('https://link.clashofclans.com/$languagecode?action=OpenClanProfile&tag=${widget.clanInfo.tag}'));
                    },
                  ),
                ),
                Positioned(
                  top: -8,
                  left: 24,
                  child: IconButton(
                    icon: Icon(Icons.bar_chart_rounded,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 32),
                    onPressed: () async {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return ClanWarsStatsCard(clanInfo: widget.clanInfo);
                        },
                      );
                    },
                  ),
                ),
                Center(
                  child: Text(
                    widget.clanInfo.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () {
                FlutterClipboard.copy(widget.clanInfo.tag).then((value) {
                  final snackBar = SnackBar(
                    content: Center(
                      child: Text(
                        AppLocalizations.of(context)!.copiedToClipboard,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                    duration: Duration(milliseconds: 1500),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                });
              },
              child: Container(
                padding: EdgeInsets.only(top: 2.0, bottom: 4.0),
                child: Text(
                  widget.clanInfo.tag,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.tertiary),
                ),
              ),
            ),
            Chip(
              avatar: CircleAvatar(
                backgroundColor: Colors.transparent,
                child: CachedNetworkImage(
                    imageUrl: widget.clanInfo.warLeague!.imageUrl),
              ),
              label: Text(
                widget.clanInfo.warLeague!.name,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 0,
              alignment: WrapAlignment.center,
              children: <Widget>[
                if (widget.clanInfo.location != null &&
                    widget.clanInfo.location!.name != 'Unknown country')
                  Chip(
                    avatar: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      child: CachedNetworkImage(
                        imageUrl: "https://clashkingfiles.b-cdn.net/country-flags/${widget.clanInfo.location!.countryCode}.png",
                      ),
                    ),
                    label: Text(
                      widget.clanInfo.location!.name,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                Chip(
                  avatar: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    child: Icon(LucideIcons.users,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 16),
                  ),
                  label: Text(
                    "${widget.clanInfo.members.toString()}/50",
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                Chip(
                  avatar: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    child: CachedNetworkImage(
                        imageUrl:
                            "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Trophy.png"),
                  ),
                  label: Text(
                    widget.clanInfo.clanPoints.toString(),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                Chip(
                  avatar: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    child: CachedNetworkImage(
                        imageUrl:
                            "https://clashkingfiles.b-cdn.net/home-base/town-hall-pics/town-hall-${widget.clanInfo.requiredTownhallLevel}.png"),
                  ),
                  label: Text(
                    widget.clanInfo.requiredTownhallLevel.toString(),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                Chip(
                  avatar: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    child: CachedNetworkImage(
                        imageUrl:
                            "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Attack.png"),
                  ),
                  label: Text(
                    widget.clanInfo.clanCapitalPoints.toString(),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                Chip(
                  avatar: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    child: Icon(LucideIcons.mail,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 16),
                  ),
                  label: Text(
                    () {
                      switch (widget.clanInfo.type.toString()) {
                        case 'inviteOnly':
                          return AppLocalizations.of(context)!.inviteOnly;
                        case 'open':
                          return AppLocalizations.of(context)!.opened;
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
                    child: CachedNetworkImage(
                        imageUrl:
                            "https://clashkingfiles.b-cdn.net/icons/Icon_DC_War.png"),
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
                FutureBuilder<List<dynamic>>(
                  future:
                      Future.wait([warLogData.then((value) => value.items)]),
                  builder: (BuildContext context,
                      AsyncSnapshot<List<dynamic>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SizedBox.shrink();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (snapshot.hasData) {
                      List<WarLogDetails> warLogDetails =
                          snapshot.data![0] as List<WarLogDetails>;
                      if (widget.clanInfo.isWarLogPublic == true) {
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WarHistoryScreen(
                                  clanTag: widget.clanInfo.tag,
                                  discordUser: widget.user,
                                  warLogData: warLogDetails,
                                  warLogStats: widget.clanInfo.warLog.warLogStats,
                                  clanName: widget.clanInfo.name,
                                ),
                              ),
                            );
                          },
                          child: Chip(
                            avatar: CircleAvatar(
                              backgroundColor: Colors.transparent,
                              backgroundImage: NetworkImage(
                                "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Clan_War.png",
                              ),
                            ),
                            label: Shimmer.fromColors(
                              period: Duration(seconds: 3),
                              baseColor:
                                  Theme.of(context).colorScheme.onSurface,
                              highlightColor: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.3),
                              child: Text(
                                AppLocalizations.of(context)?.publicWarLog ??
                                    'Public War Log',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ),
                          ),
                        );
                      } else {
                        return Chip(
                          avatar: CircleAvatar(
                            backgroundColor: Colors.transparent,
                            backgroundImage: NetworkImage(
                              "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Clan_War.png",
                            ),
                          ),
                          label: Text(
                            AppLocalizations.of(context)?.privateWarLog ??
                                'Private War Log',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        );
                      }
                    }
                    return SizedBox.shrink();
                  },
                ),
              ],
            ),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.clanInfo.description,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
                maxLines: 7,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            widget.clanInfo.description.contains("discord.com/invite/") || widget.clanInfo.description.contains("discord.gg/")
              ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: ButtonTheme(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF5865F2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.discord, size: 24),
                          SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.faqJoinDiscord),
                        ],
                      ),
                      onPressed: () async {
                        try {
                          final String? discordCode = extractDiscordCode(widget.clanInfo.description);
                          print('Code Discord trouvé : $discordCode');
                          if (discordCode != null) {
                            final Uri url = Uri.parse('https://discord.gg/$discordCode');
                            if (await launchUrl(url)) {
                              print('Le lien a été ouvert avec succès');
                            } else {
                              print('Le lien ne peut pas être ouvert');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("We can't open this link"),
                                ),
                              );
                            }
                          } else {
                            print('Aucun code Discord valide trouvé');
                          }
                        } catch (e) {
                          print('Erreur lors de la tentative d\'ouverture du lien : $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("We can't open this link"),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                )
              : SizedBox(height: 12,),
            SizedBox(height: 4),
            FutureBuilder<String>(
              future: currentWarFuture,
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox.shrink();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  final warState = snapshot.data ?? false;
                  if (warState == "war") {
                    return Column(children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary,
                          shadowColor: Theme.of(context).colorScheme.secondary,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CurrentWarInfoScreen(
                                currentWarInfo:
                                    warInfoContainer.currentWarInfo!,
                                discordUser: widget.user,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16),
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
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                    ]);
                  } else if (warState == "cwl") {
                    return Column(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            shadowColor: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CurrentLeagueInfoScreen(
                                  currentLeagueInfo:
                                      leagueInfoContainer.currentLeagueInfo!,
                                  discordUser: widget.user,
                                  clanTag: widget.clanInfo.tag,
                                  clanInfo: widget.clanInfo,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  width: 20,
                                  imageUrl: widget.clanInfo.warLeague!.imageUrl,
                                ),
                                SizedBox(width: 8),
                                Shimmer.fromColors(
                                  period: Duration(seconds: 3),
                                  baseColor: Colors.white,
                                highlightColor: Colors.white.withOpacity(0.4),
                                  child: Text(
                                    AppLocalizations.of(context)?.ongoingCwl ??
                                        "Ongoing CWL",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                      ],
                    );
                  } else if (warState == "notInWar") {
                    return Column(children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                        ),
                        onPressed: () {},
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16),
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
                              Text(
                                AppLocalizations.of(context)?.notInWar ??
                                    "Not In War",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                    ]);
                  } else {
                    return SizedBox.shrink();
                  }
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
