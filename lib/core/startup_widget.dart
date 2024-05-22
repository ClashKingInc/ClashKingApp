import 'package:flutter/material.dart';
import 'package:clashkingapp/main_pages/login_page.dart';
import 'package:clashkingapp/core/my_home_page.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/core/my_app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StartupWidget extends StatefulWidget {
  @override
  StartupWidgetState createState() => StartupWidgetState();
}

class StartupWidgetState extends State<StartupWidget> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final appState = Provider.of<MyAppState>(context, listen: false);

    // Check if a user has been registered yet
    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString('user_type');

    // If yes and the user is a guest, initialize the guest user
    if (userType == "guest") {
      await appState.initializeGuestUser(); // Initialize guest user
      if (mounted) {
        Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (_) => MyHomePage()));
      }
    }
    // If yes and the user is a discord user, initialize the discord user
    else if (userType == "discord") {
      await appState.initializeDiscordUser(); // Initialize discord user
      if (mounted) {
        Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (_) => MyHomePage()));
      }
    }
    // If no user has been registered yet, redirect to the login page
    else {
      if (mounted) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => LoginPage(appState: appState)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator while the app is initializing
    return Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
