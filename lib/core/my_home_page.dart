import 'package:clashkingapp/custom_icons_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/main_pages/dashboard_page.dart';
import 'package:clashkingapp/main_pages/clan_page.dart';
import 'package:clashkingapp/main_pages/war_league_page.dart';
import 'package:clashkingapp/main_pages/management_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/core/my_app.dart';

class MyHomePage extends StatefulWidget {
  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  Future<void>? _initializeAccountsFuture;

  @override
  void initState() {
    super.initState();
    _initializeAccountsFuture = _initializeAccounts();
  }

  Future<void> _initializeAccounts() async {
    final appState = Provider.of<MyAppState>(context, listen: false);
    await appState.fetchPlayerAccounts(appState.user!);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
                      playerStats: appState.playerStats!, user: appState.user!)
                  : Center(
                      child:
                          CircularProgressIndicator()), // Wrap CircularProgressIndicator with Center
              appState.clanInfo != null && appState.user != null
                  ? ClanInfoPage(
                      clanInfo: appState.clanInfo!, user: appState.user!)
                  : Center(
                      child:
                          CircularProgressIndicator()), // Wrap CircularProgressIndicator with Center
              appState.user != null && appState.playerStats != null
                ? CurrentWarInfoPage(user: appState.user!, playerStats: appState.playerStats!)
                : Center(
                    child: CircularProgressIndicator(),
                  ), // Wrap CircularProgressIndicator with Center
              //WarLeaguePage(currentWarInfo: appState.currentWarInfo,),
              ManagementPage(),
            ];

            return Scaffold(
              body: Center(
                child: IndexedStack(
                  index: _selectedIndex,
                  children:
                      widgetOptions, // Use widgetOptions here instead of _widgetOptions
                ),
              ),
              bottomNavigationBar: BottomNavigationBar(
                type: BottomNavigationBarType.fixed, 
                backgroundColor: Colors.white, 
                items: <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard),
                    label: AppLocalizations.of(context)?.dashboard ?? 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.shield),
                    label: AppLocalizations.of(context)?.clan ?? 'Clan',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(
                        CustomIcons.swordCross), // Example icon for War/League
                    label: AppLocalizations.of(context)?.warLeague ?? 'War/League',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings),
                    label: AppLocalizations.of(context)?.management ?? 'Management',
                  ),
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: Color(
                    0xFFC98910), // Using the primary color we picked from the logo
                unselectedItemColor: Color(
                    0xFF9B1F28), // A color that complements the primary color
                showUnselectedLabels: true,
                onTap: _onItemTapped,
              ),
            );
          }
        });
  }
}
