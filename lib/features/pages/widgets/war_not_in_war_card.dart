import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';

class NotInWarCard extends StatefulWidget {
  final String clanName;
  final String clanBadgeUrl;
  final bool bookmarked;

  const NotInWarCard({
    super.key,
    required this.clanName,
    required this.clanBadgeUrl,
    this.bookmarked = false,
  });

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
            if (widget.bookmarked)
              Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.bookmark_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            Center(
              child: Column(
                children: <Widget>[
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: Center(
                      child: MobileWebImage(
                        errorWidget: (context, url, error) => Icon(Icons.error),
                        imageUrl: widget.clanBadgeUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(
                              context,
                            )?.warIsNotInWar(widget.clanName) ??
                            "is not in war.",
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
