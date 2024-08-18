import 'package:clashkingapp/classes/account/accounts.dart';
import 'package:clashkingapp/main_pages/dashboard_page/to_do_dashboard/components/to_do_body_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';


class ToDoBody extends StatefulWidget {
  final Accounts accounts;
  final Map<String, String> filterOptions;
  final bool active;
  final List<String> tags;

  ToDoBody({
    super.key,
    required this.filterOptions,
    required this.active,
    required this.tags,
    required this.accounts,
  });

  @override
  ToDoBodyState createState() => ToDoBodyState();
}

class ToDoBodyState extends State<ToDoBody> {
  List<Widget> _buildCards() {
    DateTime today = DateTime.now();
    List<Widget> cards = [];

    for (var profile in widget.accounts.accounts) {
      for (var toDo in widget.accounts.toDoList.items
          .where((item) => item.playerTag == profile.tag)) {
        Account? currentAccount =
            widget.accounts.findAccountByTag(toDo.playerTag);
        DateTime lastActiveDate =
            DateTime.fromMillisecondsSinceEpoch(toDo.lastActive * 1000);
        int daysDiff = today.difference(lastActiveDate).inDays;

        if ((widget.active && daysDiff <= 14) ||
            (!widget.active && daysDiff > 14)) {
          cards.add(ToDoBodyCard(tag: profile.tag, profileInfo: currentAccount!.profileInfo, toDo: toDo));
        }
      }
    }

    return cards;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> cards = _buildCards();

    return Column(
      children: [
        SizedBox(height: 8),
        /*FilterDropdown(
          sortBy: currentFilter,
          updateSortBy: updateFilter,
          sortByOptions: filterOptions,
        ),
        SizedBox(height: 8),*/
        if (cards.isEmpty && !widget.active)
          Container(
            width: double.infinity, // Prend toute la largeur de l'écran
            margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(AppLocalizations.of(context)!.noInactiveAccounts),
                    SizedBox(height: 10),
                    CachedNetworkImage(
                      imageUrl:
                          'https://assets.clashk.ing/stickers/Villager_BB_Master_Builder_7.png',
                      width: 200,
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (cards.isEmpty && widget.active)
          Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(AppLocalizations.of(context)!.noActiveAccounts),
                    SizedBox(height: 10),
                    CachedNetworkImage(
                      imageUrl:
                          'https://assets.clashk.ing/stickers/Villager_BB_Master_Builder_4.png',
                      width: 200,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...cards,
      ],
    );
  }
}
