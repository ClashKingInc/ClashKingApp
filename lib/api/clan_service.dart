// clan_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'clan_info.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ClanService {

    Future<void> initEnv() async {
    await dotenv.load(fileName: ".env");
  }

  Future<ClanInfo> fetchClanInfo() async {
    final response = await http.get(
      Uri.parse('https://api.clashking.xyz/v1/clans/!VY2J0LL'),
    );

    print('Response status: ${response.statusCode}'); // Print response status
    print('Response body: ${response.body}'); // Print response body

    if (response.statusCode == 200) {
      return ClanInfo.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load clan stats');
    }
  }
}
