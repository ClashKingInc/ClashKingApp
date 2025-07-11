import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NotInWarCard extends StatefulWidget {
  final String clanName;
  final String clanBadgeUrl;

  NotInWarCard({super.key, required this.clanName, required this.clanBadgeUrl});

  @override
  NotInWarCardState createState() => NotInWarCardState();
}

class NotInWarCardState extends State<NotInWarCard> {
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
                      child: CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                          imageUrl: widget.clanBadgeUrl, fit: BoxFit.cover),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context)
                                ?.warIsNotInWar(widget.clanName) ??
                            "is not in war.",
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        AppLocalizations.of(context)?.warAskForWar ??
                            'Contact a leader or co-leader to start a war.',
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
