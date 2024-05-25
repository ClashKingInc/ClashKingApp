import 'package:clashkingapp/custom_icons_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/main_pages/dashboard_page/dashboard_page.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_page.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_league_page.dart';
import 'package:clashkingapp/main_pages/management_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/core/my_app_state.dart';
import 'package:clashkingapp/components/app_bar/app_bar.dart';

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
    print('Initializing accounts');
    final appState = Provider.of<MyAppState>(context, listen: false);
    await appState.fetchPlayerAccounts(appState.user!);
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
            List<Widget> widgetOptions = [
              appState.playerAccounts != null && appState.playerStats != null
                  ? DashboardPage(
                      playerStats: appState.playerStats!,
                      discordUser: appState.user!)
                  : Center(
                      child:
                          CircularProgressIndicator()), // Wrap CircularProgressIndicator with Center
              appState.user != null
                  ? ClanInfoPage(
                      clanInfo: appState.clanInfo, user: appState.user!)
                  : Center(
                      child:
                          CircularProgressIndicator()), // Wrap CircularProgressIndicator with Center
              appState.user != null && appState.playerStats != null
                  ? CurrentWarInfoPage(
                      discordUser: appState.user!,
                      playerStats: appState.playerStats!,
                      clanInfo: appState.clanInfo)
                  : Center(
                      child: CircularProgressIndicator(),
                    ), // Wrap CircularProgressIndicator with Center
              //WarLeaguePage(currentWarInfo: appState.currentWarInfo,),
              ManagementPage(),
            ];

            return Scaffold(
              appBar: CustomAppBar(user: appState.user!),
              body: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: widgetOptions,
              ),
              bottomNavigationBar: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                backgroundColor: Theme.of(context).colorScheme.surface,
                items: <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard),
                    label:
                        AppLocalizations.of(context)?.dashboard ?? 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.shield),
                    label: AppLocalizations.of(context)?.clan ?? 'Clan',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(
                        CustomIcons.swordCross), // Example icon for War/League
                    label:
                        AppLocalizations.of(context)?.warLeague ?? 'War/League',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings),
                    label: AppLocalizations.of(context)?.management ??
                        'Management',
                  ),
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: Theme.of(context).colorScheme.primary,
                unselectedItemColor: Theme.of(context).colorScheme.secondary,
                showUnselectedLabels: true,
                onTap: _onItemTapped,
              ),
            );
          }
        });
  }
}
