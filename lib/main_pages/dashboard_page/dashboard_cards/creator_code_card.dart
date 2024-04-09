import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CreatorCodeCard extends StatelessWidget {
  const CreatorCodeCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        // Padding right and left
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.center, // Adjust vertical alignment here
          children: <Widget>[
            Image.asset('assets/icons/Crown.png',
                width: 80, height: 80), // Specify your desired width and height
            SizedBox(width: 16), // Add space between the image and text
            Expanded(
              // Use Expanded to ensure text takes up the remaining space
              child: Text(
                AppLocalizations.of(context)?.creatorCode ??
                    'Creator Code : ClashKing',
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
    );
  }
}
