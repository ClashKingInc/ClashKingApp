import 'package:clash_king_app/custom_icons_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:english_words/english_words.dart';
import 'package:clash_king_app/pages/dashboard_page.dart';
import 'package:clash_king_app/pages/clan_page.dart';
import 'package:clash_king_app/pages/war_league_page.dart';
import 'package:clash_king_app/pages/management_page.dart';
import 'package:clash_king_app/api/player_stats.dart';
import 'package:clash_king_app/api/player_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';


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
  var current = WordPair.random();
  PlayerStats? playerStats; // Add this line

  MyAppState() {
    fetchPlayerStats();
  }

  void getNext() {
    current = WordPair.random();
    notifyListeners();
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
    : CircularProgressIndicator(), // Show a loading spinner when playerStats is null
      ClanPage(),
      WarLeaguePage(),
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
