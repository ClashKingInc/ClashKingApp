import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/coc_accounts/presentation/add_coc_account_page.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/features/auth/presentation/login_page.dart';
import 'package:clashkingapp/core/app/my_home_page.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';

class StartupWidget extends StatefulWidget {
  @override
  StartupWidgetState createState() => StartupWidgetState();
}

class StartupWidgetState extends State<StartupWidget> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    final authService = context.read<AuthService>();
    await authService.initializeAuth();

    if (!mounted) return;

    if (authService.isAuthenticated) {
      final cocService = context.read<CocAccountService>();
      final playerService = context.read<PlayerService>();
      final clanService = context.read<ClanService>();
      final warService = context.read<WarCwlService>();
      await cocService.loadApiData(playerService, clanService, warService);
    }

    setState(() {
      _isInitializing = false;
    });

    _navigateToNextScreen(authService);
  }

  void _navigateToNextScreen(AuthService authService) {
    Future.microtask(() {
      Widget nextPage;
      if (authService.isAuthenticated && mounted) {
        if (context.read<CocAccountService>().cocAccounts.isNotEmpty) {
          // ✅ User connected and has CoC account → Go to home page
          nextPage = MyHomePage();
        } else {
          // ❌ No account → Go to add account page
          nextPage = AddCocAccountPage();
        }
      } else {
        // ❌ User not connected → Go to login page
        nextPage = LoginPage();
      }
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => nextPage),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isInitializing
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : const SizedBox.shrink();
  }
}
