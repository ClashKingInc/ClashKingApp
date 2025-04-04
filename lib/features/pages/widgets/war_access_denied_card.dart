import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WarAccessDeniedCard extends StatefulWidget {
  final String clanName;
  final String clanBadgeUrl;

  WarAccessDeniedCard({
    super.key,
    required this.clanName,
    required this.clanBadgeUrl
  });

  @override
  WarAccessDeniedCardState createState() => WarAccessDeniedCardState();
}

class WarAccessDeniedCardState extends State<WarAccessDeniedCard> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Column(
                children: <Widget>[
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: Center(
                      child: CachedNetworkImage(imageUrl: 
                        widget.clanBadgeUrl,
                        fit: BoxFit.cover),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(AppLocalizations.of(context)?.warLogIsClosed(widget.clanName) ?? "'s war log is closed.",
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        AppLocalizations.of(context)?.askForWarLogOpening ?? 'Contact a leader or a co-leader to open the war log.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}