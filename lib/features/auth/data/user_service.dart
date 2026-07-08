import 'package:clashkingapp/core/services/api_service.dart';

class UserService {
  UserService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<Map<String, dynamic>> getClashKingUser() async {
    return await _apiService.get('/auth/me');
  }

  Future<List<String>> getClashAccounts(String userId) async {
    final response = await _apiService.get(
      '/links/${Uri.encodeComponent(userId)}',
    );

    if (response['items'] is List) {
      return (response['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map((account) => account['player_tag']?.toString())
          .whereType<String>()
          .toList();
    }

    return [];
  }
}
