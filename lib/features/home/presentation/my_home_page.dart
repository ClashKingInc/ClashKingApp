import 'package:clashkingapp/core/theme/custom_icons_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/main_pages/dashboard_page/dashboard_page.dart';
import 'package:clashkingapp/main_pages/clan_page/clan_page.dart';
import 'package:clashkingapp/main_pages/wars_league_page/war_league_page.dart';
import 'package:clashkingapp/main_pages/tools_page/tools_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/common/widgets/app_bar/app_bar.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';

class MyHomePage extends StatefulWidget {
  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _selectedIndex = index);
  }

  void _onItemTapped(int index) {
    if (_pageController.hasClients) {
      _pageController.jumpToPage(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          //DashboardPage(),
          //ClanInfoPage(),
          //CurrentWarInfoPage(),
          ToolsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.tertiary,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: AppLocalizations.of(context)?.dashboard ?? 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shield),
            label: AppLocalizations.of(context)?.clan ?? 'Clan',
          ),
          BottomNavigationBarItem(
            icon: Icon(CustomIcons.swordCross),
            label: AppLocalizations.of(context)?.warLeague ?? 'War/League',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: AppLocalizations.of(context)?.tools ?? 'Tools',
          ),
        ],
        currentIndex: _selectedIndex,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }
}
