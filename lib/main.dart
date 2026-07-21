import 'dart:async';
import 'package:clashkingapp/core/config/app_feature_flags.dart';
import 'package:clashkingapp/core/config/observability_config.dart';
import 'package:clashkingapp/core/services/bookmark_service.dart';
import 'package:clashkingapp/core/services/error_reporter.dart';
import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/core/services/player_card_preferences_service.dart';
import 'package:clashkingapp/core/services/push_notification_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:clashkingapp/core/services/token_service.dart';
import 'package:clashkingapp/features/auth/data/user_service.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:clashkingapp/features/stats/presentation/stats_provider.dart';
import 'package:clashkingapp/core/services/android_workmanager_service.dart';
import 'package:clashkingapp/core/services/war_widget_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/core/app/my_app.dart';
import 'package:home_widget/home_widget.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
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

// CallbackDispatcher for background execution (Android only)
@pragma('vm:entry-point')
void callbackDispatcher() {
  AndroidWorkmanagerService.instance.executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await _initializeObservabilityForCurrentIsolate();

      // Handle different background tasks
      if (task == 'simplePeriodicTask') {
        if (!await WarWidgetSyncService.areWarWidgetsEnabled()) {
          DebugUtils.debugInfo('War widget background refresh skipped.');
          return Future.value(true);
        }
        // Regular periodic widget update
        await const WarWidgetSyncService().updateWarWidget();
      } else if (task == 'refreshWarWidget') {
        if (!await WarWidgetSyncService.areWarWidgetsEnabled()) {
          DebugUtils.debugInfo('War widget manual refresh skipped.');
          return Future.value(true);
        }
        // Manual refresh from widget button
        await WarWidgetService.handleWidgetRefresh();
      }

      return Future.value(true);
    } catch (e, stackTrace) {
      ErrorReporter.captureException(
        e,
        stackTrace: stackTrace,
        operation: 'widget.background',
      );
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
        ErrorReporter.captureException(err, operation: 'deep_link.running');
      });
    },
    onError: (err) {
      DebugUtils.debugError(" Deep link error: $err");
      ErrorReporter.captureException(err, operation: 'deep_link.stream');
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
            ErrorReporter.captureException(err, operation: 'deep_link.initial');
          });
        }
      })
      .catchError((err) {
        DebugUtils.debugError(" Initial deep link error: $err");
        ErrorReporter.captureException(err, operation: 'deep_link.initial');
      });
}

Future<void> main() async {
  // Initialize Flutter binding BEFORE Sentry
  WidgetsFlutterBinding.ensureInitialized();
  PushNotificationService.registerBackgroundHandler();

  if (!ObservabilityConfig.isEnabled) {
    await _startClashKingApp();
    return;
  }

  final packageInfo = await PackageInfo.fromPlatform();

  if (kIsWeb) {
    await SentryFlutter.init((options) {
      _configureObservabilityOptions(options, packageInfo);
    });
    await _startClashKingApp();
    return;
  }

  await SentryFlutter.init((options) {
    _configureObservabilityOptions(options, packageInfo);
  }, appRunner: _startClashKingApp);
}

Future<void> _initializeObservabilityForCurrentIsolate() async {
  if (!ObservabilityConfig.isEnabled || Sentry.isEnabled) return;

  final packageInfo = await PackageInfo.fromPlatform();
  await SentryFlutter.init((options) {
    _configureObservabilityOptions(options, packageInfo);
  });
}

void _configureObservabilityOptions(
  SentryFlutterOptions options,
  PackageInfo packageInfo,
) {
  options.dsn = ObservabilityConfig.dsn;
  options.environment = ObservabilityConfig.environment;
  options.release = '${packageInfo.packageName}@${packageInfo.version}';
  options.dist = packageInfo.buildNumber;
  options.debug = false;
  options.sendDefaultPii = false;
  options.tracesSampleRate = ObservabilityConfig.tracesSampleRate;
  options.replay.sessionSampleRate =
      ObservabilityConfig.replaySessionSampleRate;
  options.replay.onErrorSampleRate =
      ObservabilityConfig.replayOnErrorSampleRate;
}

Future<void> _startClashKingApp() async {
  // Pre-warm the shared Flutter glass shader before first use.
  if (!kIsWeb) {
    await LiquidGlassWidgets.initialize();
  }
  final appState = MyAppState();
  if (!kIsWeb) {
    await appState.featureFlagsReady;
  }

  final warWidgetsEnabled = appState.isFeatureEnabled(
    AppFeatureFlags.warWidgets,
  );
  if (!kIsWeb && warWidgetsEnabled) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await HomeWidget.setAppGroupId('group.com.clashking.apps');
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      await AndroidWorkmanagerService.instance.initialize(callbackDispatcher);
      appState.registerWarWidgetRefreshIfEnabled();
    }
    // Initialize war widget service for background callbacks
    WarWidgetService.initialize();
    // Override with the app-level callback (handles widget taps → WarWidgetSyncService)
    HomeWidget.registerInteractivityCallback(backgroundCallback);
  }

  if (kIsWeb) {
    unawaited(
      GameDataService.loadGameData().then(
        (_) => DebugUtils.debugSuccess("GameDataService OK"),
      ),
    );
  } else {
    await Future.wait([
      GameDataService.loadGameData().then(
        (_) => DebugUtils.debugSuccess("GameDataService OK"),
      ),
    ]);
  }

  FlutterNativeSplash.remove();

  // Initialize deep link listening
  _initializeDeepLinks();

  runApp(
    LiquidGlassWidgets.wrap(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeNotifier()),
          ChangeNotifierProvider.value(value: appState),
          ChangeNotifierProvider(create: (_) => AuthService()),
          ChangeNotifierProvider(create: (_) => CocAccountService()),
          ChangeNotifierProvider(create: (_) => PlayerService()),
          ChangeNotifierProvider(create: (_) => ClanService()),
          ChangeNotifierProvider(create: (_) => WarCwlService()),
          ChangeNotifierProvider(create: (_) => BookmarkService()),
          ChangeNotifierProvider(create: (_) => PlayerCardPreferencesService()),
          ChangeNotifierProvider(create: (_) => StatsProvider()),
          Provider.value(value: ApiService.shared),
          Provider(create: (_) => UserService()),
          Provider.value(value: TokenService.shared),
        ],
        child: MyApp(),
      ),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    FlutterNativeSplash.remove();
  });
}
