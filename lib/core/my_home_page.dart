import 'package:clashkingapp/custom_icons_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/main_pages/dashboard_page/dashboard_page.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_page.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war_league_page.dart';
import 'package:clashkingapp/main_pages/tools_page/tools_page.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/core/my_app_state.dart';
import 'package:clashkingapp/components/app_bar/app_bar.dart';
import 'package:clashkingapp/classes/account/accounts.dart';

class MyHomePage extends StatefulWidget {
  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  Future<void>? _initializeAccountsFuture;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _initializeAccountsFuture = _initializeAccounts();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeAccounts() async {
    final appState = Provider.of<MyAppState>(context, listen: false);
    try {
      bool success = await appState.initializeData();
      if (!success) {
        // If initialization fails, try to initialize with empty data to allow app to continue
        appState.accounts = Accounts(accounts: [], tags: []);
        appState.account = null;
      }
    } catch (e) {
      // Handle any uncaught exceptions and allow app to continue with empty state
      appState.accounts = Accounts(accounts: [], tags: []);
      appState.account = null;
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onItemTapped(int index) {
    if (_pageController.hasClients) {
      _pageController.jumpToPage(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    var appState = Provider.of<MyAppState>(context);

    return FutureBuilder(
      future: _initializeAccountsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          return ValueListenableBuilder<String?>(
            valueListenable: appState.selectedTagNotifier,
            builder: (context, selectedTag, child) {
              if (selectedTag != null && appState.accounts != null) {
                appState.account = appState.accounts!.accounts.firstWhere(
                  (account) => account.profileInfo.tag == selectedTag,
                  orElse: () => appState.accounts!.accounts.first,
                );
              }

              List<Widget> widgetOptions = [
                appState.account != null
                    ? DashboardPage(
                        playerStats: appState.account!.profileInfo,
                        discordUser: appState.user!,
                        accounts: appState.accounts!)
                    : Center(child: CircularProgressIndicator()),
                appState.account != null && appState.user != null
                    ? ClanInfoPage(
                        account: appState.account!,
                        user: appState.user!,
                      )
                    : Center(child: CircularProgressIndicator()),
                appState.account != null
                    ? CurrentWarInfoPage(
                        discordUser: appState.user!,
                        account: appState.account!,
                      )
                    : Center(child: CircularProgressIndicator()),
                ToolsPage(),
              ];
              
              return appState.accounts != null
                  ? (appState.account != null
                      ? Scaffold(
                          appBar: CustomAppBar(
                            user: appState.user!,
                            accounts: appState.accounts!,
                          ),
                          body: PageView(
                            controller: _pageController,
                            onPageChanged: _onPageChanged,
                            children: widgetOptions,
                          ),
                          bottomNavigationBar: BottomNavigationBar(
                            type: BottomNavigationBarType.fixed,
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            selectedItemColor:
                                Theme.of(context).colorScheme.primary,
                            unselectedItemColor:
                                Theme.of(context).colorScheme.tertiary,
                            items: <BottomNavigationBarItem>[
                              BottomNavigationBarItem(
                                icon: Icon(Icons.dashboard),
                                label: AppLocalizations.of(context)?.dashboard ??
                                    'Dashboard',
                              ),
                              BottomNavigationBarItem(
                                icon: Icon(Icons.shield),
                                label: AppLocalizations.of(context)?.clan ?? 'Clan',
                              ),
                              BottomNavigationBarItem(
                                icon: Icon(CustomIcons.swordCross),
                                label: AppLocalizations.of(context)?.warLeague ??
                                    'War/League',
                              ),
                              BottomNavigationBarItem(
                                icon: Icon(Icons.settings),
                                label:
                                    AppLocalizations.of(context)?.tools ?? 'Tools',
                              ),
                            ],
                            currentIndex: _selectedIndex,
                            showUnselectedLabels: true,
                            onTap: _onItemTapped,
                          ),
                        )
                      : Scaffold(
                          appBar: CustomAppBar(
                            user: appState.user!,
                            accounts: appState.accounts!,
                          ),
                          body: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.account_circle, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No accounts found',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Please add a Clash of Clans account to continue',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ))
                  : Scaffold(
                      body: Center(
                          child: Text(AppLocalizations.of(context)!
                              .connectionErrorRelaunch)),
                    );
            },
          );
        }
      },
    );
  }
}
