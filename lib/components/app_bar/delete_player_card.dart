import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/classes/account/cocdiscord_link_functions.dart';
import 'package:clashkingapp/classes/account/user.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/core/my_app_state.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/core/startup_widget.dart';
import 'package:clashkingapp/classes/account/accounts.dart';
import 'package:clashkingapp/core/functions.dart';

class DeletePlayerCard extends StatefulWidget {
  final User user;
  final Accounts accounts;

  const DeletePlayerCard(
      {super.key, required this.user, required this.accounts});

  @override
  DeletePlayerCardState createState() => DeletePlayerCardState();
}

class DeletePlayerCardState extends State<DeletePlayerCard> {
  String? _dropdownValue;
  String errorMessage = '';

  void updateErrorMessage(String message) {
    setState(() {
      errorMessage = message;
    });
  }

  @override
  void initState() {
    super.initState();
    // Set the default value for _dropdownValue
    if (widget.accounts.accounts.isNotEmpty) {
      _dropdownValue = widget.accounts.accounts.first.profileInfo.tag;
    }
  }

  @override
  Widget build(BuildContext context) {
    final failedToDeleteTryAgain =
        AppLocalizations.of(context)!.failedToDeleteTryAgain;
    var myAppState = Provider.of<MyAppState>(context, listen: false);

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(children: [
          SizedBox(height: 15),
          DropdownButton<String>(
            elevation: 16,
            dropdownColor: Theme.of(context).colorScheme.surface,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            underline: Container(),
            items: widget.accounts.accounts
                .map<DropdownMenuItem<String>>((Account account) {
              String tag = account.profileInfo.tag;
              String imageUrl = account.profileInfo.townHallPic;
              String name = account.profileInfo.name;
              return DropdownMenuItem<String>(
                value: tag,
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      height: 30,
                      width: 30,
                      child: CachedNetworkImage(imageUrl: imageUrl),
                    ),
                    SizedBox(width: 4),
                    Text(name,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Theme.of(context).colorScheme.onSurface)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _dropdownValue = newValue!;
              });
            },
            value: _dropdownValue,
          ),
          SizedBox(height: 15), // Add spacing
          errorMessage.isNotEmpty
              ? Text(errorMessage,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.error))
              : SizedBox.shrink(),
          SizedBox(height: 15),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              String token = await login();
              String playerTag = _dropdownValue!;
              if (widget.user.isDiscordUser) {
                final success = await deleteLink(playerTag, token,
                    updateErrorMessage, failedToDeleteTryAgain);
                if (success) {
                  widget.user.tags.remove(playerTag);
                  if (widget.user.tags.isNotEmpty) {
                    deletePrefs('selectedTag');
                    if (context.mounted) {
                      myAppState.deleteAccountByTag(playerTag, myAppState);
                    }
                    if (errorMessage.isEmpty) {
                      navigator.pop();
                    }
                  } else {
                    navigator.push(
                        MaterialPageRoute(builder: (_) => StartupWidget()));
                  }
                }
              } else {
                widget.user.tags.remove(playerTag);
                if (widget.user.tags.isNotEmpty) {
                  deletePrefs('selectedTag');
                  if (context.mounted) {
                    myAppState.deleteAccountByTag(playerTag, myAppState);
                  }
                  if (errorMessage.isEmpty) {
                    navigator.pop();
                  }
                }
              }
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(
                  Theme.of(context).colorScheme.primary),
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
            child: Text(AppLocalizations.of(context)!.deleteAccount,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        ]));
  }
}
