import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clashkingapp/core/constants/global_keys.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';
import 'package:clashkingapp/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
  static void registerBackgroundHandler() {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }
  }

  static const _deviceEndpoint = '/notifications/devices';
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
      final settings = await FirebaseMessaging.instance.requestPermission(
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

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return _setResult(
          PushNotificationSetupResult(
            state: PushNotificationSetupState.permissionDenied,
            authorizationStatus: settings.authorizationStatus,
            message: null,
          ),
        );
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        return _setResult(
          PushNotificationSetupResult(
            state: PushNotificationSetupState.tokenUnavailable,
            authorizationStatus: settings.authorizationStatus,
            message: null,
          ),
        );
      }

      await _cacheToken(token);
      await registerCurrentDeviceToken(token: token);

      return _setResult(
        PushNotificationSetupResult(
          state: PushNotificationSetupState.ready,
          authorizationStatus: settings.authorizationStatus,
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
    final payload = <String, dynamic>{
      'token': resolvedToken,
      'provider': 'fcm',
      'platform': Platform.operatingSystem,
      'app_version': packageInfo.version,
      'build_number': packageInfo.buildNumber,
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
          icon: '@mipmap/launcher_icon',
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
      android: AndroidInitializationSettings('@mipmap/launcher_icon'),
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
    final route = data['route']?.toString();
    if (route == null || route.isEmpty) return;

    // Route handling will be expanded when backend payload contracts are final.
    final context = globalNavigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text('Notification opened: $route')));
  }

  PushNotificationSetupResult _setResult(PushNotificationSetupResult result) {
    _lastResult = result;
    return result;
  }
}
