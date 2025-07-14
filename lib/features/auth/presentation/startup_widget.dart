import 'package:clashkingapp/features/auth/presentation/maintenance_page.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/coc_accounts/presentation/coc_account_management_page.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/features/auth/presentation/login_page.dart';
import 'package:clashkingapp/core/app/my_home_page.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:clashkingapp/common/widgets/loading/app_loading_screen.dart';
import 'package:clashkingapp/common/widgets/error/error_page.dart';
import 'dart:io';

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

  // Helper function to determine if an error is network-related
  bool _isNetworkError(dynamic error) {
    if (error is SocketException) {
      return true;
    }
    if (error is Exception) {
      String errorString = error.toString().toLowerCase();
      return errorString.contains('network') ||
             errorString.contains('connection') ||
             errorString.contains('hostname') ||
             errorString.contains('socket') ||
             errorString.contains('timeout') ||
             errorString.contains('no address');
    }
    return false;
  }

  Future<void> _initAuth() async {
    final authService = context.read<AuthService>();
    
    try {
      await authService.initializeAuth();
    } catch (e) {
      // Handle network errors during authentication
      if (mounted && _isNetworkError(e)) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ErrorPage(
              isNetworkError: true,
              onRetry: () async {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => StartupWidget()),
                );
              },
            ),
          ),
        );
        return;
      }
      // For non-network errors, continue with normal flow
    }

    if (!mounted) return;

    if (authService.isAuthenticated) {
      final cocService = context.read<CocAccountService>();
      final playerService = context.read<PlayerService>();
      final clanService = context.read<ClanService>();
      final warService = context.read<WarCwlService>();
      try {
        // Load the selected tag from SharedPreferences first
        await cocService.loadSelectedTag();
        await cocService.loadApiData(playerService, clanService, warService);
      } catch (e) {
        if (mounted) {
          if (e.toString().contains("503") || e.toString().contains("500")) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => MaintenanceScreen()),
            );
            return;
          } else if (_isNetworkError(e)) {
            // Show network error page for data loading failures
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => ErrorPage(
                  isNetworkError: true,
                  onRetry: () async {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => StartupWidget()),
                    );
                  },
                ),
              ),
            );
            return;
          } else {
            // Handle other errors (e.g., network issues)
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text("Error"),
                content: Text("An error occurred: $e"),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text("OK"),
                  ),
                ],
              ),
            );
          }
        }
      }
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
        ? const AppLoadingScreen()
        : const SizedBox.shrink();
  }
}
