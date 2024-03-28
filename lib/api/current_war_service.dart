// current_war_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'current_war_info.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CurrentWarService {

    Future<void> initEnv() async {
    await dotenv.load(fileName: ".env");
  }

  Future<CurrentWarInfo> fetchCurrentWarInfo() async {
    final response = await http.get(
      Uri.parse('https://api.clashking.xyz/v1/clans/!2QPCJQQ2U/currentwar'),
    );

    print('Response status: ${response.statusCode}'); // Print response status
    print('Response body: ${response.body}'); // Print response body

    if (response.statusCode == 200) {
      String responseBody = utf8.decode(response.bodyBytes);
      return CurrentWarInfo.fromJson(jsonDecode(responseBody));
    } else {
      throw Exception('Failed to load current war info');
    }
  }
}
/*
Gros chêne : VY2J0LL
Le petit chêne : 2QPCJQQ2U
Gland Esport : 2GRCROPUG 
*/