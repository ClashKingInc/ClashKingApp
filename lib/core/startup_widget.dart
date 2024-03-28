import 'package:flutter/material.dart';
import 'package:clashkingapp/main_pages/login_page.dart';
import 'package:clashkingapp/core/functions.dart';
import 'package:clashkingapp/core/my_home_page.dart';


class StartupWidget extends StatefulWidget {
  @override
  StartupWidgetState createState() => StartupWidgetState();
}

class StartupWidgetState extends State<StartupWidget> {
  @override
  void initState() {
    super.initState();
    _checkTokenValidity();
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