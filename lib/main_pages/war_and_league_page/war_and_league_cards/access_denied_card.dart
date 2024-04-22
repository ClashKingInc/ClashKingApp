import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AccessDeniedCard extends StatefulWidget {
  final String clanName;
  final String clanBadgeUrl;

  AccessDeniedCard({
    super.key,
    required this.clanName,
    required this.clanBadgeUrl
  });

  @override
  AccessDeniedCardState createState() => AccessDeniedCardState();
}

class AccessDeniedCardState extends State<AccessDeniedCard> {
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
                      child: Image.network(
                        widget.clanBadgeUrl,
                        fit: BoxFit.cover),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${widget.clanName}${AppLocalizations.of(context)?.warLogIsClosed ?? "'s war log is closed."}',
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