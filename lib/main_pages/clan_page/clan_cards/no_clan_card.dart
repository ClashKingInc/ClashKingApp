import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NoClanCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: Theme.of(context).textTheme.labelLarge ?? TextStyle(),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: <Widget>[
              SizedBox(
                height: 80,
                width: 80,
                child: CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                    imageUrl:
                        "https://assets.clashk.ing/builder-base/building-pics/Building_HV_Clan_Castle_level_2_3.png"),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(AppLocalizations.of(context)?.noClan ?? 'No Clan',
                        style: (Theme.of(context).textTheme.titleSmall)),
                    Text(
                        AppLocalizations.of(context)
                                ?.joinClanToUnlockNewFeatures ??
                            'Join a clan to unlock new features.',
                        style: (Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.tertiary))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
