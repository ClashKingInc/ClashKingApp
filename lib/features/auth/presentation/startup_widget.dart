import 'package:clashkingapp/features/auth/presentation/maintenance_page.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/account_bootstrap_service.dart';
import 'package:clashkingapp/core/services/bookmark_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/coc_accounts/presentation/coc_account_management_page.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/features/auth/presentation/login_page.dart';
import 'package:clashkingapp/core/app/my_home_page.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:clashkingapp/core/utils/network_error_utils.dart';
import 'package:clashkingapp/common/widgets/loading/app_loading_screen.dart';
import 'package:clashkingapp/common/widgets/error/error_page.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';
import 'package:clashkingapp/core/services/game_data_service.dart';

class StartupWidget extends StatefulWidget {
  const StartupWidget({super.key});

  @override
  StartupWidgetState createState() => StartupWidgetState();
}

class StartupWidgetState extends State<StartupWidget> {
  static const _accountBootstrap = AccountBootstrapService();
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initAuth());
  }

  Future<void> _initAuth() async {
    final authService = context.read<AuthService>();
    final gameDataLoad = GameDataService.loadGameData();

    try {
      await Future.wait([authService.initializeAuth(), gameDataLoad]);
    } catch (e) {
      if (isNetworkError(e) || isMaintenanceError(e)) {
        if (mounted) _showInitializationFailure(e);
        return;
      }
      // Auth failure (expired/revoked session): initializeAuth() already cleared
      // tokens and set isAuthenticated=false — fall through so _navigateToNextScreen
      // redirects to LoginPage instead of looping on ErrorPage.
    }

    if (!mounted) return;

    if (authService.canUseApp) {
      final cocService = context.read<CocAccountService>();
      final playerService = context.read<PlayerService>();
      final clanService = context.read<ClanService>();
      final warService = context.read<WarCwlService>();
      final bookmarkService = context.read<BookmarkService>();
      try {
        await _accountBootstrap.initialize(
          userId: authService.currentUser?.userId,
          cocAccounts: cocService,
          bookmarks: bookmarkService,
          players: playerService,
          clans: clanService,
          wars: warService,
        );
      } catch (e, stackTrace) {
        DebugUtils.debugError(" Startup data initialization failed: $e");
        DebugUtils.debugError(stackTrace.toString());
        if (mounted) {
          _showInitializationFailure(e);
        }
        return;
      }
    }

    setState(() {
      _isInitializing = false;
    });

    _navigateToNextScreen(authService);
  }

  void _showInitializationFailure(dynamic error) {
    if (!mounted) return;

    if (isMaintenanceError(error)) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MaintenanceScreen()),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ErrorPage(
          isNetworkError: isNetworkError(error),
          onRetry: () async {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => StartupWidget()),
            );
          },
        ),
      ),
    );
  }

  void _navigateToNextScreen(AuthService authService) {
    Future.microtask(() {
      Widget nextPage;
      if (authService.canUseApp && mounted) {
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
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => nextPage));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isInitializing ? const AppLoadingScreen() : const SizedBox.shrink();
  }
}
