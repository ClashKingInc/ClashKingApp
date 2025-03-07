import 'package:clashkingapp/services/api_service.dart';

class UserService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getClashKingUser() async {
    return await _apiService.get('/auth/me');
  }

  Future<Map<String, dynamic>> getDiscordProfile() async {
    return await _apiService.get('/discord/me');
  }

  Future<List<String>> getClashAccounts() async {
    final response = await _apiService.get('/user/clash-accounts');

    if (response.containsKey('accounts') && response['accounts'] is List) {
      return List<String>.from(response['accounts']);
    }

    return [];
  }
}
