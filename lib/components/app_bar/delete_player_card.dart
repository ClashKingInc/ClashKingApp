import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/components/app_bar/app_bar_functions.dart';
import 'package:clashkingapp/api/discord_user_info.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/core/my_app.dart';
import 'package:provider/provider.dart';

class DeletePlayerCard extends StatefulWidget {
  final DiscordUser user;

  const DeletePlayerCard({super.key, required this.user});

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
    if (widget.user.selectedTagDetails.isNotEmpty) {
      _dropdownValue = widget.user.selectedTagDetails.first['tag'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(children: [
          SizedBox(height: 15),
          DropdownButton<String>(
            elevation: 16,
            dropdownColor: Theme.of(context).colorScheme.surface,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            underline: Container(),
            items: widget.user.selectedTagDetails
                .map<DropdownMenuItem<String>>((details) {
              String tag = details['tag'];
              String imageUrl = details['imageUrl'];
              String name = details['name'];
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
              final success = await deleteLink(playerTag, token, updateErrorMessage, context);
              if (success) {
                Provider.of<MyAppState>(context, listen: false).reloadUsersAccounts();
              }
              if (errorMessage.isEmpty) {
                navigator.pop();
              }
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
            child: Text(AppLocalizations.of(context)!.deleteAccount, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ]));
  }
}
