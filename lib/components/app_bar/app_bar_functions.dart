import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

Future<String> login() async {
  final url = Uri.parse('https://cocdiscord.link/login');
  final response = await http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: jsonEncode(<String, String>{
      'username': dotenv.env['DISCORDCOC_LOGIN']!,
      'password': dotenv.env['DISCORDCOC_PASSWORD']!,
    }),
  );

  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    return data['token'];
  } else {
    throw Exception('Failed to login with status code: ${response.statusCode}');
  }
}

Future<bool> addLink(String playerTag, String discordId, String authToken,
    Function updateErrorMessage) async {
  final url = Uri.parse('https://cocdiscord.link/links');
  final response = await http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application',
      'Authorization': 'Bearer $authToken',
    },
    body: jsonEncode(<String, dynamic>{
      'playerTag': playerTag,
      'discordId': discordId,
    }),
  );

  if (response.statusCode == 200) {
    print("Link added successfully.");
    return true;
  } else if (response.statusCode == 400) {
    updateErrorMessage('The player tag entered does not exist.');
  } else if (response.statusCode == 409) {
    updateErrorMessage('The player tag is already linked to someone.');
  } else {
    updateErrorMessage('Failed to add link. Please try again later.');
  }
  return false;
}

Future<void> deleteLink(String playerTag, String authToken) async {
  final url = Uri.parse('https://cocdiscord.link/links/$playerTag');
  final response = await http.delete(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $authToken',
    },
  );

  if (response.statusCode == 200) {
    print("Link deleted successfully.");
  } else {
    throw Exception(
        'Failed to delete link with status code: ${response.statusCode}');
  }
}
