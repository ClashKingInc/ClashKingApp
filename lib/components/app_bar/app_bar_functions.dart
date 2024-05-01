import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';

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
    Function updateErrorMessage, BuildContext context) async {
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
    updateErrorMessage('');
    return true;
  } else if (response.statusCode == 400) {
    updateErrorMessage(AppLocalizations.of(context)!.playerTagNotExists);
  } else if (response.statusCode == 409) {
    updateErrorMessage(AppLocalizations.of(context)!.accountAlreadyLinked);
  } else {
    updateErrorMessage(AppLocalizations.of(context)!.failedToAddTryAgain);
  }
  return false;
}

Future<bool> deleteLink(String playerTag, String authToken, Function updateErrorMessage, BuildContext context) async {
  playerTag = playerTag.replaceAll('#', '');
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
    updateErrorMessage('');
    return true;
  }
  {
    updateErrorMessage(AppLocalizations.of(context)!.failedToDeleteTryAgain);
  }
  return false;
}
