import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/components/app_bar/app_bar_functions.dart';
import 'package:flutter/services.dart';
import 'package:clashkingapp/core/my_app.dart';
import 'package:provider/provider.dart';

class AddPlayerCard extends StatefulWidget {
  final String userId;

  const AddPlayerCard({super.key, required this.userId});

  @override
  AddPlayerCardState createState() => AddPlayerCardState();
}

class AddPlayerCardState extends State<AddPlayerCard> {
  final TextEditingController controller = TextEditingController();
  String errorMessage = '';

  void updateErrorMessage(String message) {
    setState(() {
      errorMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 30),
        TextField(
          style: Theme.of(context).textTheme.bodySmall,
          controller: controller,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.enterPlayerTag,
            labelStyle: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.tertiary, width: 1.0),
              borderRadius: BorderRadius.circular(8.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.secondary, width: 2.0),
              borderRadius: BorderRadius.circular(8.0),
            ),
            prefixIcon: Icon(Icons.tag,
                color: Theme.of(context).colorScheme.onBackground),
          ),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(
                RegExp(r'[a-zA-Z0-9]')), // Add this line
          ],
        ),
        SizedBox(height: 15), // Add spacing
        errorMessage.isNotEmpty
            ? Text(errorMessage,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.error))
            : SizedBox.shrink(),
        SizedBox(height: 15), // Add spacing
        // Styled ElevatedButton
        ElevatedButton(
          onPressed: () async {
            String token = await login();
            String playerTag = controller.text;
            final success = await addLink(
                playerTag, widget.userId, token, updateErrorMessage);
            if (success) {
              Provider.of<MyAppState>(context, listen: false)
                  .reloadUsersAccounts();
            }
            Navigator.of(context).pop();
          },
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(
                Theme.of(context).colorScheme.primary),
            foregroundColor: MaterialStateProperty.all(
                Theme.of(context).colorScheme.onPrimary),
            padding: MaterialStateProperty.all(
                EdgeInsets.symmetric(vertical: 12, horizontal: 24)),
            textStyle: MaterialStateProperty.all(
                Theme.of(context).textTheme.bodyLarge),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            elevation: MaterialStateProperty.all(4),
          ),
          child: Text(AppLocalizations.of(context)!.addAccount),
        ),
      ],
    );
  }
}
