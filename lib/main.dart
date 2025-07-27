import 'dart:async';
import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:clashkingapp/core/services/token_service.dart';
import 'package:clashkingapp/features/auth/data/user_service.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/core/app/my_app.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:clashkingapp/core/app/my_app_state.dart';
import 'package:clashkingapp/core/theme/theme_notifier.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter/foundation.dart';
import 'package:clashkingapp/widgets/war_widget.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';
import 'package:app_links/app_links.dart';
import 'package:clashkingapp/core/utils/deep_link_handler.dart';
import 'package:clashkingapp/core/constants/global_keys.dart';

// CallbackDispatcher for background execution (Android only)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await ApiService.loadConfig();
      
      // Handle different background tasks
      if (task == 'simplePeriodicTask') {
        // Regular periodic widget update
        final myAppState = MyAppState();
        await myAppState.updateWarWidget();
      } else if (task == 'refreshWarWidget') {
        // Manual refresh from widget button
        await WarWidgetService.handleWidgetRefresh();
      }
      
      return Future.value(true);
    } catch (e) {
      DebugUtils.debugError(" Background task error: $e");
      return Future.value(false);
    }
  });
}

/// Initialize deep link listening for clashking:// URLs
void _initializeDeepLinks() {
  if (kIsWeb) {
    // Web doesn't support deep links in the same way
    return;
  }
  
  final appLinks = AppLinks();
  
  // Handle deep links when app is already running
  appLinks.uriLinkStream.listen((uri) {
    DebugUtils.debugInfo("🔗 Deep link received (running): $uri");
    _handleDeepLink(uri);
  }, onError: (err) {
    DebugUtils.debugError(" Deep link error: $err");
  });
  
  // Handle initial deep link when app starts from a deep link
  appLinks.getInitialLink().then((uri) {
    if (uri != null) {
      DebugUtils.debugInfo("🔗 Initial deep link: $uri");
      // Delay handling to ensure app is fully initialized
      Future.delayed(Duration(milliseconds: 500), () {
        _handleDeepLink(uri);
      });
    }
  }).catchError((err) {
    DebugUtils.debugError(" Initial deep link error: $err");
  });
}

/// Handle deep link with proper context checking
void _handleDeepLink(Uri uri) {
  // Ensure we have a valid navigation context
  final context = globalNavigatorKey.currentContext;
  if (context != null) {
    DeepLinkHandler.handleDeepLink(context, uri);
  } else {
    // If no context yet, retry after a short delay
    Future.delayed(Duration(milliseconds: 200), () {
      final retryContext = globalNavigatorKey.currentContext;
      if (retryContext != null && retryContext.mounted) {
        DeepLinkHandler.handleDeepLink(retryContext, uri);
      } else {
        DebugUtils.debugError(" No navigation context available for deep link: $uri");
      }
    });
  }
}

Future<void> main() async {
  // Initialize Flutter binding BEFORE Sentry
  WidgetsFlutterBinding.ensureInitialized();

  // Load config from backend first
  await ApiService.loadConfig();

  await SentryFlutter.init(
    (options) {
      options.dsn = ApiService.sentryDsn ?? '';
      options.tracesSampleRate = 1.0;
      options.debug = false;
      options.replay.sessionSampleRate = 1.0;
      options.replay.onErrorSampleRate = 1.0;
    },
    appRunner: () async {

      if (!kIsWeb) {
        Workmanager().initialize(callbackDispatcher);
        // Initialize war widget service for background callbacks
        WarWidgetService.initialize();
      }

      await Future.wait([
        GameDataService.loadGameData().then((_) => DebugUtils.debugSuccess("GameDataService OK")),
      ]);

      FlutterNativeSplash.remove();
      
      // Initialize deep link listening
      _initializeDeepLinks();
      
      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeNotifier()),
            ChangeNotifierProvider(create: (_) => MyAppState()),
            ChangeNotifierProvider(create: (_) => AuthService()),
            ChangeNotifierProvider(create: (_) => CocAccountService()),
            ChangeNotifierProvider(create: (_) => PlayerService()),
            ChangeNotifierProvider(create: (_) => ClanService()),
            ChangeNotifierProvider(create: (_) => WarCwlService()),
            Provider(create: (_) => ApiService()),
            Provider(create: (_) => UserService()),
            Provider(create: (_) => TokenService()),
          ],
          child: MyApp(),
        ),
      );
    },
  );
}

