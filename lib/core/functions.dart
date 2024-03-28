
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> isTokenValid() async {
  final prefs = await SharedPreferences.getInstance();
  String? expirationDateString = prefs.getString('expiration_date');

  if (expirationDateString != null) {
    DateTime expirationDate = DateTime.parse(expirationDateString);
    return DateTime.now().isBefore(expirationDate);
  }

  return false;
}

Future<String?> getAccessToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('access_token');
}