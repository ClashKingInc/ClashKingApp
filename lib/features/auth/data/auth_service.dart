import 'package:clashkingapp/core/models/user.dart';
import 'package:clashkingapp/core/utils/discord_auth_helper.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/core/services/token_service.dart';
import 'package:clashkingapp/core/constants/global_keys.dart';
import 'package:clashkingapp/features/auth/presentation/login_page.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
      print("🔄 Starting Discord login process...");
      final result = await DiscordAuthHelper.getDiscordAuthCode();
      print("🔄 Discord auth result: $result");
      if (result == null) throw Exception("User cancelled Discord login.");

      final deviceId = await _tokenService.getDeviceId();
      print("🔄 Device ID: $deviceId");
      final deviceName = await _tokenService.getDeviceName();
      print("🔄 Device Name: $deviceName");
      final response = await _apiService.post('/auth/discord', {
        'code': result['code']!,
        'redirect_uri': DiscordAuthHelper.getRedirectUri(),
        'code_verifier': result['code_verifier']!,
        'device_id': deviceId,
        'device_name': deviceName,
      });
      print("🔄 Discord login response: $response");

      await _tokenService.saveTokens(
          response['access_token'], response['refresh_token']);
      print("🔄 Tokens saved successfully.");
      notifyListeners();
    } catch (e) {
      print("❌ Discord login error: $e");
      throw Exception("Discord login failed. Please try again.");
    }
  }

  Future<void> signInWithClashKing(String email, String password) async {
    final response = await _apiService.post('/auth/clashking', {
      'email': email,
      'password': password,
    });
    await _tokenService.saveTokens(
        response['access_token'], response['refresh_token']);
    notifyListeners();
  }

  Future<void> logout() async {
    await _tokenService.clearTokens();
    _isAuthenticated = false;
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
      Uri.parse('${ApiService.apiUrl}$endpoint'),
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
      Uri.parse('${ApiService.apiUrl}$endpoint'),
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
}
