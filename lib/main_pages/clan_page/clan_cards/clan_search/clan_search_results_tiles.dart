import 'package:flutter/material.dart';
import 'dart:async';
import 'package:clashkingapp/classes/clan/clan_info.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_info_clan/clan_info_page.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/classes/data/league_data_manager.dart';

class ClanSearchResultTile extends StatefulWidget {
  final dynamic clan;
  final List<String> user;

  ClanSearchResultTile({required this.clan, required this.user});

  @override
  ClanSearchResultTileState createState() => ClanSearchResultTileState();
}

class ClanSearchResultTileState extends State<ClanSearchResultTile> {
  String? leagueUrl;

  @override
  void initState() {
    super.initState();
    fetchLeagueUrl();
  }

  Future<void> fetchLeagueUrl() async {
    leagueUrl = LeagueDataManager().getLeagueUrl(widget.clan['warLeague']['name']);
    setState(() {});
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
          Clan clanInfo = await ClanService().fetchClanAndWarInfo(widget.clan['tag']);
          navigator.pop();
          navigator.push(
            MaterialPageRoute(builder: (context) => ClanInfoScreen(clanInfo: clanInfo, discordUser: widget.user)),
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
                    Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 50,
                        child: CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),imageUrl: widget.clan['badgeUrls']['medium']),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start, 
                        children: [
                          Text("${widget.clan['name']} "),
                          (widget.clan.containsKey('location') && widget.clan['location']!.containsKey('countryCode'))
                            ? CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                              imageUrl: "https://assets.clashk.ing/country-flags/${widget.clan['location']['countryCode'].toLowerCase()}.png",
                              width: 16)
                            : SizedBox.shrink(),
                          SizedBox(width: 8),
                          CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                            width: 20,
                            imageUrl: leagueUrl ?? "https://assets.clashk.ing/icons/Icon_HV_Trophy.png",
                          ),
                        ],
                      ),
                      Text(
                        "${widget.clan['tag']}",
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
                                avatar: Icon(LucideIcons.users, size: 16, color: Theme.of(context).colorScheme.onSurface),
                                label: Text(
                                  widget.clan['members'].toString(),
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                              Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: Colors.transparent,
                                  child: CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),imageUrl: "https://assets.clashk.ing/icons/Icon_HV_Trophy.png"),
                                ),
                                label: Text(
                                  widget.clan['clanPoints'].toString(),
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
