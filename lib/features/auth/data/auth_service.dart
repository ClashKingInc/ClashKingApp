import 'package:clashkingapp/core/functions/functions.dart';
import 'package:clashkingapp/core/models/user.dart';
import 'package:clashkingapp/core/utils/discord_auth_helper.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/core/services/token_service.dart';
import 'package:clashkingapp/core/constants/global_keys.dart';
import 'package:clashkingapp/features/auth/presentation/login_page.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:clashkingapp/core/utils/debug_utils.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

class AuthService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final TokenService _tokenService = TokenService();
  String? _accessToken;
  bool _isAuthenticated = false;
  User? _currentUser;
  List<dynamic>? _cocAccounts;

  String? get accessToken => _accessToken;
  bool get isAuthenticated => _isAuthenticated;
  User? get currentUser => _currentUser;
  List<dynamic>? get cocAccounts => _cocAccounts;

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

  String _localized(
    String fallback,
    String Function(AppLocalizations l10n) builder,
  ) {
    final context = globalNavigatorKey.currentContext;
    if (context == null) {
      return fallback;
    }

    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return fallback;
    }

    return builder(l10n);
  }

  Future<void> initializeAuth() async {
    _accessToken = await _tokenService.getAccessToken();
    if (_accessToken != null) {
      try {
        final response = await _apiService.get('/auth/me');
        _currentUser = User.fromJson(response);
        _isAuthenticated = true;
      } catch (e) {
        if (_isNetworkError(e)) {
          // For network errors, keep the authentication state
          // We'll assume the user is still authenticated but can't connect
          _isAuthenticated = true;
          DebugUtils.debugWarning("⚠️ Network error during auth check: $e");
        } else {
          // For authentication errors (401, 403, etc.), log out the user
          _isAuthenticated = false;
          _accessToken = null;
          await _tokenService.clearTokens();
          DebugUtils.debugWarning("⚠️ Authentication error: $e");
        }
        // Rethrow the error so startup can handle it appropriately
        rethrow;
      }
    }
    notifyListeners();
  }

  Future<void> signInWithDiscord() async {
    try {
      DebugUtils.debugInfo("🔄 Starting Discord login process...");
      final result = await DiscordAuthHelper.getDiscordAuthCode();
      if (result == null) {
        throw Exception(
          _localized(
            'Discord login was cancelled.',
            (l10n) => l10n.authErrorUserCancelledDiscordLogin,
          ),
        );
      }

      final deviceId = await _tokenService.getDeviceId();
      final deviceName = await _tokenService.getDeviceName();
      final response = await _apiService.post('/auth/discord', {
        'code': result['code']!,
        'redirect_uri': DiscordAuthHelper.getRedirectUri(),
        'code_verifier': result['code_verifier']!,
        'device_id': deviceId,
        'device_name': deviceName,
      });

      await _tokenService.saveTokens(
          response['access_token'], response['refresh_token']);
      _currentUser = User.fromJson(response['user']);
      _isAuthenticated = true;
      _accessToken = response['access_token'];
      DebugUtils.debugSuccess("🔄 Tokens saved successfully.");
      notifyListeners();
    } catch (e) {
      DebugUtils.debugError(" Discord login error: $e");
      throw Exception(
        _localized(
          'Discord login failed.',
          (l10n) => l10n.authErrorDiscordLoginFailed,
        ),
      );
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      DebugUtils.debugInfo("🔄 Starting email login process...");
      final deviceId = await _tokenService.getDeviceId();
      final deviceName = await _tokenService.getDeviceName();

      final response = await _apiService.post('/auth/email', {
        'email': email,
        'password': password,
        'device_id': deviceId,
        'device_name': deviceName,
      });

      await _tokenService.saveTokens(
          response['access_token'], response['refresh_token']);
      _currentUser = User.fromJson(response['user']);
      _isAuthenticated = true;
      _accessToken = response['access_token'];

      DebugUtils.debugSuccess("🔄 Email login completed successfully");
      notifyListeners();
    } catch (e) {
      DebugUtils.debugError(" Email login error: $e");
      if (e is EmailVerificationRequiredException) {
        rethrow;
      }
      throw Exception(
        _localized(
          'Email login failed.',
          (l10n) => l10n.authErrorEmailLoginFailed,
        ),
      );
    }
  }

  Future<Map<String, dynamic>> registerWithEmail(
      String email, String password, String username) async {
    try {
      DebugUtils.debugInfo("🔄 Starting email registration process...");
      final deviceId = await _tokenService.getDeviceId();
      final deviceName = await _tokenService.getDeviceName();

      final response = await _apiService.post('/auth/register', {
        'email': email,
        'password': password,
        'username': username,
        'device_id': deviceId,
        'device_name': deviceName,
      });

      // Registration now sends verification email instead of creating account
      // No tokens returned yet - user needs to verify email first
      DebugUtils.debugSuccess(
          "🔄 Email registration verification sent successfully");

      // Don't set authentication state yet - wait for email verification
      notifyListeners();

      // Return response for UI to handle (includes verification_token in dev mode)
      return response;
    } catch (e) {
      DebugUtils.debugError(" Email registration error: $e");
      rethrow; // Let the UI handle error parsing and localization
    }
  }

  Future<void> verifyEmail(String verificationToken) async {
    try {
      DebugUtils.debugInfo("🔄 Starting email verification process...");

      final response = await _apiService.post('/auth/verify-email', {
        'token': verificationToken,
      });

      await _tokenService.saveTokens(
          response['access_token'], response['refresh_token']);
      _currentUser = User.fromJson(response['user']);
      _isAuthenticated = true;
      _accessToken = response['access_token'];

      DebugUtils.debugSuccess("🔄 Email verification completed successfully");
      notifyListeners();
    } catch (e) {
      DebugUtils.debugError(" Email verification error: $e");
      throw Exception(
        _localized(
          'Email verification failed.',
          (l10n) => l10n.authErrorEmailVerificationFailed,
        ),
      );
    }
  }

  Future<void> verifyEmailWithCode(String email, String code) async {
    try {
      DebugUtils.debugInfo("🔄 Starting email verification with code...");

      final response = await _apiService.post('/auth/verify-email-code', {
        'email': email,
        'code': code,
      });

      await _tokenService.saveTokens(
          response['access_token'], response['refresh_token']);
      _currentUser = User.fromJson(response['user']);
      _isAuthenticated = true;
      _accessToken = response['access_token'];

      DebugUtils.debugSuccess(
          "🔄 Email verification with code completed successfully");
      notifyListeners();
    } catch (e) {
      DebugUtils.debugError(" Email verification with code error: $e");
      rethrow; // Let the UI handle error parsing and localization
    }
  }

  Future<Map<String, dynamic>> resendVerificationEmail(String email) async {
    try {
      DebugUtils.debugInfo("🔄 Resending verification email...");

      final response = await _apiService.post('/auth/resend-verification', {
        'email': email,
      });
      DebugUtils.debugSuccess("🔄 Verification email resent successfully");

      return response;
    } catch (e) {
      DebugUtils.debugError(" Resend verification error: $e");
      rethrow; // Let the UI handle error parsing and localization
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      DebugUtils.debugInfo("🔄 Requesting password reset...");

      final response = await _apiService.post('/auth/forgot-password', {
        'email': email,
      });
      DebugUtils.debugSuccess("🔄 Password reset requested successfully");

      return response;
    } catch (e) {
      DebugUtils.debugError(" Forgot password error: $e");
      rethrow; // Let the UI handle error parsing and localization
    }
  }

  Future<void> resetPassword(
      String email, String resetCode, String newPassword) async {
    try {
      DebugUtils.debugInfo("🔄 Resetting password...");
      final deviceId = await _tokenService.getDeviceId();
      final deviceName = await _tokenService.getDeviceName();

      final response = await _apiService.post('/auth/reset-password', {
        'email': email,
        'reset_code': resetCode,
        'new_password': newPassword,
        'device_id': deviceId,
        'device_name': deviceName,
      });

      await _tokenService.saveTokens(
          response['access_token'], response['refresh_token']);
      _currentUser = User.fromJson(response['user']);
      _isAuthenticated = true;
      _accessToken = response['access_token'];

      DebugUtils.debugSuccess("🔄 Password reset completed successfully");
      notifyListeners();
    } catch (e) {
      DebugUtils.debugError(" Password reset error: $e");
      rethrow; // Let the UI handle error parsing and localization
    }
  }

  Future<void> linkDiscordAccount(
      String discordAccessToken, String? refreshToken, int? expiresIn) async {
    try {
      DebugUtils.debugInfo("🔄 Linking Discord account...");
      final deviceId = await _tokenService.getDeviceId();
      final deviceName = await _tokenService.getDeviceName();

      await _apiService.post('/auth/link-discord', {
        'access_token': discordAccessToken,
        if (refreshToken != null) 'refresh_token': refreshToken,
        if (expiresIn != null) 'expires_in': expiresIn.toString(),
        'device_id': deviceId,
        'device_name': deviceName,
      });

      DebugUtils.debugSuccess("🔄 Discord linking completed");
      // Refresh user data to get updated auth methods
      await initializeAuth();
    } catch (e) {
      DebugUtils.debugError(" Discord linking error: $e");
      throw Exception(
        _localized(
          'Discord account linking failed.',
          (l10n) => l10n.authErrorDiscordLinkFailed,
        ),
      );
    }
  }

  Future<void> linkEmailAccount(
      String email, String password, String username) async {
    try {
      DebugUtils.debugInfo("🔄 Linking email account...");
      final deviceId = await _tokenService.getDeviceId();
      final deviceName = await _tokenService.getDeviceName();

      await _apiService.post('/auth/link-email', {
        'email': email,
        'password': password,
        'username': username,
        'device_id': deviceId,
        'device_name': deviceName,
      });

      DebugUtils.debugSuccess("🔄 Email linking completed");
      // Refresh user data to get updated auth methods
      await initializeAuth();
    } catch (e) {
      DebugUtils.debugError(" Email linking error: $e");
      throw Exception(
        _localized(
          'Email account linking failed.',
          (l10n) => l10n.authErrorEmailLinkFailed,
        ),
      );
    }
  }

  Future<void> logout() async {
    await _tokenService.clearTokens();
    clearPrefs();
    _isAuthenticated = false;
    _currentUser = null;
    _cocAccounts = null;
    _accessToken = null;
    notifyListeners();
    globalNavigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  Future<void> signOut() async {
    await _tokenService.clearTokens();
    clearPrefs();
    _isAuthenticated = false;
    _currentUser = null;
    _cocAccounts = null;
    _accessToken = null;
    notifyListeners();
  }

  /// Comprehensive logout that clears all service data
  /// Call this method and then separately call clearAccountData() on CocAccountService
  Future<void> logoutAndClearAllData() async {
    await _tokenService.clearTokens();
    clearPrefs();
    _isAuthenticated = false;
    _currentUser = null;
    _cocAccounts = null;
    _accessToken = null;
    notifyListeners();

    // Note: Also call CocAccountService.clearAccountData() after this
    DebugUtils.debugInfo(
        "🔄 AuthService data cleared. Make sure to also clear CocAccountService data.");
  }
}
