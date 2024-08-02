import 'package:clashkingapp/classes/account/accounts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ToDoHeader extends StatefulWidget {
  final Accounts accounts;

  ToDoHeader({super.key, required this.accounts});

  @override
  ToDoHeaderState createState() => ToDoHeaderState();
}

class ToDoHeaderState extends State<ToDoHeader> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: CachedNetworkImageProvider(
            'https://clashkingfiles.b-cdn.net/landscape/Villager_HV_Builder_19.png',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 30, // Adjust position according to design requirements
            child: Text(
              AppLocalizations.of(context)?.toDoList ?? 'To Do List',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                  ),
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 32,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
