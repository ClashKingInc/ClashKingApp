import 'package:clashkingapp/classes/account/accounts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/classes/profile/profile_info.dart';
import 'package:clashkingapp/main_pages/dashboard_page/to_do_dashboard/components/to_do_header.dart';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';
import 'package:clashkingapp/main_pages/dashboard_page/to_do_dashboard/components/to_do_body.dart'; 

class ToDoScreen extends StatefulWidget {
  final ProfileInfo playerStats;
  final List<String> tags;
  final Accounts accounts;

  ToDoScreen(
      {super.key,
      required this.playerStats,
      required this.tags,
      required this.accounts});

  @override
  ToDoScreenState createState() => ToDoScreenState();
}

class ToDoScreenState extends State<ToDoScreen>
    with SingleTickerProviderStateMixin {
  String currentFilter = 'all';

  @override
  void initState() {
    super.initState();
    checkToDoIsInitialized();
  }

  void checkToDoIsInitialized() {
    while (!widget.accounts.isTodoInitialized && widget.accounts.toDoList.numberAccounts > 0) {
      Future.delayed(Duration(milliseconds: 100), () {
        checkToDoIsInitialized();
      });
    }
  }

  void updateFilter(String newFilter) {
    setState(() {
      currentFilter = newFilter;
    });
  }

  @override
  Widget build(BuildContext context) {
    Map<String, String> filterOptions = {
      AppLocalizations.of(context)!.all: 'all',
      //'byEvent': 'byEvent',
    };

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            ToDoHeader(accounts: widget.accounts),
            ScrollableTab(
                tabBarDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                ),
                labelColor: Theme.of(context).colorScheme.onSurface,
                labelPadding: EdgeInsets.zero,
                labelStyle: Theme.of(context).textTheme.bodyLarge,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
                onTap: (value) {
                  setState(() {});
                },
                tabs: [
                  Tab(text: AppLocalizations.of(context)!.activeAccounts),
                  Tab(text: AppLocalizations.of(context)!.inactiveAccounts),
                ],
                children: [
                  ToDoBody(accounts: widget.accounts, tags: widget.tags, filterOptions: filterOptions, active: true),
                  ToDoBody(accounts: widget.accounts, tags: widget.tags, filterOptions: filterOptions, active: false),
                ]),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
