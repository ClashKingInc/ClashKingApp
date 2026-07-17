import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clashkingapp/core/app/my_app_state.dart';
import 'package:clashkingapp/core/config/api_config.dart';
import 'package:clashkingapp/core/config/app_feature_flags.dart';
import 'package:clashkingapp/core/constants/global_keys.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/core/services/token_service.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';
import 'package:clashkingapp/common/widgets/dialogs/open_clash_dialog.dart';
import 'package:clashkingapp/firebase_options.dart';
import 'package:clashkingapp/features/pages/data/announcement_service.dart';
import 'package:clashkingapp/features/pages/data/announcement_story_cache_service.dart';
import 'package:clashkingapp/features/pages/presentation/announcement_story_dialog.dart';
import 'package:clashkingapp/features/pages/presentation/announcement_webview_page.dart';
import 'package:clashkingapp/features/pages/presentation/posts_page.dart';
import 'package:clashkingapp/features/pages/presentation/search_page.dart';
import 'package:clashkingapp/features/upgrade_tracker/presentation/upgrade_tracker_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    DebugUtils.debugInfo(
      'Push background message received: ${message.messageId}',
    );
  } catch (error, stackTrace) {
    await Sentry.captureException(error, stackTrace: stackTrace);
    DebugUtils.debugWarning('Push background handler skipped: $error');
  }
}

enum PushNotificationSetupState {
  unsupported,
  notConfigured,
  initializing,
  ready,
  permissionRequired,
  permissionDenied,
  tokenUnavailable,
}

class PushNotificationSetupResult {
  const PushNotificationSetupResult({
    required this.state,
    this.authorizationStatus,
    this.token,
    this.message,
  });

  final PushNotificationSetupState state;
  final AuthorizationStatus? authorizationStatus;
  final String? token;
  final String? message;

  bool get canReceivePush =>
      state == PushNotificationSetupState.ready && token != null;
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const _pushApiV2BaseOverride = String.fromEnvironment(
    'CK_PUSH_API_V2_BASE_URL',
  );

  static String get _pushEnvironment {
    if (_pushApiV2BaseOverride.isNotEmpty ||
        ApiConfig.environment == ApiEnvironment.local) {
      return 'sandbox';
    }
    return 'production';
  }

