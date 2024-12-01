import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/components/dialogs/open_clash_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:marquee/marquee.dart';

class WrappedCard extends StatefulWidget {
  @override
  WrappedCardState createState() => WrappedCardState();
}

class WrappedCardState extends State<WrappedCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final languageCode =
            Localizations.localeOf(context).languageCode.toLowerCase();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            final url = Uri.https('link.clashofclans.com', '/$languageCode', {
              'action': 'SupportCreator',
              'id': 'Clashking',
            });

            return OpenClashDialog(url: url);
          },
        );
      },
      child: Card(
        color: Theme.of(context).colorScheme.primary,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context)?.wrappedIsHere(2024) ?? '',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
              ),
              SizedBox(height: 4),
              SizedBox(
                height: 16,
                child: Marquee(
                  text: AppLocalizations.of(context)!.wrappedDescription,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                  scrollAxis: Axis.horizontal,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  blankSpace: 20.0,
                  velocity: 40.0,
                  pauseAfterRound: Duration(seconds: 1),
                  startPadding: 10.0,
                  accelerationDuration: Duration(seconds: 1),
                  accelerationCurve: Curves.linear,
                  decelerationDuration: Duration(milliseconds: 500),
                  decelerationCurve: Curves.easeOut,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
