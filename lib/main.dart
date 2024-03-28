import 'package:clashkingapp/api/user_data.dart';
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
import 'package:clashkingapp/main_pages/login_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clashkingapp/global_keys.dart';

Future main() async {
  await dotenv.load(); // Charge le fichier .env
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class StartupWidget extends StatefulWidget {
  @override
  _StartupWidgetState createState() => _StartupWidgetState();
}

class _StartupWidgetState extends State<StartupWidget> {
  @override
  void initState() {
    super.initState();
    _checkTokenValidity();
  }

  Future<void> _checkTokenValidity() async {
    final isValid = await isTokenValid();
    if (isValid) {
      // Si le token est valide, naviguez vers MyHomePage
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => MyHomePage()));
    } else {
      // Si le token n'est pas valide, naviguez vers LoginPage
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => LoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Affichez un indicateur de chargement pendant la vérification
    return Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: Consumer<MyAppState>(
        builder: (context, appState, child) {
          return FutureBuilder(
            future: appState.initializeUserFuture, // Use the stored Future here
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return MaterialApp(
                    home: Scaffold(
                        body: Center(child: CircularProgressIndicator())));
              } else if (snapshot.hasError) {
                return MaterialApp(
                    home: Scaffold(
                        body: Center(child: Text('Error initializing user'))));
              } else {
                return MaterialApp(
                  navigatorKey: globalNavigatorKey,
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
                      onSecondary: Color(0xFFFFFFFF), // Text color on top of secondary color
                      onBackground: Color(0xFF000000), // Typically black text for readibility
                      onSurface: Color(0xFF000000), // Typically black text for readibility
                      onError: Color(0xFFFFFFFF), // White text on top of error color
                    ),
                    textTheme: TextTheme(
                      bodyLarge: TextStyle(color: Colors.black, fontSize: 16, fontFamily: 'Roboto', fontWeight: FontWeight.w500),
                      bodyMedium: TextStyle(color: Colors.black, fontSize: 14, fontFamily: 'Roboto', fontWeight: FontWeight.w500),
                      bodySmall: TextStyle(color: Colors.black, fontSize: 12, fontFamily: 'Roboto', fontWeight: FontWeight.w500),
                      titleLarge: TextStyle(color: Colors.black, fontSize: 24, fontFamily: 'Roboto', fontWeight: FontWeight.w500),
                      titleMedium: TextStyle(color: Colors.black, fontSize: 20, fontFamily: 'Roboto', fontWeight: FontWeight.w500),
                      titleSmall: TextStyle(color: Colors.black, fontSize: 18, fontFamily: 'Roboto', fontWeight: FontWeight.w500),
                      labelLarge: TextStyle(color: Colors.black, fontSize: 16, fontFamily: 'Roboto', fontWeight: FontWeight.w500),
                      labelMedium: TextStyle(color: Colors.black, fontSize: 14, fontFamily: 'Roboto', fontWeight: FontWeight.w500),
                      labelSmall: TextStyle(color: Colors.black, fontSize: 12, fontFamily: 'Roboto', fontWeight: FontWeight.w500),
                    ),
                  ),
                  home: StartupWidget(),
                );
              }
            },
          );
        },
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  PlayerAccounts? playerAccounts;
  PlayerStats? playerStats;
  ClanInfo? clanInfo; 
  CurrentWarInfo? currentWarInfo; 
  DiscordUser? user; 
  Future<void>? initializeUserFuture;
  ValueNotifier<String?> selectedTag = ValueNotifier<String?>(null);

  MyAppState() {
    initializeUserFuture = initializeUser().then((_) async {
    await fetchPlayerAccounts(user!.tags);
    playerStats = playerAccounts!.items.first;
    print("playerAccounts: $playerAccounts");
    selectedTag.value = user!.tags.first;
    selectedTag.addListener(_reloadData);
  });

}

  void _reloadData() async {
    if (selectedTag.value != null) {
      playerStats = playerAccounts!.items.firstWhere((element) => element.tag == selectedTag.value);
      notifyListeners();
    }
  }

  // Assume this method exists and fetches player stats correctly
  Future<void> fetchPlayerAccounts(List<String> tags) async {
    try {
      playerAccounts = await PlayerService().fetchPlayerAccounts(tags);
      notifyListeners(); // Notify listeners to rebuild widgets that depend on playerStats.
    } catch (e, s) {
      // Handle the error, maybe log it or show a user-friendly message
      print("Error fetching player stats: $e");
      print("Stack trace: $s");
    }
  }

  // Assume this method exists and fetches clan correctly
  Future<void> fetchClanInfo(String tag) async {
    try {
      clanInfo = await ClanService().fetchClanInfo(tag);
      notifyListeners(); // Notify listeners to rebuild widgets that depend on clanInfo.
    } catch (e, s) {
      // Handle the error, maybe log it or show a user-friendly message
      print("Error fetching clan info: $e");
      print("Stack trace: $s");
    }
  }

  // Assume this method exists and fetches current war correctly
  Future<void> fetchCurrentWarInfo(String tag) async {
    try {
      currentWarInfo = await CurrentWarService().fetchCurrentWarInfo(tag);
      notifyListeners(); // Notify listeners to rebuild widgets that depend on currentWarInfo.
    } catch (e, s) {
      // Handle the error, maybe log it or show a user-friendly message
      print("Error fetching current war info: $e");
      print("Stack trace: $s");
    }
  }

  Future<void> initializeUser() async {
    bool validToken = await isTokenValid();
    if (validToken) {
      print("Token valide.");
      final accessToken = await getAccessToken();
      if (accessToken != null) {
        print("Access token : $accessToken");
        user = await fetchDiscordUser(accessToken);
        print("User: $user");
        notifyListeners();
      }
    } else {
      print("Token non valide ou absent.");
    }
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

Future<bool> isTokenValid() async {
  final prefs = await SharedPreferences.getInstance();
  String? expirationDateString = prefs.getString('expiration_date');

  if (expirationDateString != null) {
    DateTime expirationDate = DateTime.parse(expirationDateString);
    return DateTime.now().isBefore(expirationDate);
  }

  return false;
}

Future<String?> getAccessToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('access_token');
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
      appState.playerAccounts != null
          ? DashboardPage(
              playerStats: appState.playerStats!, user: appState.user!)
          : Center(
              child:
                  CircularProgressIndicator()), // Wrap CircularProgressIndicator with Center
      appState.clanInfo != null
          ? ClanInfoPage(clanInfo: appState.clanInfo!, user: appState.user!)
          : Center(
              child:
                  CircularProgressIndicator()), // Wrap CircularProgressIndicator with Center
      appState.currentWarInfo != null
          ? CurrentWarInfoPage(currentWarInfo: appState.currentWarInfo!)
          : Center(
              child:
                  CircularProgressIndicator()), // Wrap CircularProgressIndicator with Center
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
