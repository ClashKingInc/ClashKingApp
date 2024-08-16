import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clashkingapp/core/functions.dart';

class CreatorCodeCard extends StatefulWidget {
  @override
  CreatorCodeCardState createState() => CreatorCodeCardState();
}

class CreatorCodeCardState extends State<CreatorCodeCard> {
  @override
  Widget build(BuildContext context) {
    // Check if the theme is light or dark using Theme.of(context)
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Set the appropriate image URLs based on the theme
    final logoUrl = isDarkMode
        ? "https://assets.clashk.ing/logos/crown-arrow-dark-bg/ClashKing-1.png"
        : "https://assets.clashk.ing/logos/crown-arrow-white-bg/ClashKing-2.png";

    return GestureDetector(
      onTap: () async {
        final languagecode = await getPrefs('languageCode');
        launchUrl(Uri.parse(
            'https://link.clashofclans.com/$languagecode?action=SupportCreator&id=Clashking'));
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              CachedNetworkImage(imageUrl: logoUrl, height: 80),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)?.creatorCode ?? 'Creator Code : ClashKing',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
