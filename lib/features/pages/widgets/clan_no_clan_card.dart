import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

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
                child: MobileWebImage(imageUrl: ImageAssets.clanCastle),
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
