import 'package:clashkingapp/custom_icons_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/main_pages/dashboard_page.dart';
import 'package:clashkingapp/main_pages/clan_page.dart';
import 'package:clashkingapp/main_pages/current_war_page.dart';
import 'package:clashkingapp/main_pages/management_page.dart';
import 'package:clashkingapp/api/player_info.dart';
import 'package:clashkingapp/api/player_service.dart';
import 'package:clashkingapp/api/clan_info.dart';
import 'package:clashkingapp/api/clan_service.dart';
import 'package:clashkingapp/api/current_war_info.dart';
import 'package:clashkingapp/api/current_war_service.dart';


Future main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'ClashKing',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Color(0xFFC98910), // primary color as the seed
            primary: Color(0xFFC98910),
            secondary: Color(0xFF9B1F28),
            background: Color(0xFFFFFFFF),
            surface: Color(0xFFFFF8E1),
            error: Color(0xFFB00020),
            onPrimary: Color(0xFFFFFFFF), // Text color on top of primary color
            onSecondary:
                Color(0xFFFFFFFF), // Text color on top of secondary color
            onBackground:
                Color(0xFF000000), // Typically black text for readibility
            onSurface:
                Color(0xFF000000), // Typically black text for readibility
            onError: Color(0xFFFFFFFF), // White text on top of error color
          ),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  PlayerStats? playerStats; // Add this line
  ClanInfo? clanInfo; // Add this line 
  CurrentWarInfo? currentWarInfo; // Add this line

  MyAppState() {
    fetchPlayerStats();
    fetchClanInfo();
    fetchCurrentWarInfo();
  }

  // Assume this method exists and fetches player stats correctly
  Future<void> fetchPlayerStats() async {
    try {
      playerStats = await PlayerService().fetchPlayerStats();
      notifyListeners(); // Notify listeners to rebuild widgets that depend on playerStats.
    } catch (e, s) {
      // Handle the error, maybe log it or show a user-friendly message
      print("Error fetching player stats: $e");
      print("Stack trace: $s");
    }
  }

    // Assume this method exists and fetches clan correctly
  Future<void> fetchClanInfo() async {
    try {
      clanInfo = await ClanService().fetchClanInfo();
      notifyListeners(); // Notify listeners to rebuild widgets that depend on clanInfo.
    } catch (e, s) {
      // Handle the error, maybe log it or show a user-friendly message
      print("Error fetching clan info: $e");
      print("Stack trace: $s");
    }
  }

    // Assume this method exists and fetches current war correctly
  Future<void> fetchCurrentWarInfo() async {
    try {
      currentWarInfo = await CurrentWarService().fetchCurrentWarInfo();
      notifyListeners(); // Notify listeners to rebuild widgets that depend on currentWarInfo.
    } catch (e, s) {
      // Handle the error, maybe log it or show a user-friendly message
      print("Error fetching current war info: $e");
      print("Stack trace: $s");
    }
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    var appState = Provider.of<MyAppState>(context);

    List<Widget> widgetOptions = [
      appState.playerStats != null
    ? DashboardPage(playerStats: appState.playerStats!)
    : CircularProgressIndicator(), // Show a loading spinner when playerStats is nul
      appState.clanInfo != null
    ?  ClanInfoPage(clanInfo: appState.clanInfo!)
    : CircularProgressIndicator(),
      appState.currentWarInfo != null
    ? CurrentWarInfoPage(currentWarInfo: appState.currentWarInfo!)
    : CircularProgressIndicator(),
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
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shield),
            label: 'Clans',
          ),
          BottomNavigationBarItem(
            icon: Icon(CustomIcons.sword_cross), // Example icon for War/League
            label: 'War/League',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Management',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Color(
            0xFFC98910), // Using the primary color we picked from the logo
        unselectedItemColor:
            Color(0xFF9B1F28), // A color that complements the primary color
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }
}
