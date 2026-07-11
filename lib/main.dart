import 'dart:async';
import 'package:clashkingapp/core/services/bookmark_service.dart';
import 'package:clashkingapp/core/services/player_card_preferences_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:clashkingapp/core/services/token_service.dart';
import 'package:clashkingapp/features/auth/data/user_service.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:clashkingapp/core/services/android_workmanager_service.dart';
import 'package:clashkingapp/core/services/war_widget_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/core/app/my_app.dart';
import 'package:home_widget/home_widget.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/core/app/my_app_state.dart';
import 'package:clashkingapp/core/theme/theme_notifier.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter/foundation.dart';
import 'package:clashkingapp/widgets/war_widget.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';
import 'package:app_links/app_links.dart';
import 'package:clashkingapp/core/utils/deep_link_handler.dart';
import 'package:clashkingapp/core/config/observability_config.dart';
import 'package:clashkingapp/core/services/error_reporter.dart';

// CallbackDispatcher for background execution (Android only)
@pragma('vm:entry-point')
void callbackDispatcher() {
  AndroidWorkmanagerService.instance.executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();

      // Handle different background tasks
      if (task == 'simplePeriodicTask') {
        // Regular periodic widget update
        await const WarWidgetSyncService().updateWarWidget();
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
  appLinks.uriLinkStream.listen(
    (uri) {
      DebugUtils.debugInfo("🔗 Deep link received (running): $uri");
      DeepLinkHandler.queueDeepLink(uri);
      DeepLinkHandler.tryHandlePendingDeepLink().catchError((err) {
        DebugUtils.debugError(" Deep link handling error: $err");
        ErrorReporter.captureException(err);
      });
    },
    onError: (err) {
      DebugUtils.debugError(" Deep link error: $err");
    },
  );

  // Handle initial deep link when app starts from a deep link
  appLinks
      .getInitialLink()
      .then((uri) {
        if (uri != null) {
          DebugUtils.debugInfo("🔗 Initial deep link: $uri");
          DeepLinkHandler.queueDeepLink(uri);
          DeepLinkHandler.tryHandlePendingDeepLink().catchError((err) {
            DebugUtils.debugError(" Deep link handling error: $err");
            ErrorReporter.captureException(err);
          });
        }
      })
      .catchError((err) {
        DebugUtils.debugError(" Initial deep link error: $err");
      });
}

Future<void> main() async {
  // Initialize Flutter binding BEFORE Sentry
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-warm the shared Flutter glass shader before first use.
  await LiquidGlassWidgets.initialize();

  await SentryFlutter.init(
    (options) {
      options.dsn = ApiService.sentryDsn;
      options.tracesSampleRate = ObservabilityConfig.tracesSampleRate;
      options.debug = false;
      options.replay.sessionSampleRate =
          ObservabilityConfig.replaySessionSampleRate;
      options.replay.onErrorSampleRate =
          ObservabilityConfig.replayErrorSampleRate;
    },
    appRunner: () async {
      if (!kIsWeb) {
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          await HomeWidget.setAppGroupId('group.com.clashking.apps');
        }
        if (defaultTargetPlatform == TargetPlatform.android) {
          await AndroidWorkmanagerService.instance.initialize(
            callbackDispatcher,
          );
        }
        // Initialize war widget service for background callbacks
        WarWidgetService.initialize();
        // Override with the app-level callback (handles widget taps → WarWidgetSyncService)
        HomeWidget.registerInteractivityCallback(backgroundCallback);
      }

      FlutterNativeSplash.remove();

      // Initialize deep link listening
      _initializeDeepLinks();

      runApp(
        LiquidGlassWidgets.wrap(
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ThemeNotifier()),
              ChangeNotifierProvider(create: (_) => MyAppState()),
              ChangeNotifierProvider(create: (_) => AuthService()),
              ChangeNotifierProvider(create: (_) => CocAccountService()),
              ChangeNotifierProvider(create: (_) => PlayerService()),
              ChangeNotifierProvider(create: (_) => ClanService()),
              ChangeNotifierProvider(create: (_) => WarCwlService()),
              ChangeNotifierProvider(create: (_) => BookmarkService()),
              ChangeNotifierProvider(
                create: (_) => PlayerCardPreferencesService(),
              ),
              Provider.value(value: ApiService.shared),
              Provider(create: (_) => UserService()),
              Provider.value(value: TokenService.shared),
            ],
            child: MyApp(),
          ),
        ),
      );
    },
  );
}
