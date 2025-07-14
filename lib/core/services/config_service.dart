import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:clashkingapp/core/utils/debug_utils.dart';  

class ConfigService {
  static const String _baseUrl = "https://dev.api.clashk.ing/v2/app";
  static String? _sentryDsn;
  
  static String? get sentryDsn => _sentryDsn;
  
  static Future<void> loadConfig() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/public-config'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final config = json.decode(response.body);
        _sentryDsn = config['sentry_dsn'];
      } else {
        DebugUtils.debugError(' Failed to load config: ${response.statusCode}');
      }
    } catch (e) {
      DebugUtils.debugError(' Error loading config: $e');
    }
  }
}