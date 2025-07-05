import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/common/widgets/dialogs/open_clash_dialog.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

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
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                AppLocalizations.of(context)?.gameCreatorCodeDialogTitle ?? 'Support ClashKing',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Text(
                AppLocalizations.of(context)?.gameCreatorCodeDialogDescription ??
                    'Using our creator code helps fund development, keeps the app & bot free for all, and allows us to add new features.\n\nIt doesn\'t cost you anything - just use "ClashKing" as your creator code in the Clash of Clans shop!',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context)?.generalCancel ?? 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    
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
                  child: Text(
                    AppLocalizations.of(context)?.gameCreatorCodeDialogButton ?? 'Use Creator Code',
                  ),
                ),
              ],
            );
          },
        );
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),imageUrl: logoUrl, height: 80),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.gameCreatorCode ??
                          'Creator Code : ClashKing',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)?.gameCreatorCodeDescription ??
                          'Tap for info • Support us for free!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
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
