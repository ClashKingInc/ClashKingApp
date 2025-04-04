import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:clashkingapp/core/services/token_service.dart';

class ApiService {
  static const String apiUrl = "https://dev.api.clashk.ing/v2";
  static const String assetUrl = "https://assets.clashk.ing";
  static const String proxyUrl = "https://proxy.clashk.ing/v1";
  static const String cocAssetsUrl = "https://coc-assets.clashk.ing";
  static const String bunnyUrl = "https://cdn.clashk.ing";
  static const String discordUrl = "https://discord.gg/clashking";

  Future<Map<String, dynamic>> get(String endpoint) async {
    final token = await TokenService().getAccessToken();
    final response = await http.get(
      Uri.parse('$apiUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, String> body) async {
    final response = await http.post(
      Uri.parse('$apiUrl$endpoint'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
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

  static String cocAssetsProxyUrl(String url) {
    if (url.startsWith('https://api-assets.clashofclans.com')) {
      return url.replaceFirst(
        'https://api-assets.clashofclans.com',
        cocAssetsUrl,
      );
    }
    return url;
  }
}
