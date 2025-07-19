import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/presentation/clan_info/clan_page.dart';

class ClanSearchResultTile extends StatefulWidget {
  final dynamic clan;

  ClanSearchResultTile({required this.clan});

  @override
  ClanSearchResultTileState createState() => ClanSearchResultTileState();
}

class ClanSearchResultTileState extends State<ClanSearchResultTile> {
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
          
          try {
            final clanInfo = await ClanService().getClanAndWarData(widget.clan['tag']);
            navigator.pop();
            navigator.push(
              MaterialPageRoute(builder: (context) => ClanInfoScreen(clanInfo: clanInfo)),
            );
          } catch (e) {
            navigator.pop();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to load clan data: ${e.toString()}')),
              );
            }
          }
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
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                            imageUrl: widget.clan['badgeUrls']['medium']),
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
                          (widget.clan.containsKey('location') &&
                                  widget.clan['location']!
                                      .containsKey('countryCode'))
                              ? CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                                  imageUrl: ImageAssets.flag(widget
                                      .clan['location']['countryCode']
                                      .toLowerCase()),
                                  width: 16)
                              : SizedBox.shrink(),
                          SizedBox(width: 8),
                          CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                            width: 20,
                            imageUrl: ImageAssets.leagues[
                                    widget.clan['warLeague']['name']] ??
                                ImageAssets.leagues['Unranked']!,
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
                                avatar: Icon(LucideIcons.users,
                                    size: 16,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface),
                                label: Text(
                                  widget.clan['members'].toString(),
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                              Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: Colors.transparent,
                                  child: CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                                      imageUrl: ImageAssets.trophies),
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
