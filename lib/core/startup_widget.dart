import 'package:flutter/material.dart';
import 'package:clashkingapp/main_pages/login_page.dart';
import 'package:clashkingapp/core/functions.dart';
import 'package:clashkingapp/core/my_home_page.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/core/my_app.dart';


class StartupWidget extends StatefulWidget {
  @override
  StartupWidgetState createState() => StartupWidgetState();
}

class StartupWidgetState extends State<StartupWidget> {
  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

Future<void> _initializeUser() async {
  final appState = Provider.of<MyAppState>(context, listen: false);
  await appState.initializeUser();

  if (appState.user != null) {
    appState.selectedTag.value = appState.user!.tags.first;
    appState.selectedTag.addListener(appState.reloadData);
    print("User1: ${appState.user}");
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MyHomePage()));
  } else {
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => LoginPage()));
  }
}


  Future<void> _checkTokenValidity() async {
    final isValid = await isTokenValid();
    if (!mounted) return;

    if (isValid) {
      // If the token is valid, navigate to MyHomePage
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => MyHomePage()));
    } else {
      // If the token is not valid, navigate to LoginPage
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