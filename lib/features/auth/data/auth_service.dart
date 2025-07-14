import 'package:clashkingapp/core/functions/functions.dart';
import 'package:clashkingapp/core/models/user.dart';
import 'package:clashkingapp/core/utils/discord_auth_helper.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/core/services/token_service.dart';
import 'package:clashkingapp/core/constants/global_keys.dart';
import 'package:clashkingapp/features/auth/presentation/login_page.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:clashkingapp/core/utils/debug_utils.dart';

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
      DebugUtils.debugInfo("🔄 Discord auth result: $result");
      if (result == null) throw Exception("User cancelled Discord login.");

      final deviceId = await _tokenService.getDeviceId();
      DebugUtils.debugInfo("🔄 Device ID: $deviceId");
      final deviceName = await _tokenService.getDeviceName();
      DebugUtils.debugInfo("🔄 Device Name: $deviceName");
      DebugUtils.debugInfo("🔄 Discord code_verifier : ${result['code_verifier']}");
      DebugUtils.debugInfo("🔄 Discord code: ${result['code']}");
      final response = await _apiService.post('/auth/discord', {
        'code': result['code']!,
        'redirect_uri': DiscordAuthHelper.getRedirectUri(),
        'code_verifier': result['code_verifier']!,
        'device_id': deviceId,
        'device_name': deviceName,
      });
      
      DebugUtils.debugInfo("🔄 Discord login response: $response");

      await _tokenService.saveTokens(
          response['access_token'], response['refresh_token']);
      _currentUser = User.fromJson(response['user']);
      DebugUtils.debugSuccess("🔄 Tokens saved successfully.");
      notifyListeners();
    } catch (e) {
      DebugUtils.debugError(" Discord login error: $e");
      throw Exception("Discord login failed. Please try again.");
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
      
      DebugUtils.debugInfo("🔄 Email login response: $response");
      
      await _tokenService.saveTokens(
          response['access_token'], response['refresh_token']);
      _currentUser = User.fromJson(response['user']);
      _isAuthenticated = true;
      _accessToken = response['access_token'];
      
      DebugUtils.debugSuccess("🔄 Email login completed successfully");
      notifyListeners();
    } catch (e) {
      DebugUtils.debugError(" Email login error: $e");
      throw Exception("Email login failed. Please check your credentials.");
    }
  }

  Future<Map<String, dynamic>> registerWithEmail(String email, String password, String username) async {
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
      
      DebugUtils.debugInfo("🔄 Email registration response: $response");
      
      // Registration now sends verification email instead of creating account
      // No tokens returned yet - user needs to verify email first
      DebugUtils.debugSuccess("🔄 Email registration verification sent successfully");
      
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
      
      DebugUtils.debugInfo("🔄 Email verification response: $response");
      
      await _tokenService.saveTokens(
          response['access_token'], response['refresh_token']);
      _currentUser = User.fromJson(response['user']);
      _isAuthenticated = true;
      _accessToken = response['access_token'];
      
      DebugUtils.debugSuccess("🔄 Email verification completed successfully");
      notifyListeners();
    } catch (e) {
      DebugUtils.debugError(" Email verification error: $e");
      throw Exception("Email verification failed. The token may be invalid or expired.");
    }
  }

  Future<void> verifyEmailWithCode(String email, String code) async {
    try {
      DebugUtils.debugInfo("🔄 Starting email verification with code...");
      
      final response = await _apiService.post('/auth/verify-email-code', {
        'email': email,
        'code': code,
      });
      
      DebugUtils.debugInfo("🔄 Email verification response: $response");
      
      await _tokenService.saveTokens(
          response['access_token'], response['refresh_token']);
      _currentUser = User.fromJson(response['user']);
      _isAuthenticated = true;
      _accessToken = response['access_token'];
      
      DebugUtils.debugSuccess("🔄 Email verification with code completed successfully");
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
      
      DebugUtils.debugInfo("🔄 Resend verification response: $response");
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
      
      DebugUtils.debugInfo("🔄 Forgot password response: $response");
      DebugUtils.debugSuccess("🔄 Password reset requested successfully");
      
      return response;
    } catch (e) {
      DebugUtils.debugError(" Forgot password error: $e");
      rethrow; // Let the UI handle error parsing and localization
    }
  }

  Future<void> resetPassword(String email, String resetCode, String newPassword) async {
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
      
      DebugUtils.debugInfo("🔄 Password reset response: $response");
      
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

  Future<void> linkDiscordAccount(String discordAccessToken, String? refreshToken, int? expiresIn) async {
    try {
      DebugUtils.debugInfo("🔄 Linking Discord account...");
      final deviceId = await _tokenService.getDeviceId();
      final deviceName = await _tokenService.getDeviceName();
      
      final response = await _apiService.post('/auth/link-discord', {
        'access_token': discordAccessToken,
        if (refreshToken != null) 'refresh_token': refreshToken,
        if (expiresIn != null) 'expires_in': expiresIn.toString(),
        'device_id': deviceId,
        'device_name': deviceName,
      });
      
      DebugUtils.debugSuccess("🔄 Discord linking completed: $response");
      // Refresh user data to get updated auth methods
      await initializeAuth();
    } catch (e) {
      DebugUtils.debugError(" Discord linking error: $e");
      throw Exception("Failed to link Discord account. It may already be linked to another account.");
    }
  }

  Future<void> linkEmailAccount(String email, String password, String username) async {
    try {
      DebugUtils.debugInfo("🔄 Linking email account...");
      final deviceId = await _tokenService.getDeviceId();
      final deviceName = await _tokenService.getDeviceName();
      
      final response = await _apiService.post('/auth/link-email', {
        'email': email,
        'password': password,
        'username': username,
        'device_id': deviceId,
        'device_name': deviceName,
      });
      
      DebugUtils.debugSuccess("🔄 Email linking completed: $response");
      // Refresh user data to get updated auth methods
      await initializeAuth();
    } catch (e) {
      DebugUtils.debugError(" Email linking error: $e");
      throw Exception("Failed to link email account. Email may already be in use.");
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

  Future<Map<String, dynamic>> get(String endpoint) async {
    final token = await _tokenService.getAccessToken();

    if (token == null) {
      throw Exception(
          "Utilisateur non authentifié. Veuillez vous reconnecter.");
    }

    final response = await http.get(
      Uri.parse('${ApiService.apiUrlV2}$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, String> body) async {
    final token = await _tokenService.getAccessToken();

    if (token == null) {
      throw Exception(
          "Utilisateur non authentifié. Veuillez vous reconnecter.");
    }

    final response = await http.post(
      Uri.parse('${ApiService.apiUrlV2}$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body,
    );

    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode} ${response.body}');
    }
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
    DebugUtils.debugInfo("🔄 AuthService data cleared. Make sure to also clear CocAccountService data.");
  }

}
