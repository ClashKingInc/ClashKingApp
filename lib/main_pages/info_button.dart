import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class InfoButton extends StatefulWidget {
  final String text;
  final String title;

  InfoButton({
    required this.text,
    required this.title
  });

  @override
  State<InfoButton> createState() => InfoButtonState();
}

class InfoButtonState extends State<InfoButton> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 40,
      right: 15,
      child: GestureDetector(
        onTap: () => showInfoPopup(context, widget.text, widget.title),
        child: Icon(Icons.info_outline,
                color: Theme.of(context).colorScheme.onPrimary, size: 32),
      ),
    );
  }
}

void showInfoPopup(BuildContext context, String text, String title) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: <Widget>[
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
