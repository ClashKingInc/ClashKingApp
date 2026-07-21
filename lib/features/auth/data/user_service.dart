import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/coc_accounts/models/coc_account_link.dart';

class UserService {
  UserService({ApiService? apiService})
    : _apiService = apiService ?? ApiService.shared;

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
          .map(CocAccountLink.fromJson)
          .map((account) => account.playerTag)
          .toList();
    }

    return [];
  }
}
