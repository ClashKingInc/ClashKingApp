import 'package:flutter/material.dart';
import 'package:clashkingapp/main_pages/login_page.dart';
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
      if (mounted) {
        Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (_) => MyHomePage()));
      }
    } else {
      if (mounted) {
        Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (_) => LoginPage()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Affichez un indicateur de chargement pendant la vérification
    return Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
