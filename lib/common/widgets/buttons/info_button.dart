import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

class InfoButton extends StatefulWidget {
  final TextSpan textSpan;
  final String title;

  const InfoButton({super.key, required this.textSpan, required this.title});

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
        onTap: () => showInfoPopup(context, widget.textSpan, widget.title),
        child: Icon(
          Icons.info_outline,
          color: Theme.of(context).colorScheme.onPrimary,
          size: 24,
        ),
      ),
    );
  }
}

void showInfoPopup(BuildContext context, TextSpan textSpan, String title) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(child: RichText(text: textSpan)),
        actions: <Widget>[
          TextButton(
            child: Text(AppLocalizations.of(context)!.generalOk),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
