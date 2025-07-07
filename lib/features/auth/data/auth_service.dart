import 'package:clashkingapp/core/functions/functions.dart';
import 'package:clashkingapp/core/models/user.dart';
import 'package:clashkingapp/core/utils/discord_auth_helper.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/core/services/token_service.dart';
import 'package:clashkingapp/core/constants/global_keys.dart';
import 'package:clashkingapp/features/auth/presentation/login_page.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
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

  Future<void> initializeAuth() async {
    _accessToken = await _tokenService.getAccessToken();
    if (_accessToken != null) {
      try {
        final response = await _apiService.get('/auth/me');
        _currentUser = User.fromJson(response);
        _isAuthenticated = true;
      } catch (e) {
        _isAuthenticated = false;
        _accessToken = null;
        await _tokenService.clearTokens();
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
      DebugUtils.debugError("❌ Discord login error: $e");
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
      DebugUtils.debugError("❌ Email login error: $e");
      throw Exception("Email login failed. Please check your credentials.");
    }
  }

  Future<void> registerWithEmail(String email, String password, String username) async {
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
      
      await _tokenService.saveTokens(
          response['access_token'], response['refresh_token']);
      _currentUser = User.fromJson(response['user']);
      _isAuthenticated = true;
      _accessToken = response['access_token'];
      
      DebugUtils.debugSuccess("🔄 Email registration completed successfully");
      notifyListeners();
    } catch (e) {
      DebugUtils.debugError("❌ Email registration error: $e");
      throw Exception("Registration failed. Email may already be in use.");
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
      DebugUtils.debugError("❌ Discord linking error: $e");
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
      DebugUtils.debugError("❌ Email linking error: $e");
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
