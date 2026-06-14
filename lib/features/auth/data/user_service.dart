import 'package:clashkingapp/core/services/api_service.dart';

class UserService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getClashKingUser() async {
    return await _apiService.get('/auth/me');
  }

  Future<List<String>> getClashAccounts() async {
    final response = await _apiService.get('/users/coc-accounts');

    if (response.containsKey('accounts') && response['accounts'] is List) {
      return List<String>.from(response['accounts']);
    }

    return [];
  }
}
