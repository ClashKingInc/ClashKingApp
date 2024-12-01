import 'package:clashkingapp/classes/events/wrapped/clash_wrapped.dart';
import 'package:clashkingapp/front/events/wrapped/wrapped_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:marquee/marquee.dart';

class WrappedCard extends StatefulWidget {
  final ClashWrappedData wrappedData;

  WrappedCard({required this.wrappedData});

  @override
  WrappedCardState createState() => WrappedCardState();
}

class WrappedCardState extends State<WrappedCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WrappedScreen(wrappedData: widget.wrappedData),
          ),
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface),
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
