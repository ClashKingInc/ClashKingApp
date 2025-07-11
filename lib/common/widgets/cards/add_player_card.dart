/*import 'package:clashkingapp/classes/account/user.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/classes/account/cocdiscord_link_functions.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/core/app/my_app_state.dart';
import 'package:clashkingapp/core/functions.dart';

class AddPlayerCard extends StatefulWidget {
  final User user;

  const AddPlayerCard({super.key, required this.user});

  @override
  AddPlayerCardState createState() => AddPlayerCardState();
}

class AddPlayerCardState extends State<AddPlayerCard> {
  final TextEditingController controller = TextEditingController();
  String errorMessage = '';
  final TextEditingController apiTokenController = TextEditingController();
  bool showApiTokenInput = false;
  String apiErrorMessage = '';

  void updateErrorMessage(String message) {
    setState(() {
      errorMessage = message;
    });
  }

  void updateApiErrorToken(String message) {
    setState(() {
      apiErrorMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final playerTagNotExists = AppLocalizations.of(context)!.accountsErrorTagNotExists;
    String accountAlreadyLinked =
        AppLocalizations.of(context)!.accountsErrorAlreadyLinked("");
    final failedToAddTryAgain =
        AppLocalizations.of(context)!.accountsErrorFailedToAdd;
    final failedToDeleteTryAgain =
        AppLocalizations.of(context)!.accountsErrorFailedToDelete;
    String wrongApiToken = AppLocalizations.of(context)!.accountsErrorWrongApiToken;

    return Column(
      children: [
        SizedBox(height: 30),
        TextField(
          style: Theme.of(context).textTheme.bodySmall,
          controller: controller,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.accountsEnterPlayerTag,
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
            prefixIcon:
                Icon(Icons.tag, color: Theme.of(context).colorScheme.onSurface),
          ),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(
                RegExp(r'[a-zA-Z0-9]')), // Add this line
          ],
        ),
        SizedBox(height: 16), // Add spacing
        errorMessage.isNotEmpty
            ? Text(errorMessage,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.error))
            : SizedBox.shrink(),
        SizedBox(height: 16), // Add spacing
        if (showApiTokenInput) ...[
          Text(AppLocalizations.of(context)!.accountsEnterApiToken,
              style: Theme.of(context).textTheme.bodySmall),
          SizedBox(height: 16),
          TextField(
            style: Theme.of(context).textTheme.bodySmall,
            controller: apiTokenController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.accountsApiToken,
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
            ),
          ),
          SizedBox(height: 16),
          if (apiErrorMessage.isNotEmpty)
            Text(apiErrorMessage,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.error)),
          if (apiErrorMessage.isNotEmpty) SizedBox(height: 16),
        ],

        ElevatedButton(
          onPressed: () async {
            final myAppState = Provider.of<MyAppState>(context, listen: false);
            final navigator = Navigator.of(context);

            String token = await login();
            String playerTag = controller.text;
            if (widget.user.isDiscordUser) {
              if (showApiTokenInput) {
                if (apiTokenController.text.isNotEmpty) {
                  String apiToken = apiTokenController.text;
                  bool success = await addLinkWithAPIToken(
                    playerTag,
                    widget.user.id,
                    token,
                    updateApiErrorToken,
                    playerTagNotExists,
                    accountAlreadyLinked,
                    failedToAddTryAgain,
                    apiToken,
                    failedToDeleteTryAgain,
                    wrongApiToken,
                  );
                  if (success) {
                    await storePrefs('selectedTag', playerTag);
                    if (context.mounted) {
                      await myAppState.addAccount(playerTag, myAppState);
                    }
                  }
                  if (apiErrorMessage.isEmpty) {
                    navigator.pop();
                  } else if (errorMessage == accountAlreadyLinked) {
                    setState(() {
                      showApiTokenInput = true; // Show API token input on error
                    });
                  }
                }
              } else if (!widget.user.tags.contains("#$playerTag")) {
                bool success = await addLink(
                  playerTag,
                  widget.user.id,
                  token,
                  updateErrorMessage,
                  playerTagNotExists,
                  accountAlreadyLinked,
                  failedToAddTryAgain,
                );
                if (success) {
                  await storePrefs('selectedTag', playerTag);
                  if (context.mounted) {
                    await myAppState.addAccount(playerTag, myAppState);
                  }
                }
                if (errorMessage.isEmpty) {
                  navigator.pop();
                } else if (errorMessage == accountAlreadyLinked) {
                  setState(() {
                    showApiTokenInput = true; // Show API token input on error
                  });
                }
              } else {
                if (context.mounted) {
                  updateErrorMessage(
                      AppLocalizations.of(context)!.accountsErrorAlreadyLinkedToYou);
                }
              }
            } else {
              if (showApiTokenInput) {
                String apiToken = apiTokenController.text;
                bool success = await checkApiToken(
                    apiToken, playerTag, updateErrorMessage, wrongApiToken);
                if (success) {
                  await storePrefs('selectedTag', playerTag);
                  if (context.mounted) {
                    await myAppState.addAccount(playerTag, myAppState);
                  }
                }
                if (apiErrorMessage.isEmpty) {
                  navigator.pop();
                } else if (errorMessage == accountAlreadyLinked) {
                  setState(() {
                    showApiTokenInput = true; // Show API token input on error
                  });
                }
              } else if (!widget.user.tags.contains("#$playerTag")) {
                bool success = await addLink(
                  playerTag,
                  widget.user.id,
                  token,
                  updateErrorMessage,
                  playerTagNotExists,
                  accountAlreadyLinked,
                  failedToAddTryAgain,
                );
                if (success) {
                  await storePrefs('selectedTag', playerTag);
                  if (context.mounted) {
                    await myAppState.addAccount(playerTag, myAppState);
                  }
                }
                if (errorMessage.isEmpty) {
                  navigator.pop();
                } else if (errorMessage == accountAlreadyLinked) {
                  setState(() {
                    showApiTokenInput = true; // Show API token input on error
                  });
                }
              } else {
                if (context.mounted) {
                  updateErrorMessage(
                      AppLocalizations.of(context)!.accountsErrorAlreadyLinkedToYou);
                }
              }
            }
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.secondary),
            foregroundColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.onPrimary),
            padding: WidgetStateProperty.all(
                EdgeInsets.symmetric(vertical: 12, horizontal: 24)),
            textStyle: WidgetStateProperty.all(
                Theme.of(context).textTheme.bodyLarge),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            elevation: WidgetStateProperty.all(4),
          ),
          child: Text(AppLocalizations.of(context)!.accountsAdd,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSecondary)),
        ),
      ],
    );
  }
}
*/