  static void registerBackgroundHandler() {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }
  }

  static const _deviceEndpoint = '/notifications/devices';
  static const _preferencesEndpoint = '/notifications/preferences';
  static const _tokenPrefsKey = 'push_fcm_token';
  static const _lastRegistrationPrefsKey = 'push_last_registration_token';
  static const _channelId = 'clashking_push';
  static const _channelName = 'ClashKing alerts';
  static const _channelDescription =
      'War, CWL, account, and ClashKing announcement alerts.';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  StreamSubscription<String>? _tokenRefreshSub;
  bool _initializing = false;
  bool _initialized = false;
  bool _localNotificationsReady = false;
  PushNotificationSetupResult _lastResult = const PushNotificationSetupResult(
    state: PushNotificationSetupState.notConfigured,
  );

  PushNotificationSetupResult get lastResult => _lastResult;

  Future<PushNotificationSetupResult> initialize({
    bool register = false,
  }) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return _setResult(
        const PushNotificationSetupResult(
          state: PushNotificationSetupState.unsupported,
          message: null,
        ),
      );
    }

    if (_initializing) {
      return _lastResult;
    }

    _initializing = true;
    _setResult(
      const PushNotificationSetupResult(
        state: PushNotificationSetupState.initializing,
      ),
    );

    try {
      await _ensureFirebaseInitialized();
      await _initializeLocalNotifications();
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );

      _bindMessageStreams();
      _initialized = true;

      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      if (!_hasDisplayPermission(settings.authorizationStatus)) {
        return _setResult(
          PushNotificationSetupResult(
            state: _permissionStateFor(settings.authorizationStatus),
            authorizationStatus: settings.authorizationStatus,
            message: null,
          ),
        );
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        return _setResult(
          const PushNotificationSetupResult(
            state: PushNotificationSetupState.tokenUnavailable,
            message: null,
          ),
        );
      }

      await _cacheToken(token);
      if (register) {
        unawaited(registerCurrentDeviceToken(token: token));
      }

      return _setResult(
        PushNotificationSetupResult(
          state: PushNotificationSetupState.ready,
          token: token,
        ),
      );
    } catch (error, stackTrace) {
      await Sentry.captureException(error, stackTrace: stackTrace);
      DebugUtils.debugWarning('Push notifications are not configured: $error');
      return _setResult(
        PushNotificationSetupResult(
          state: PushNotificationSetupState.notConfigured,
          message: error.toString(),
        ),
      );
    } finally {
      _initializing = false;
    }
  }

  Future<PushNotificationSetupResult> requestPermissionAndRegister() async {
    final initialized = _initialized
        ? _lastResult
        : await initialize(register: false);
    if (initialized.state == PushNotificationSetupState.notConfigured ||
        initialized.state == PushNotificationSetupState.unsupported) {
      return initialized;
    }

    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (Platform.isAndroid) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      }

      final resolvedSettings = await FirebaseMessaging.instance
          .getNotificationSettings();
      final authorizationStatus = resolvedSettings.authorizationStatus;

      if (!_hasDisplayPermission(authorizationStatus)) {
        return _setResult(
          PushNotificationSetupResult(
            state: _permissionStateFor(authorizationStatus),
            authorizationStatus: authorizationStatus,
            message: null,
          ),
        );
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        return _setResult(
          PushNotificationSetupResult(
            state: PushNotificationSetupState.tokenUnavailable,
            authorizationStatus: authorizationStatus,
            message: null,
          ),
        );
      }

      await _cacheToken(token);
      await registerCurrentDeviceToken(token: token);

      return _setResult(
        PushNotificationSetupResult(
          state: PushNotificationSetupState.ready,
          authorizationStatus: authorizationStatus,
          token: token,
        ),
      );
    } catch (error, stackTrace) {
      await Sentry.captureException(error, stackTrace: stackTrace);
      DebugUtils.debugError('Push permission/register failed: $error');
      return _setResult(
        PushNotificationSetupResult(
          state: PushNotificationSetupState.notConfigured,
          message: error.toString(),
        ),
      );
    }
  }

  Future<void> registerCurrentDeviceToken({String? token}) async {
    final resolvedToken = token ?? await cachedToken();
    if (resolvedToken == null || resolvedToken.isEmpty) {
      DebugUtils.debugWarning('Push registration skipped: no FCM token.');
      return;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final tokenService = TokenService();
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    final payload = <String, dynamic>{
      'token': resolvedToken,
      'device_id': await tokenService.getDeviceId(),
      'provider': 'fcm',
      'platform': Platform.operatingSystem,
      'environment': _pushEnvironment,
      'app_version': packageInfo.version,
      'build_number': packageInfo.buildNumber,
      'os_version': Platform.operatingSystemVersion,
      'device_model': await tokenService.getDeviceName(),
      'authorization_status': settings.authorizationStatus.name,
      'locale': PlatformDispatcher.instance.locale.toLanguageTag(),
      'timezone': DateTime.now().timeZoneName,
    };

    if (Platform.isIOS) {
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (apnsToken != null) {
        payload['apns_token'] = apnsToken;
      }
    }

    try {
      final url = _pushApiV2BaseOverride.isEmpty
          ? null
          : '$_pushApiV2BaseOverride$_deviceEndpoint';
      final response = await ApiService().postResponse(
        _deviceEndpoint,
        body: payload,
        requiresAuth: true,
        url: url,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastRegistrationPrefsKey, resolvedToken);
        DebugUtils.debugSuccess('Push device token registered.');
      } else {
        DebugUtils.debugWarning(
          'Push token registration failed: ${response.statusCode}',
        );
      }
    } catch (error, stackTrace) {
      // Backend endpoint may not exist yet; keep this non-fatal so local push
      // reception can be tested before server registration is wired.
      await Sentry.captureException(error, stackTrace: stackTrace);
      DebugUtils.debugWarning('Push token registration skipped: $error');
    }
  }

  Future<bool> savePreferences(Map<String, dynamic> preferences) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return false;
    final payload = <String, dynamic>{
      'device_id': await TokenService().getDeviceId(),
      'environment': _pushEnvironment,
      'locale': PlatformDispatcher.instance.locale.toLanguageTag(),
      'timezone': DateTime.now().timeZoneName,
      'enabled_types': <String>[],
      'war_attack_modes': <String>[],
      'event_types': <String>[],
      'reminder_timings': <String>[],
      'account_scope': 'all',
      'selected_accounts': <String>[],
      'selected_town_halls': <int>[],
      'selected_clan_tags': <String>[],
      ...preferences,
    };
    try {
      final url = _pushApiV2BaseOverride.isEmpty
          ? null
          : '$_pushApiV2BaseOverride$_preferencesEndpoint';
      final response = await ApiService().putResponse(
        _preferencesEndpoint,
        body: payload,
        requiresAuth: true,
        url: url,
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (error, stackTrace) {
      await Sentry.captureException(error, stackTrace: stackTrace);
      DebugUtils.debugWarning('Push preferences sync failed: $error');
      return false;
    }
  }

  Future<bool> unregisterCurrentDeviceToken() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return false;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenPrefsKey);
    final payload = <String, dynamic>{
      'device_id': await TokenService().getDeviceId(),
      'provider': 'fcm',
      'platform': Platform.operatingSystem,
      'environment': _pushEnvironment,
      if (token != null && token.isNotEmpty) 'token': token,
    };

    try {
      final url = _pushApiV2BaseOverride.isEmpty
          ? null
          : '$_pushApiV2BaseOverride$_deviceEndpoint';
      final response = await ApiService().deleteResponse(
        _deviceEndpoint,
        body: payload,
        requiresAuth: true,
        url: url,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await Future.wait([
          prefs.remove(_tokenPrefsKey),
          prefs.remove(_lastRegistrationPrefsKey),
        ]);
        await FirebaseMessaging.instance.deleteToken();
        return true;
      }
    } catch (error, stackTrace) {
      await Sentry.captureException(error, stackTrace: stackTrace);
      DebugUtils.debugWarning('Push device unregister skipped: $error');
    }
    return false;
  }

  Future<String?> cachedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenPrefsKey);
  }

  Future<String?> tokenPreview() async {
    final token = await cachedToken();
    if (token == null || token.length <= 16) return token;
    return '${token.substring(0, 8)}…${token.substring(token.length - 8)}';
  }

  Future<void> showForegroundMessage(RemoteMessage message) async {
    if (!_localNotificationsReady) return;

    final notification = message.notification;
    final title =
        notification?.title ?? message.data['title']?.toString() ?? 'ClashKing';
    final body =
        notification?.body ??
        message.data['body']?.toString() ??
        'New ClashKing alert';
    final payload = message.data.isEmpty ? null : jsonEncode(message.data);

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_stat_clashking',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  Future<void> _ensureFirebaseInitialized() async {
    if (Firebase.apps.isNotEmpty) return;
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  Future<void> _initializeLocalNotifications() async {
    if (_localNotificationsReady) return;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_stat_clashking'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        _handlePayload(response.payload);
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.high,
          ),
        );

    _localNotificationsReady = true;
  }

  void _bindMessageStreams() {
    _foregroundSub ??= FirebaseMessaging.onMessage.listen((message) {
      DebugUtils.debugInfo('Push foreground message: ${message.messageId}');
      unawaited(showForegroundMessage(message));
    });

    _openedSub ??= FirebaseMessaging.onMessageOpenedApp.listen((message) {
      DebugUtils.debugInfo('Push opened message: ${message.messageId}');
      _handleMessageNavigation(message);
    });

    _tokenRefreshSub ??= FirebaseMessaging.instance.onTokenRefresh.listen((
      token,
    ) {
      DebugUtils.debugInfo('Push token refreshed.');
      unawaited(_cacheToken(token));
      unawaited(registerCurrentDeviceToken(token: token));
    });

    unawaited(
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) {
          _handleMessageNavigation(message);
        }
      }),
    );
  }

  Future<void> _cacheToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenPrefsKey, token);
  }

  void _handlePayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        _handleDataNavigation(decoded);
      }
    } catch (error, stackTrace) {
      Sentry.captureException(error, stackTrace: stackTrace);
      DebugUtils.debugWarning('Invalid notification payload: $error');
    }
  }

  void _handleMessageNavigation(RemoteMessage message) {
    _handleDataNavigation(message.data);
  }

  void _handleDataNavigation(Map<String, dynamic> data) {
    if (data['type']?.toString() == 'admin_post') {
      if (!_canOpenFeatureRoute('admin_post', AppFeatureFlags.posts)) return;
      final postID = data['post_id']?.toString();
      if (postID != null && postID.isNotEmpty) {
        unawaited(_openAdminPost(postID));
        return;
      }
    }
    final route = data['route']?.toString();
    if (route == null || route.isEmpty) return;
    unawaited(_openRoute(route));
  }

  Future<void> _openRoute(String route) async {
    var navigator = globalNavigatorKey.currentState;
    for (var attempt = 0; navigator == null && attempt < 20; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      navigator = globalNavigatorKey.currentState;
    }
    if (navigator == null) return;

    switch (route) {
      case '/support-creator':
      case '/settings/support':
        final context = globalNavigatorKey.currentContext;
        if (context == null || !context.mounted) return;
        final languageCode = Localizations.localeOf(
          context,
        ).languageCode.toLowerCase();
        final url = Uri.https('link.clashofclans.com', '/$languageCode', {
          'action': 'SupportCreator',
          'id': 'Clashking',
        });
        await showDialog<void>(
          context: context,
          builder: (_) => OpenClashDialog(url: url),
        );
        return;
      case '/posts':
        if (!_canOpenFeatureRoute(route, AppFeatureFlags.posts)) return;
        await navigator.push(
          MaterialPageRoute<void>(builder: (_) => const PostsPage()),
        );
        return;
      case '/search':
        await navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => const SearchPage(overlay: true, autofocus: true),
          ),
        );
        return;
      case '/upgrade-tracker':
        if (!_canOpenFeatureRoute(route, AppFeatureFlags.upgradeTracker)) {
          return;
        }
        await navigator.push(
          MaterialPageRoute<void>(builder: (_) => const UpgradeTrackerPage()),
        );
        return;
      default:
        DebugUtils.debugWarning('Unsupported push route: $route');
    }
  }

  bool _canOpenFeatureRoute(String route, String featureFlag) {
    if (_isFeatureEnabled(featureFlag)) return true;
    DebugUtils.debugWarning(
      'Push route blocked by feature flag: $route ($featureFlag)',
    );
    return false;
  }

  bool _isFeatureEnabled(String key) {
    final context = globalNavigatorKey.currentContext;
    if (context == null || !context.mounted) {
      return AppFeatureFlags.defaultValue(key);
    }
    try {
      return context.read<MyAppState>().isFeatureEnabled(key);
    } on ProviderNotFoundException {
      return AppFeatureFlags.defaultValue(key);
    }
  }

  Future<void> _openAdminPost(String postID) async {
    final announcement = await AnnouncementService().getAnnouncement(postID);
    if (announcement == null) {
      DebugUtils.debugWarning('Push post could not be loaded: $postID');
      return;
    }
    var navigator = globalNavigatorKey.currentState;
    for (var attempt = 0; navigator == null && attempt < 20; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      navigator = globalNavigatorKey.currentState;
    }
    if (navigator == null) return;
    if (announcement.storyUrl?.isNotEmpty == true) {
      final preparedFilePath = await AnnouncementStoryCacheService().prepare(
        announcement,
      );
      if (preparedFilePath == null) {
        DebugUtils.debugWarning('Push story could not be prepared: $postID');
        return;
      }
      final storyContext = globalNavigatorKey.currentContext;
      if (storyContext == null || !storyContext.mounted) return;
      await showAnnouncementStoryDialog(
        storyContext,
        announcement: announcement,
        preparedFilePath: preparedFilePath,
      );
      return;
    }
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => AnnouncementWebViewPage(
          title: announcement.title,
          html: announcement.body,
          url: announcement.htmlUrl,
        ),
      ),
    );
  }

  PushNotificationSetupResult _setResult(PushNotificationSetupResult result) {
    _lastResult = result;
    return result;
  }

  bool _hasDisplayPermission(AuthorizationStatus status) {
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  PushNotificationSetupState _permissionStateFor(AuthorizationStatus status) {
    return status == AuthorizationStatus.denied
        ? PushNotificationSetupState.permissionDenied
        : PushNotificationSetupState.permissionRequired;
  }
}
